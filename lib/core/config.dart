/// Build-time configuration, passed with `--dart-define-from-file=config/<flavor>.json`.
class AppConfig {
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
  static const apiUrl = String.fromEnvironment('API_URL', defaultValue: 'http://10.0.2.2:8000');

  /// Web OAuth client ID the server verifies Google ID tokens against. Empty disables Google sign-in.
  static const googleServerClientId = String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// Where testers send feedback (an email address). Empty hides the Settings entry.
  static const feedbackEmail = String.fromEnvironment('FEEDBACK_EMAIL');

  static bool get isProd => flavor == 'prod';

  /// Test builds can be pointed at another server from Settings, e.g. a tunnel to a developer's machine.
  static bool get allowsServerOverride => !isProd;
}
