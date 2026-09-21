/// Chemins des endpoints d'authentification centralisés.
///
/// Le backend NestJS n'utilise pas de préfixe global (`/api/v1`),
/// les routes sont directement au niveau racine du contrôleur.
abstract final class AuthEndpoints {
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String profile = '/auth/profile';
  static const String forgotPassword = '/auth/forgot-password';
}
