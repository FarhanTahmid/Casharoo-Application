import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/entitlements/entitlements.dart';
import '../../core/ui.dart';
import '../../l10n/app_localizations.dart';

/// The features this version of the app has, in the order the upgrade screen
/// lists them. The server knows of more (see its catalog); one is added here
/// when the app gets it, so nobody is sold something they cannot use yet.
const shownFeatures = [
  F.personalAccounts,
  F.customCategories,
  F.budgetMonthOverride,
  F.businessWorkspaces,
  F.businessCashbooks,
];

/// A feature's name in the user's language. [fallback] is the server's English
/// name, for a key this version has no words for.
String featureLabel(AppLocalizations l10n, String feature, [String? fallback]) => switch (feature) {
      F.personalAccounts => l10n.featureAccounts,
      F.customCategories => l10n.featureCustomCategories,
      F.budgetMonthOverride => l10n.featureBudgetMonthOverride,
      F.insightsCustomRange => l10n.featureInsightsCustomRange,
      F.insightsYearReview => l10n.featureYearReview,
      F.insightsTrendMonths => l10n.featureTrendMonths,
      F.recurringTransactions => l10n.featureRecurring,
      F.savingsGoals => l10n.featureSavingsGoals,
      F.homeWidget => l10n.featureHomeWidget,
      F.businessWorkspaces => l10n.featureBusinesses,
      F.businessCashbooks => l10n.featureCashbooks,
      F.teamSeats => l10n.featureTeamSeats,
      F.reportRange => l10n.featureReportRange,
      F.reportExport => l10n.featureReportExport,
      F.auditTrail => l10n.featureAuditTrail,
      F.customFields => l10n.featureCustomFields,
      F.storageMb => l10n.featureStorage,
      F.aiCredits => l10n.featureAiCredits,
      F.pdfPages => l10n.featurePdfPages,
      F.devicesMax => l10n.featureDevices,
      F.ads => l10n.featureNoAds,
      _ => fallback ?? feature,
    };

/// One sentence saying what the plan did not allow.
String planLimitText(AppLocalizations l10n, PlanLimitException refusal, String plan) {
  final limit = refusal.limit;
  return switch (refusal.reason) {
    PlanLimitException.reasonLocked => l10n.limitLocked(plan),
    PlanLimitException.reasonFeature => l10n.limitFeature(featureLabel(l10n, refusal.feature), plan),
    PlanLimitException.reasonQuota => l10n.limitQuota(featureLabel(l10n, refusal.feature)),
    _ when limit == null => l10n.limitGeneric(plan),
    _ => switch (refusal.feature) {
        F.personalAccounts => l10n.limitAccounts(plan, limit),
        F.customCategories => l10n.limitCategories(plan, limit),
        F.businessCashbooks => l10n.limitCashbooks(plan, limit),
        F.businessWorkspaces => l10n.limitWorkspaces(plan, limit),
        _ => l10n.limitGeneric(plan),
      },
  };
}

/// "Oct 12, 2026" in the user's language, from a moment the server sent. With
/// the year, since a plan can run into the next one.
String planDate(BuildContext context, DateTime moment) =>
    DateFormat.yMMMd(context.languageCode).format(moment.toLocal());

/// A small padlock with "Locked", for a row a downgrade made read-only.
class LockedTag extends StatelessWidget {
  const LockedTag({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: context.l10n.lockedTag,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline_rounded, size: 14, color: colors.muted),
          const SizedBox(width: 3),
          ExcludeSemantics(
            child: Text(context.l10n.lockedTag, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colors.muted)),
          ),
        ],
      ),
    );
  }
}
