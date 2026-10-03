import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'auth/auth_repository.dart';
import 'config.dart';
import 'db/database.dart';
import 'db/local_store.dart';
import 'sync/sync_engine.dart';

// ---------------------------------------------------------------- plumbing

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final tokenStoreProvider = Provider<TokenStore>((ref) => SecureTokenStore());

final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(baseUrl: AppConfig.apiUrl, tokenStore: ref.watch(tokenStoreProvider)),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiClientProvider)));

final localStoreProvider = Provider<LocalStore>(
  (ref) => LocalStore(
    ref.watch(databaseProvider),
    onChange: () => ref.read(syncControllerProvider.notifier).schedule(),
  ),
);

final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(ref.watch(databaseProvider), ref.watch(apiClientProvider), ref.watch(localStoreProvider)),
);

// -------------------------------------------------------------------- auth

class AuthState {
  const AuthState(this.step, {this.email, this.ready = true});

  final AuthStep step;

  /// Address the pending code was sent to, for display.
  final String? email;

  /// False until the stored session has been checked at launch.
  final bool ready;
}

class AuthController extends Notifier<AuthState> {
  static const _stepKey = 'auth_step';
  static const _emailKey = 'auth_email';

  @override
  AuthState build() {
    _restore();
    return const AuthState(AuthStep.signedOut, ready: false);
  }

  AuthRepository get _auth => ref.read(authRepositoryProvider);
  AppDatabase get _db => ref.read(databaseProvider);

  /// At launch: trust what was stored so the app opens offline, then confirm with the server.
  Future<void> _restore() async {
    final hasToken = await ref.read(tokenStoreProvider).read() != null;
    final stored = await _db.getSetting(_stepKey);
    final email = await _db.getSetting(_emailKey);
    final step = !hasToken
        ? AuthStep.signedOut
        : AuthStep.values.firstWhere((s) => s.name == stored, orElse: () => AuthStep.signedOut);
    state = AuthState(step, email: email);
    if (!hasToken) return;
    try {
      await _apply(await _auth.currentSession(), email: email);
    } on OfflineException {
      // Offline at launch: keep working with what is on the device
    }
  }

  Future<String?> signUp(String email, String password) =>
      _run(() => _auth.signUp(email, password), email: email);

  Future<String?> logIn(String email, String password) => _run(() => _auth.logIn(email, password), email: email);

  Future<String?> logInWithGoogle({required String idToken, required String clientId}) =>
      _run(() => _auth.logInWithGoogle(idToken: idToken, clientId: clientId));

  Future<String?> verifyEmail(String code) => _run(() => _auth.verifyEmail(code), email: state.email);

  Future<String?> resendEmailCode() => _run(() => _auth.resendEmailCode(), email: state.email);

  Future<String?> requestPasswordReset(String email) =>
      _run(() => _auth.requestPasswordReset(email), email: email);

  Future<String?> resetPassword(String code, String newPassword) =>
      _run(() => _auth.resetPassword(code, newPassword), email: state.email);

  Future<void> logOut() async {
    await _auth.logOut();
    await _signedOutCleanup();
    state = const AuthState(AuthStep.signedOut);
  }

  /// The server rejected the token while syncing.
  Future<void> sessionExpired() async {
    await ref.read(tokenStoreProvider).write(null);
    await _signedOutCleanup();
    state = const AuthState(AuthStep.signedOut);
  }

  /// Returns an error message to show, or null when the request went through.
  Future<String?> _run(Future<AuthResult> Function() action, {String? email}) async {
    try {
      final result = await action();
      await _apply(result, email: email);
      return result.error;
    } on OfflineException {
      return 'offline';
    }
  }

  Future<void> _apply(AuthResult result, {String? email}) async {
    // A failed attempt (wrong code, wrong password) leaves the current step as it is
    final step = result.step;
    if (step == null) return;
    if (step == AuthStep.signedOut && state.step == AuthStep.signedIn) await _signedOutCleanup();
    await _db.setSetting(_stepKey, step.name);
    await _db.setSetting(_emailKey, email);
    state = AuthState(step, email: email);
    if (step == AuthStep.signedIn) ref.read(syncControllerProvider.notifier).schedule(immediately: true);
  }

  Future<void> _signedOutCleanup() async {
    await _db.wipe();
    await _db.setSetting(_stepKey, null);
    await _db.setSetting(_emailKey, null);
    await _db.setSetting(CurrentWorkspaceController.settingKey, null);
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

// -------------------------------------------------------------------- sync

class SyncStatus {
  const SyncStatus({this.syncing = false, this.offline = false, this.error, this.lastSyncedAt});

  final bool syncing;
  final bool offline;
  final String? error;
  final DateTime? lastSyncedAt;

  SyncStatus copyWith({bool? syncing, bool? offline, String? error, DateTime? lastSyncedAt, bool clearError = false}) =>
      SyncStatus(
        syncing: syncing ?? this.syncing,
        offline: offline ?? this.offline,
        error: clearError ? null : (error ?? this.error),
        lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      );
}

class SyncController extends Notifier<SyncStatus> {
  Timer? _debounce;
  Timer? _periodic;
  bool _again = false;

  @override
  SyncStatus build() {
    // Other devices' changes arrive on this cadence while the app is open
    _periodic = Timer.periodic(const Duration(minutes: 1), (_) => syncNow());
    ref.onDispose(() {
      _debounce?.cancel();
      _periodic?.cancel();
    });
    return const SyncStatus();
  }

  /// After a local write: sync shortly, folding quick successive edits into one run.
  void schedule({bool immediately = false}) {
    _debounce?.cancel();
    _debounce = Timer(immediately ? Duration.zero : const Duration(seconds: 2), syncNow);
  }

  Future<void> syncNow() async {
    if (ref.read(authControllerProvider).step != AuthStep.signedIn) return;
    if (state.syncing) {
      _again = true; // a write landed mid-run: go round once more
      return;
    }
    state = state.copyWith(syncing: true);
    try {
      await ref.read(syncEngineProvider).sync();
      state = SyncStatus(lastSyncedAt: DateTime.now());
    } on OfflineException {
      state = state.copyWith(syncing: false, offline: true, clearError: true);
    } on SessionExpiredException {
      state = const SyncStatus();
      await ref.read(authControllerProvider.notifier).sessionExpired();
    } catch (error) {
      state = state.copyWith(syncing: false, offline: false, error: '$error');
    }
    if (_again) {
      _again = false;
      schedule(immediately: true);
    }
  }
}

final syncControllerProvider = NotifierProvider<SyncController, SyncStatus>(SyncController.new);

/// Number of local changes not yet on the server.
final pendingChangesProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  final count = db.outbox.seq.count();
  return (db.selectOnly(db.outbox)..addColumns([count])).map((row) => row.read(count) ?? 0).watchSingle();
});

final syncFailuresProvider = StreamProvider<List<SyncFailure>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.syncFailures)..orderBy([(f) => OrderingTerm.desc(f.id)])).watch();
});

// -------------------------------------------------------------- workspaces

final workspacesProvider = StreamProvider<List<Workspace>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.workspaces)..orderBy([(w) => OrderingTerm.asc(w.kind), (w) => OrderingTerm.asc(w.name)]))
      .watch();
});

/// Id of the workspace the user last chose.
class CurrentWorkspaceController extends Notifier<String?> {
  static const settingKey = 'workspace_id';

  @override
  String? build() {
    ref.read(databaseProvider).getSetting(settingKey).then((value) => state = value);
    return null;
  }

  Future<void> select(String? id) async {
    state = id;
    await ref.read(databaseProvider).setSetting(settingKey, id);
  }
}

final currentWorkspaceIdProvider = NotifierProvider<CurrentWorkspaceController, String?>(CurrentWorkspaceController.new);

/// The workspace on screen: the chosen one, else the personal one.
final currentWorkspaceProvider = Provider<Workspace?>((ref) {
  final workspaces = ref.watch(workspacesProvider).value ?? const [];
  if (workspaces.isEmpty) return null;
  final chosen = ref.watch(currentWorkspaceIdProvider);
  return workspaces.firstWhere(
    (w) => w.id == chosen,
    orElse: () => workspaces.firstWhere((w) => w.kind == 'personal', orElse: () => workspaces.first),
  );
});

// ----------------------------------------------------------- preferences

class LocaleController extends Notifier<Locale> {
  static const _key = 'locale';

  @override
  Locale build() {
    ref.read(databaseProvider).getSetting(_key).then((value) {
      if (value != null) state = Locale(value);
    });
    return const Locale('en');
  }

  Future<void> set(Locale locale) async {
    state = locale;
    await ref.read(databaseProvider).setSetting(_key, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);

class ThemeModeController extends Notifier<ThemeMode> {
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    ref.read(databaseProvider).getSetting(_key).then((value) {
      if (value != null) state = ThemeMode.values.firstWhere((m) => m.name == value, orElse: () => ThemeMode.system);
    });
    return ThemeMode.system;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref.read(databaseProvider).setSetting(_key, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
