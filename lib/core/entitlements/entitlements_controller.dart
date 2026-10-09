import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../auth/auth_repository.dart';
import '../db/database.dart';
import '../providers.dart';
import 'entitlements.dart';
import 'plan_guard.dart';

/// The billing endpoints that answer with the user's entitlements.
class EntitlementsRepository {
  EntitlementsRepository(this._api);

  final ApiClient _api;
  static const _base = '/api/v1/billing';

  Future<Entitlements?> fetch() async => _read(await _api.get('$_base/entitlements/'));

  Future<(Entitlements?, String?)> redeem(String code) async =>
      _answer(await _api.post('$_base/promo/redeem/', {'code': code}));

  Future<(Entitlements?, String?)> claim(String slug) async => _answer(await _api.post('$_base/offers/$slug/claim/'));

  /// Which rows stay editable under a limit the user is over. [scope] is the
  /// workspace for a per-workspace limit.
  Future<(Entitlements?, String?)> keep(String feature, String scope, List<String> ids) async =>
      _answer(await _api.put('$_base/keep/$feature/', {'scope': scope, 'ids': ids}));

  /// Test servers only: act out a store purchase, renewal, expiry or refund.
  Future<(Entitlements?, String?)> simulate(String action, {String? plan, String period = 'monthly'}) async =>
      _answer(await _api.post('$_base/dev/simulate/', {'action': action, 'plan': ?plan, 'period': period}));

  Entitlements? _read(ApiResponse response) =>
      response.ok && response.body is Map ? Entitlements(response.json, fetchedAt: DateTime.now()) : null;

  (Entitlements?, String?) _answer(ApiResponse response) {
    final entitlements = _read(response);
    if (entitlements != null) return (entitlements, null);
    if (response.statusCode == 429) return (null, EntitlementsController.throttled);
    final body = response.body;
    if (body is Map && body.isNotEmpty) {
      return (null, body.values.map((value) => value is List ? value.join(' ') : '$value').join(' '));
    }
    return (null, 'Request failed (${response.statusCode}).');
  }
}

final entitlementsRepositoryProvider =
    Provider<EntitlementsRepository>((ref) => EntitlementsRepository(ref.watch(apiClientProvider)));

/// What the signed-in user's plan gives. The last answer shows straight away,
/// offline too, and is refreshed when the app opens, when a sync reports that
/// something changed, and after a code is redeemed.
class EntitlementsController extends AsyncNotifier<Entitlements?> {
  /// Markers the actions below return in place of a sentence from the server.
  static const offline = 'offline';
  static const throttled = 'throttled';

  EntitlementsRepository get _repo => ref.read(entitlementsRepositoryProvider);
  AppDatabase get _db => ref.read(databaseProvider);

  @override
  Future<Entitlements?> build() async {
    final step = ref.watch(authControllerProvider.select((auth) => auth.step));
    if (step != AuthStep.signedIn) return null;
    final stored = await _db.getSetting(entitlementsSettingKey);
    final cached = stored == null ? null : Entitlements.decode(stored);
    if (cached != null) {
      unawaited(refresh());
      return cached;
    }
    try {
      final fresh = await _repo.fetch();
      if (fresh != null) await _db.setSetting(entitlementsSettingKey, fresh.encode());
      return fresh;
    } on OfflineException {
      return null;
    }
  }

  Future<void> refresh() async {
    try {
      final fresh = await _repo.fetch();
      if (fresh != null) await _set(fresh);
    } on OfflineException {
      // The copy on the phone stays
    }
  }

  /// A sync brought the server's marker. When it moved, an admin changed a
  /// plan or this user's plan changed: ask what it gives now.
  Future<void> stampSeen(String stamp) async {
    if (await _db.getSetting(billingStampSettingKey) == stamp) return;
    await _db.setSetting(billingStampSettingKey, stamp);
    await refresh();
  }

  /// Each returns null when it worked, [offline], [throttled], or what the server said.
  Future<String?> redeem(String code) => _apply(() => _repo.redeem(code));

  Future<String?> claim(String slug) => _apply(() => _repo.claim(slug));

  Future<String?> keep(String feature, String scope, List<String> ids) => _apply(() => _repo.keep(feature, scope, ids));

  Future<String?> simulate(String action, {String? plan}) => _apply(() => _repo.simulate(action, plan: plan));

  Future<String?> _apply(Future<(Entitlements?, String?)> Function() call) async {
    try {
      final (entitlements, error) = await call();
      if (entitlements != null) await _set(entitlements);
      return error;
    } on OfflineException {
      return offline;
    }
  }

  Future<void> _set(Entitlements entitlements) async {
    // An answer that lands after logging out belongs to nobody
    if (ref.read(authControllerProvider).step != AuthStep.signedIn) return;
    await _db.setSetting(entitlementsSettingKey, entitlements.encode());
    state = AsyncData(entitlements);
  }
}

final entitlementsProvider =
    AsyncNotifierProvider<EntitlementsController, Entitlements?>(EntitlementsController.new);

/// For repositories: checks a change against the plan before it is queued.
final planGuardProvider = Provider<PlanGuard>(
  (ref) => PlanGuard(ref.watch(databaseProvider), () => ref.read(entitlementsProvider).value),
);

/// The server refused a synced change because of the plan. The change was
/// rolled back; this holds the refusal until a screen has told the user.
class PlanLimitNotice extends Notifier<PlanLimitException?> {
  @override
  PlanLimitException? build() => null;

  /// A sync can refuse several changes for one reason: one notice is enough.
  void raise(PlanLimitException refusal) => state ??= refusal;

  void clear() => state = null;
}

final planLimitNoticeProvider = NotifierProvider<PlanLimitNotice, PlanLimitException?>(PlanLimitNotice.new);
