/// Chemins des endpoints « Notes & évaluations » centralisés.
///
/// Le backend NestJS n'utilise pas de préfixe global (`/api/v1`), les
/// routes sont directement au niveau racine du contrôleur `notes`.
abstract final class GradesEndpoints {
  /// Relevé de notes de l'étudiant connecté (JWT + rôle étudiant) :
  /// identité, classe, année académique, moyenne générale pondérée,
  /// mention et notes par matière.
  ///
  /// L'utilisateur est identifié par le JWT : aucun paramètre étudiant
  /// n'est envoyé, il est donc impossible de consulter un autre relevé.
  static const String mesNotes = '/notes/mes-notes';
}
