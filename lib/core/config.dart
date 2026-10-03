/// Build-time configuration, passed with `--dart-define-from-file=config/<flavor>.json`.
class AppConfig {
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://localhost:8000');

  /// Web OAuth client ID the server verifies Google ID tokens against. Empty disables Google sign-in.
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  static bool get isProd => flavor == 'prod';
}
