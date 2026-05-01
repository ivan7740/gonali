/// Compile-time configuration. Override per build with `--dart-define=...`.
///
/// On Android emulators the host loopback is `10.0.2.2`; iOS simulators
/// can use plain `localhost`. The default below targets Android because
/// it's the more common dev case for the team.
abstract class Env {
  Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
