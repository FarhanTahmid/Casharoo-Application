import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/entitlements/entitlements.dart';
import '../../core/entitlements/entitlements_controller.dart';
import '../../core/providers.dart';
import '../../core/ui.dart';
import 'plan_text.dart';
import 'upgrade_sheet.dart';

/// Offers the user closed on the home screen. They stay on the Plan screen.
class DismissedOffers extends Notifier<Set<String>> {
  static const _key = offersDismissedSettingKey;

  @override
  Set<String> build() {
    ref.read(databaseProvider).getSetting(_key).then((value) {
      if (value != null && value.isNotEmpty) state = {...state, ...value.split(',')};
    });
    return const {};
  }

  Future<void> dismiss(String slug) async {
    state = {...state, slug};
    await ref.read(databaseProvider).setSetting(_key, state.join(','));
  }
}

final dismissedOffersProvider = NotifierProvider<DismissedOffers, Set<String>>(DismissedOffers.new);

/// Takes what an offer gives, or shows the plans when there is nothing to take.
Future<void> _act(BuildContext context, WidgetRef ref, Offer offer, {bool canOpenPlans = true}) async {
  if (!offer.claimable) {
    if (canOpenPlans) await showUpgradeSheet(context);
    return;
  }
  final l10n = context.l10n;
  final error = await ref.read(entitlementsProvider.notifier).claim(offer.slug);
  if (!context.mounted) return;
  if (error == null) showEventBurst(context, AppEvent.saved);
  context.showMessage(error == null ? l10n.offerClaimed : planErrorText(l10n, error));
}

String _action(BuildContext context, Offer offer) {
  final cta = offer.ctaIn(context.languageCode);
  if (cta.isNotEmpty) return cta;
  return offer.claimable ? context.l10n.offerClaim : context.l10n.planSeePlans;
}

/// An offer in full, for the Plan screen and the upgrade sheet.
class OfferCard extends ConsumerWidget {
  const OfferCard({super.key, required this.offer, this.opensPlans = false});

  final Offer offer;

  /// Whether an offer with nothing to claim gets a button that shows the plans.
  /// False where the plans are already on screen.
  final bool opensPlans;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final language = context.languageCode;
    final body = offer.bodyIn(language);
    final has = offer.applied || offer.claimed;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpace.md),
      color: colors.gold.withValues(alpha: 0.14),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_offer_outlined, size: 20, color: colors.gold),
                const SizedBox(width: 8),
                Expanded(child: Text(offer.titleIn(language), style: text.titleMedium)),
              ],
            ),
            if (body.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(body, style: text.bodyMedium)),
            const SizedBox(height: AppSpace.sm),
            Row(
              children: [
                Expanded(
                  child: Text(
                    [
                      if (has) l10n.offerActive,
                      if (offer.endsAt != null) l10n.offerEnds(planDate(context, offer.endsAt!)),
                    ].join(' · '),
                    style: text.bodySmall,
                  ),
                ),
                if (!has && (offer.claimable || opensPlans))
                  FilledButton.tonal(
                    onPressed: () => _act(context, ref, offer, canOpenPlans: opensPlans),
                    child: Text(_action(context, offer)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The running offer, in one line on the navy field of the home screen. Gone
/// once the user has it, closes it, or it ends.
class OfferBanner extends ConsumerWidget {
  const OfferBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offers = ref.watch(entitlementsProvider).value?.offersFor(Offer.homeBanner) ?? const <Offer>[];
    final dismissed = ref.watch(dismissedOffersProvider);
    final offer = offers.where((o) => !o.applied && !o.claimed && !dismissed.contains(o.slug)).firstOrNull;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return AnimatedSize(
      duration: context.motion(AppMotion.emphasised),
      curve: AppMotion.ease,
      alignment: Alignment.topCenter,
      child: offer == null
          ? const SizedBox(width: double.infinity)
          : ColoredBox(
              color: colors.header,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.page, 0, AppSpace.page, AppSpace.sm),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.control),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _act(context, ref, offer),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 2, 6),
                      child: Row(
                        children: [
                          Icon(Icons.local_offer_rounded, size: 20, color: colors.gold),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer.titleIn(context.languageCode),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodyMedium?.copyWith(color: colors.onHeader, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  [
                                    _action(context, offer),
                                    if (offer.endsAt != null) context.l10n.offerEnds(planDate(context, offer.endsAt!)),
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: text.bodySmall?.copyWith(color: colors.onHeaderMuted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: context.l10n.dismiss,
                            visualDensity: VisualDensity.compact,
                            icon: Icon(Icons.close_rounded, size: 18, color: colors.onHeaderMuted),
                            onPressed: () => ref.read(dismissedOffersProvider.notifier).dismiss(offer.slug),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
