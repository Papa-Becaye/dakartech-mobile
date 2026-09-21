/// Configuration réseau centralisée.
///
/// La base URL provient UNIQUEMENT de la configuration, jamais des
/// widgets. Elle peut être injectée au build avec :
///   flutter run --dart-define=API_BASE_URL=https://api.dakartech.com
///
/// La valeur par défaut (`localhost:9000`) fonctionne sur téléphone USB /
/// émulateur via un forwarding adb :
///   adb reverse tcp:9000 tcp:9000
/// Sur émulateur standard sans adb reverse, utiliser `10.0.2.2:9000`.
/// Le backend n'utilise pas de préfixe de version (`/api/v1` absent).
abstract final class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:9000',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
}
