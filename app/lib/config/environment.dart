/// Build-time settings, passed with `--dart-define-from-file=env/<name>.json`
/// (see env/example.json).
abstract final class Environment {
  /// Where the app looks up the Candle server address (GitHub Pages, docs/api.json).
  static const configUrl = String.fromEnvironment(
    'CANDLE_CONFIG_URL',
    defaultValue: 'https://freegroup.github.io/candle/api.json',
  );

  /// Skips the lookup and uses this server, e.g. a local one during development.
  static const apiUrlOverride = String.fromEnvironment('CANDLE_API_URL');

  /// Lets simulators/emulators register at a server that allows debug attestation.
  static const debugAttestationToken = String.fromEnvironment('DEBUG_ATTESTATION_TOKEN');

  /// Google Cloud project linked to the app in the Play Console (Play Integrity).
  static const playCloudProjectNumber = int.fromEnvironment('PLAY_CLOUD_PROJECT_NUMBER');
}
