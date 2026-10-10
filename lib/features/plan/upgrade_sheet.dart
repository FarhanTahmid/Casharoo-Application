import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/entitlements/entitlements.dart';
import '../../core/entitlements/entitlements_controller.dart';
import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';
import 'offer_banner.dart';
import 'plan_repository.dart';
import 'plan_text.dart';

/// Runs [action]; when the plan does not allow it, says so on the upgrade
/// sheet. True when the action went through.
Future<bool> guarded(BuildContext context, Future<void> Function() action) async {
  try {
    await action();
    return true;
  } on PlanLimitException catch (refusal) {
    if (context.mounted) await showUpgradeSheet(context, refusal: refusal);
    return false;
  }
}

/// What each plan gives, and the ways to move to one. With [refusal] it opens
/// by saying what the user's plan did not allow.
Future<void> showUpgradeSheet(BuildContext context, {PlanLimitException? refusal}) => showAppSheet<void>(
      context,
      title: context.l10n.planUpgradeTitle,
      builder: (_) => _UpgradeSheet(refusal: refusal),
    );

/// Asks for a promo code and redeems it. Says how it went; a caller on a sheet
/// takes the failure in [onError], because a snackbar would sit under the sheet.
Future<void> redeemCode(BuildContext context, WidgetRef ref, {void Function(String message)? onError}) async {
  final l10n = context.l10n;
  final code = await promptText(context, title: l10n.planRedeem, label: l10n.code);
  if (code == null || !context.mounted) return;
  final error = await ref.read(entitlementsProvider.notifier).redeem(code);
  if (!context.mounted) return;
  if (error == null) {
    final plan = ref.read(entitlementsProvider).value?.plan.nameIn(context.languageCode) ?? '';
    showEventBurst(context, AppEvent.saved);
    context.showMessage(l10n.planCodeApplied(plan));
  } else {
    final message = planErrorText(l10n, error);
    onError == null ? context.showMessage(message) : onError(message);
  }
}

/// Turns the markers from the entitlements controller into a sentence.
String planErrorText(AppLocalizations l10n, String error) => switch (error) {
      EntitlementsController.offline => l10n.offlineError,
      EntitlementsController.throttled => l10n.planThrottled,
      _ => error,
    };

/// Whether [next] gives more of [feature] than [now] does.
bool givesMore(String feature, FeatureValue? now, FeatureValue next) {
  // The one switch that is better off
  if (feature == F.ads) return (now?.enabled ?? true) && !next.enabled;
  if (next.isFlag) return next.enabled && !(now?.enabled ?? false);
  if (now?.unlimited ?? false) return false;
  return next.unlimited || (next.limit ?? 0) > (now?.limit ?? 0);
}

class _UpgradeSheet extends ConsumerStatefulWidget {
  const _UpgradeSheet({this.refusal});

  final PlanLimitException? refusal;

  @override
  ConsumerState<_UpgradeSheet> createState() => _UpgradeSheetState();
}

class _UpgradeSheetState extends ConsumerState<_UpgradeSheet> {
  String? _simulating;

  /// Why the last redeem or purchase failed, shown on the sheet itself.
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.read(planRepositoryProvider).report('paywall_view', feature: widget.refusal?.feature);
  }

  Future<void> _simulate(String plan) async {
    setState(() {
      _simulating = plan;
      _error = null;
    });
    ref.read(planRepositoryProvider).report('upgrade_tap', feature: widget.refusal?.feature);
    final error = await ref.read(entitlementsProvider.notifier).simulate('purchase', plan: plan);
    if (!mounted) return;
    setState(() {
      _simulating = null;
      _error = error == null ? null : planErrorText(context.l10n, error);
    });
    if (error != null) return;
    showEventBurst(context, AppEvent.saved);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final language = context.languageCode;
    final mine = ref.watch(entitlementsProvider).value;
    final catalog = ref.watch(planCatalogProvider);
    final refusal = widget.refusal;
    final planName = mine?.plan.nameIn(language) ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (refusal != null)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpace.lg),
            padding: const EdgeInsets.all(AppSpace.md),
            decoration: BoxDecoration(
              color: colors.gold.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(AppRadius.control),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  refusal.reason == PlanLimitException.reasonLocked ? Icons.lock_outline_rounded : Icons.info_outline_rounded,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(planLimitText(l10n, refusal, planName), style: text.bodyMedium)),
              ],
            ),
          ),
        if (refusal?.reason == PlanLimitException.reasonLocked) ...[
          OutlinedButton.icon(
            icon: const Icon(Icons.checklist_rounded),
            label: Text(l10n.keepTitle),
            onPressed: () {
              final router = GoRouter.of(context);
              Navigator.pop(context);
              router.push('/plan/keep');
            },
          ),
          const SizedBox(height: AppSpace.lg),
        ],
        for (final offer in mine?.offersFor(Offer.upgradeSheet) ?? const <Offer>[]) OfferCard(offer: offer),
        ...switch (catalog) {
          AsyncData(value: final PlanCatalog found) => _plans(context, found, mine),
          AsyncData() || AsyncError() => [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
                child: Text(l10n.planLoadFailed, style: text.bodyMedium),
              ),
            ],
          _ => [const Padding(padding: EdgeInsets.all(AppSpace.xl), child: Center(child: AppLoader()))],
        },
        const SizedBox(height: AppSpace.sm),
        Text(l10n.planBuySoon, style: text.bodySmall),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.sm),
            child: Text(_error!, style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.error)),
          ),
        const SizedBox(height: AppSpace.md),
        FilledButton.icon(
          icon: const Icon(Icons.confirmation_number_outlined),
          label: Text(l10n.planRedeem),
          onPressed: () async {
            setState(() => _error = null);
            await redeemCode(context, ref, onError: (message) {
              if (mounted) setState(() => _error = message);
            });
            // On a better plan now: nothing left to offer here
            final now = ref.read(entitlementsProvider).value;
            if (context.mounted && now != null && now.version != mine?.version) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  List<Widget> _plans(BuildContext context, PlanCatalog catalog, Entitlements? mine) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final language = context.languageCode;
    final rank = mine?.plan.rank ?? 0;
    final names = {for (final feature in catalog.features) feature.key: feature.name};
    final cards = <Widget>[];
    // What the plan before gives, so each card lists only what it adds
    var below = mine?.features ?? const <String, FeatureValue>{};
    var belowName = mine?.plan.nameIn(language) ?? '';

    for (final offered in catalog.plans.where((p) => p.plan.rank > rank)) {
      final gains = [
        for (final feature in shownFeatures)
          if (offered.features[feature] case final value? when givesMore(feature, below[feature], value)) (feature, value),
      ];
      final code = offered.plan.code;
      cards.add(Card(
        margin: const EdgeInsets.only(bottom: AppSpace.md),
        color: code == widget.refusal?.upgradeTo ? scheme.primaryContainer.withValues(alpha: 0.45) : null,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(offered.plan.nameIn(language), style: text.titleLarge),
              if (offered.plan.taglineIn(language).isNotEmpty)
                Text(offered.plan.taglineIn(language), style: text.bodySmall),
              const SizedBox(height: AppSpace.md),
              if (belowName.isNotEmpty && gains.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpace.sm),
                  child: Text(l10n.planEverythingIn(belowName), style: text.bodySmall),
                ),
              for (final (feature, value) in gains)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 18, color: context.colors.moneyIn),
                      const SizedBox(width: 8),
                      Expanded(child: Text(featureLabel(l10n, feature, names[feature]), style: text.bodyMedium)),
                      if (!value.isFlag)
                        Text(
                          value.unlimited ? l10n.planUnlimited : '${value.limit ?? 0}',
                          style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontFeatures: tabularFigures),
                        ),
                    ],
                  ),
                ),
              // Stands in for the store until buying is built; never in a production build
              if (!AppConfig.isProd)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _simulating == null ? () => _simulate(code) : null,
                    child: Text(l10n.planSimulate),
                  ),
                ),
            ],
          ),
        ),
      ));
      below = offered.features;
      belowName = offered.plan.nameIn(language);
    }
    return cards;
  }
}
