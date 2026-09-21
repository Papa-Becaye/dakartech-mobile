/// États de la session utilisateur.
enum AuthStatus {
  /// Non initialisé (premier rendu du splash).
  unknown,

  /// Vérification de la session (lecture token + appel profile).
  checking,

  /// Session valide, utilisateur connecté.
  authenticated,

  /// Aucune session valide (non connecté).
  unauthenticated,
}
