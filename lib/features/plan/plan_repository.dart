import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_client.dart';
import '../../core/entitlements/entitlements.dart';
import '../../core/entitlements/entitlements_controller.dart';
import '../../core/providers.dart';

/// One feature on the upgrade screen, as the server names it.
class CatalogFeature {
  const CatalogFeature({required this.key, required this.kind, required this.name});

  factory CatalogFeature.fromJson(Map<String, dynamic> json) => CatalogFeature(
        key: json['key'] as String? ?? '',
        kind: json['kind'] as String? ?? 'flag',
        name: json['name'] as String? ?? '',
      );

  final String key;
  final String kind;

  /// English, for a feature this version of the app has no words for.
  final String name;
}

class CatalogPlan {
  const CatalogPlan({required this.plan, required this.features});

  factory CatalogPlan.fromJson(Map<String, dynamic> json) => CatalogPlan(
        plan: PlanName.fromJson(json),
        features: {
          for (final MapEntry(:key, :value) in ((json['features'] as Map?) ?? const {}).entries)
            if (value is Map) '$key': FeatureValue.fromJson(value.cast<String, dynamic>()),
        },
      );

  final PlanName plan;
  final Map<String, FeatureValue> features;
}

/// Every plan a user can move to and what each gives. The upgrade screen is
/// drawn from this, so a plan changed in the admin shows without an app release.
class PlanCatalog {
  const PlanCatalog({required this.features, required this.plans});

  factory PlanCatalog.fromJson(Map<String, dynamic> json) => PlanCatalog(
        features: [
          for (final feature in (json['features'] as List?) ?? const [])
            if (feature is Map) CatalogFeature.fromJson(feature.cast<String, dynamic>()),
        ],
        plans: [
          for (final plan in (json['plans'] as List?) ?? const [])
            if (plan is Map) CatalogPlan.fromJson(plan.cast<String, dynamic>()),
        ],
      );

  final List<CatalogFeature> features;

  /// Lowest first.
  final List<CatalogPlan> plans;
}

class KeepItem {
  const KeepItem({required this.id, required this.label, required this.kept});

  final String id;
  final String label;
  final bool kept;
}

/// One limit the user is over, with the names of what they hold under it.
class KeepChoice {
  const KeepChoice({required this.lock, required this.workspaceName, required this.items});

  factory KeepChoice.fromJson(Map<String, dynamic> json) => KeepChoice(
        lock: KeepLock.fromJson(json),
        workspaceName: json['workspace_name'] as String? ?? '',
        items: [
          for (final item in (json['items'] as List?) ?? const [])
            if (item is Map)
              KeepItem(id: '${item['id']}', label: '${item['label'] ?? ''}', kept: item['kept'] as bool? ?? false),
        ],
      );

  final KeepLock lock;
  final String workspaceName;

  /// Oldest first.
  final List<KeepItem> items;
}

class PlanRepository {
  PlanRepository(this._api);

  final ApiClient _api;
  static const _base = '/api/v1/billing';

  Future<PlanCatalog?> plans() async {
    final response = await _api.get('$_base/plans/');
    return response.ok && response.body is Map ? PlanCatalog.fromJson(response.json) : null;
  }

  Future<List<KeepChoice>?> keepChoices() async {
    final response = await _api.get('$_base/keep/');
    if (!response.ok || response.body is! List) return null;
    return [
      for (final choice in response.body as List)
        if (choice is Map) KeepChoice.fromJson(choice.cast<String, dynamic>()),
    ];
  }

  /// Tells the server an upgrade screen was seen or tapped, for the admin's
  /// numbers. Nothing depends on it arriving.
  Future<void> report(String kind, {String? feature}) async {
    try {
      await _api.post('$_base/events/', {'kind': kind, 'feature': ?feature});
    } on OfflineException {
      // Not worth keeping for later
    }
  }
}

final planRepositoryProvider = Provider<PlanRepository>((ref) => PlanRepository(ref.watch(apiClientProvider)));

/// Null when the server could not be reached.
final planCatalogProvider = FutureProvider.autoDispose<PlanCatalog?>((ref) async {
  // A plan edited in the admin moves the entitlements; fetch the list again with them
  ref.watch(entitlementsProvider.select((value) => value.value?.version));
  try {
    return await ref.watch(planRepositoryProvider).plans();
  } on OfflineException {
    return null;
  }
});

/// Null when the server could not be reached.
final keepChoicesProvider = FutureProvider.autoDispose<List<KeepChoice>?>((ref) async {
  ref.watch(entitlementsProvider.select((value) => value.value?.version));
  try {
    return await ref.watch(planRepositoryProvider).keepChoices();
  } on OfflineException {
    return null;
  }
});

/// How much of a limit is in use, for a meter.
class LimitUse {
  const LimitUse(this.feature, this.count, this.limit);

  final String feature;
  final int count;

  /// Null: unlimited.
  final int? limit;

  bool get limited => limit != null;
  double get share => limit == null || limit == 0 ? (count > 0 ? 1.5 : 0) : count / limit!;
}

/// How many the signed-in user holds of what [feature] limits in a workspace,
/// against their plan. Recounted whenever those rows or the plan change.
final limitUseProvider = StreamProvider.autoDispose.family<LimitUse, (String, String)>((ref, key) {
  final (feature, workspaceId) = key;
  final db = ref.watch(databaseProvider);
  final guard = ref.watch(planGuardProvider);
  final limit = ref.watch(entitlementsProvider.select((value) => value.value?.limitOf(feature)));
  final table = db.tableByName(switch (feature) {
    F.personalAccounts => 'accounts',
    F.customCategories => 'categories',
    F.businessCashbooks => 'cashbooks',
    _ => 'workspaces',
  });
  return db
      .customSelect('SELECT 1', readsFrom: {table})
      .watch()
      .asyncMap((_) async => LimitUse(feature, await guard.count(feature, workspaceId), limit));
});
