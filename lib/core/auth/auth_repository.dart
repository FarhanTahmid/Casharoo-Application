import '../api/api_client.dart';

enum AuthStep {
  /// Signed in and verified.
  signedIn,

  /// The account exists but the emailed code has not been entered yet.
  needsEmailCode,

  /// A password-reset code was emailed and is awaited.
  needsResetCode,

  signedOut,
}

class AuthResult {
  AuthResult(this.step, {this.error});

  /// Null when the request was refused and the user stays where they are.
  final AuthStep? step;

  /// Message from the server when the request was refused.
  final String? error;

  bool get failed => error != null;
}

/// Talks to django-allauth's headless API (app client). Every response that
/// carries a session token stores it; the token changes when a login completes.
class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;
  static const _base = '/_allauth/app/v1';

  Future<AuthResult> signUp(String email, String password) =>
      _flow(() => _api.post('$_base/auth/signup', {'email': email, 'password': password}));

  Future<AuthResult> logIn(String email, String password) =>
      _flow(() => _api.post('$_base/auth/login', {'email': email, 'password': password}));

  Future<AuthResult> verifyEmail(String code) =>
      _flow(() => _api.post('$_base/auth/email/verify', {'key': code.trim()}));

  Future<AuthResult> resendEmailCode() => _flow(() => _api.post('$_base/auth/email/verify/resend'));

  Future<AuthResult> requestPasswordReset(String email) =>
      _flow(() => _api.post('$_base/auth/password/request', {'email': email}));

  Future<AuthResult> resetPassword(String code, String newPassword) =>
      _flow(() => _api.post('$_base/auth/password/reset', {'key': code.trim(), 'password': newPassword}));

  Future<AuthResult> logInWithGoogle({required String idToken, required String clientId}) =>
      _flow(() => _api.post('$_base/auth/provider/token', {
            'provider': 'google',
            'process': 'login',
            'token': {'client_id': clientId, 'id_token': idToken},
          }));

  /// What the stored token is good for right now.
  Future<AuthResult> currentSession() async {
    if (await _api.tokenStore.read() == null) return AuthResult(AuthStep.signedOut);
    return _flow(() => _api.get('$_base/auth/session'));
  }

  Future<void> logOut() async {
    try {
      await _api.delete('$_base/auth/session');
    } on OfflineException {
      // The token is dropped locally either way
    }
    await _api.tokenStore.write(null);
  }

  Future<AuthResult> _flow(Future<ApiResponse> Function() request) async {
    final response = await request();
    final body = response.body is Map ? response.json : const <String, dynamic>{};
    final meta = (body['meta'] as Map?) ?? const {};
    final token = meta['session_token'] as String?;
    if (token != null) await _api.tokenStore.write(token);

    if (response.ok) {
      if (meta['is_authenticated'] == true) return AuthResult(AuthStep.signedIn);
      // A completed step that is not a login, such as "code resent": stay put
      // unless the server names a pending flow
      final hasFlows = (body['data'] as Map?)?['flows'] != null;
      return AuthResult(hasFlows ? _pendingStep(body) : null);
    }
    if (response.statusCode == 401) return AuthResult(_pendingStep(body));
    if (response.statusCode == 410) {
      // The session is gone for good
      await _api.tokenStore.write(null);
      return AuthResult(AuthStep.signedOut);
    }
    final errors = (body['errors'] as List?) ?? const [];
    final message = errors.map((e) => (e as Map)['message']).whereType<String>().join(' ');
    return AuthResult(null, error: message.isEmpty ? 'Request failed (${response.statusCode}).' : message);
  }

  AuthStep _pendingStep(Map<String, dynamic> body) {
    final flows = ((body['data'] as Map?)?['flows'] as List?) ?? const [];
    bool pending(String id) => flows.any((f) => (f as Map)['id'] == id && f['is_pending'] == true);
    if (pending('verify_email')) return AuthStep.needsEmailCode;
    if (pending('password_reset_by_code')) return AuthStep.needsResetCode;
    return AuthStep.signedOut;
  }
}
