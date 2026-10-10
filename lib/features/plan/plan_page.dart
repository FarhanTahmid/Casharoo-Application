import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config.dart';
import '../../core/db/database.dart';
import '../../core/entitlements/entitlements.dart';
import '../../core/entitlements/entitlements_controller.dart';
import '../../core/providers.dart';
import '../../core/ui.dart';
import 'offer_banner.dart';
import 'plan_repository.dart';
import 'plan_text.dart';
import 'upgrade_sheet.dart';

/// The user's plan: what it is, how much of it is in use, and how to get more.
class PlanPage extends ConsumerWidget {
  const PlanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final language = context.languageCode;
    final plan = ref.watch(entitlementsProvider).value;
    final workspaces = ref.watch(workspacesProvider).value ?? const <Workspace>[];
    final personal = workspaces.where((w) => w.kind == 'personal').firstOrNull;
    final current = ref.watch(currentWorkspaceProvider);

    if (plan == null) {
      // Never reached the server since signing in
      return Scaffold(
        appBar: AppBar(title: Text(l10n.plan)),
        body: EmptyState(icon: Icons.workspace_premium_outlined, message: l10n.planLoadFailed),
      );
    }

    final locked = plan.locks.fold<int>(0, (sum, lock) => sum + lock.locked.length);
    final offers = plan.offersFor(Offer.planScreen);
    final expires = plan.expiresAt;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.plan)),
      body: RefreshIndicator(
        onRefresh: ref.read(entitlementsProvider.notifier).refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, AppSpace.sm, AppSpace.page, AppSpace.xl),
          children: [
            SectionCard(
              children: [
                Text(l10n.planYours, style: text.bodySmall),
                const SizedBox(height: 2),
                Text(plan.plan.nameIn(language), style: text.headlineSmall),
                if (plan.plan.taglineIn(language).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(plan.plan.taglineIn(language), style: text.bodyMedium),
                  ),
                if (expires != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.sm),
                    child: Text(l10n.planUntil(planDate(context, expires)), style: text.bodySmall),
                  ),
                if (plan.inGrace)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.sm),
                    child: Text(
                      l10n.planGraceNote,
                      style: text.bodySmall?.copyWith(color: Theme.of(context).colorScheme.error),
                    ),
                  ),
                const SizedBox(height: AppSpace.md),
                FilledButton.tonal(onPressed: () => showUpgradeSheet(context), child: Text(l10n.planSeePlans)),
              ],
            ),
            if (locked > 0)
              Card(
                margin: const EdgeInsets.only(bottom: AppSpace.md),
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: const Icon(Icons.lock_outline_rounded),
                  title: Text(l10n.keepTitle),
                  subtitle: Text(l10n.keepLockedCount(locked)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.push('/plan/keep'),
                ),
              ),
            for (final offer in offers) OfferCard(offer: offer, opensPlans: true),
            SectionCard(
              title: l10n.planUsage,
              children: [
                if (personal != null) ...[
                  _Meter(feature: F.personalAccounts, workspaceId: personal.id),
                  _Meter(feature: F.customCategories, workspaceId: personal.id),
                ],
                const _Meter(feature: F.businessWorkspaces, workspaceId: ''),
                // Cashbooks are counted per business, and only its owner's plan decides
                if (current != null && current.kind == 'business' && current.role == 'owner')
                  _Meter(feature: F.businessCashbooks, workspaceId: current.id, detail: current.name),
              ],
            ),
            Card(
              margin: const EdgeInsets.only(bottom: AppSpace.md),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.confirmation_number_outlined),
                    title: Text(l10n.planRedeem),
                    subtitle: Text(l10n.planRedeemHint),
                    onTap: () => redeemCode(context, ref),
                  ),
                  // Stands in for the store's own events; never in a production build.
                  // Only a simulated purchase can be ended this way, not a code or an offer.
                  if (!AppConfig.isProd && plan.source == 'store') ...[
                    const Divider(indent: 56),
                    ListTile(
                      leading: const Icon(Icons.science_outlined),
                      title: Text(l10n.planSimulateExpire),
                      onTap: () async {
                        final error = await ref.read(entitlementsProvider.notifier).simulate('expire');
                        if (context.mounted && error != null) context.showMessage(planErrorText(l10n, error));
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One limit: its name, "3 of 4", and a bar that turns gold near the limit.
class _Meter extends ConsumerWidget {
  const _Meter({required this.feature, required this.workspaceId, this.detail});

  final String feature;
  final String workspaceId;

  /// Which business, for a limit counted per business.
  final String? detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    // A feature the server does not send is not shown
    if (ref.watch(entitlementsProvider.select((value) => value.value?[feature])) == null) return const SizedBox.shrink();
    final use = ref.watch(limitUseProvider((feature, workspaceId))).value;
    if (use == null) return const SizedBox.shrink();
    final label = featureLabel(l10n, feature);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(detail == null ? label : '$label · $detail', style: text.bodyMedium, overflow: TextOverflow.ellipsis),
              ),
              Text(
                use.limited ? l10n.planCountOf(use.count, use.limit!) : '${use.count} · ${l10n.planUnlimited}',
                style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600, fontFeatures: tabularFigures),
              ),
            ],
          ),
          if (use.limited) ...[const SizedBox(height: 2), LimitBar(value: use.share, height: 8)],
        ],
      ),
    );
  }
}

/// "3 of 4" beside an Add button once the limit is close, so the wall is no
/// surprise. Nothing while there is plenty of room or no limit.
class LimitHint extends ConsumerWidget {
  const LimitHint({super.key, required this.feature, required this.workspace});

  final String feature;
  final Workspace workspace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Someone else's business runs on their plan, which this phone does not know
    if (workspace.role != 'owner') return const SizedBox.shrink();
    final use = ref.watch(limitUseProvider((feature, workspace.id))).value;
    final plan = ref.watch(entitlementsProvider).value;
    // No wall to warn about while the server refuses nothing
    if (plan == null || !plan.enforced) return const SizedBox.shrink();
    if (use == null || !use.limited || use.share * 100 < plan.warnAtPercent) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Text(
        '${featureLabel(context.l10n, feature)}: ${context.l10n.planCountOf(use.count, use.limit!)}',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: LimitBar.colorFor(context, use.share)),
      ),
    );
  }
}
