/// Exception applicative de base.
///
/// Point d'entrée unique pour les erreurs métier / techniques de
/// l'application. Les features pourront la spécialiser au besoin.
class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause});

  /// Message lisible par l'utilisateur final.
  final String message;

  /// Code technique optionnel (ex. code HTTP, clé de validation).
  final String? code;

  /// Erreur d'origine (pour le débogage).
  final Object? cause;

  @override
  String toString() => message;
}
