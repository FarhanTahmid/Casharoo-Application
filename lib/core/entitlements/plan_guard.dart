import 'package:drift/drift.dart';

import '../db/database.dart';
import 'entitlements.dart';

/// Asks the plan before a change is queued, so the user hears "not on your
/// plan" at once instead of after a sync. The server asks again either way.
///
/// A workspace is judged on its owner's plan, and the phone only knows the
/// signed-in user's. In someone else's business nothing is checked here.
class PlanGuard {
  PlanGuard(this.db, this.read);

  final AppDatabase db;

  /// The latest answer from the server; null before the first one.
  final Entitlements? Function() read;

  /// The plan to hold the user to: none before the first answer, and none
  /// while the server itself refuses nothing.
  Entitlements? get _plan {
    final plan = read();
    return plan == null || !plan.enforced ? null : plan;
  }

  /// Throws when the workspace already holds as many as the plan allows.
  Future<void> roomFor(String feature, String workspaceId) async {
    final limit = _plan?.limitOf(feature);
    if (limit == null) return;
    // Businesses are counted across the account; everything else inside one workspace
    if (feature != F.businessWorkspaces && !await _mine(workspaceId)) return;
    final current = await count(feature, workspaceId);
    if (current >= limit) {
      throw PlanLimitException(feature, limit: limit, current: current);
    }
  }

  /// Throws when the plan does not include the feature.
  Future<void> require(String feature, String workspaceId) async {
    final plan = _plan;
    if (plan == null || plan.can(feature) || !await _mine(workspaceId)) return;
    throw PlanLimitException(feature, reason: PlanLimitException.reasonFeature);
  }

  /// Throws when a downgrade made the row read-only.
  void writable(String feature, String rowId) {
    final plan = _plan;
    if (plan == null || !plan.isLocked(rowId)) return;
    throw PlanLimitException(feature, reason: PlanLimitException.reasonLocked, limit: plan.limitOf(feature));
  }

  /// How many the user holds of what [feature] limits, counted the way the
  /// server counts (billing/rules.py): archived accounts and the categories an
  /// account starts with do not count, nor does the demo business.
  Future<int> count(String feature, String workspaceId) async {
    final (sql, scoped) = switch (feature) {
      F.personalAccounts => (
          'SELECT COUNT(*) AS n FROM accounts WHERE workspace_id = ? AND deleted_at IS NULL AND is_archived = 0',
          true,
        ),
      F.customCategories => (
          'SELECT COUNT(*) AS n FROM categories WHERE workspace_id = ? AND deleted_at IS NULL AND is_default = 0',
          true,
        ),
      F.businessCashbooks => ('SELECT COUNT(*) AS n FROM cashbooks WHERE workspace_id = ? AND deleted_at IS NULL', true),
      F.businessWorkspaces => (
          "SELECT COUNT(*) AS n FROM workspaces WHERE kind = 'business' AND role = 'owner' AND is_demo = 0",
          false,
        ),
      _ => (null, false),
    };
    if (sql == null) return 0;
    final row = await db.customSelect(sql, variables: [if (scoped) Variable<String>(workspaceId)]).getSingle();
    return row.read<int>('n');
  }

  Future<bool> _mine(String workspaceId) async {
    final workspace = await (db.select(db.workspaces)..where((w) => w.id.equals(workspaceId))).getSingleOrNull();
    return workspace?.role == 'owner';
  }
}
