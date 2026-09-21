/// Rôles utilisateur conformes au backend NestJS.
///
/// Les valeurs utilisent la casse exacte renvoyée par l'API
/// (`ADMIN`, `ENSEIGNANT`, `ETUDIANT`).
enum UserRole {
  admin('ADMIN'),
  enseignant('ENSEIGNANT'),
  etudiant('ETUDIANT');

  const UserRole(this.apiValue);

  /// Valeur telle qu'elle apparaît dans la réponse JSON du backend.
  final String apiValue;

  /// Traduit la valeur API en enum.
  ///
  /// Lance une [FormatException] si la valeur est inconnue, afin de
  /// détecter immédiatement toute incohérence lors du développement.
  static UserRole fromApi(String value) {
    return values.firstWhere(
      (r) => r.apiValue == value,
      orElse: () => throw FormatException('Rôle inconnu : $value'),
    );
  }
}
