/// Chemins des endpoints « Cours » centralisés.
///
/// Le backend NestJS n'utilise pas de préfixe global (`/api/v1`),
/// les routes sont directement au niveau racine du contrôleur `cours`.
abstract final class CoursesEndpoints {
  /// Cours de l'étudiant connecté (JWT requis).
  ///
  /// Récupère les cours de la classe de l'étudiant, avec matière et
  /// enseignant embarqués.
  static const String myCourses = '/cours/mes-cours';

  /// Détail d'un cours (JWT requis), avec matière, enseignant, classe
  /// (filière + année) et prochaine séance.
  static String courseDetail(int id) => '/cours/$id';

  /// Séances d'un cours (JWT requis), avec la présence de l'étudiant.
  static String courseSeances(int id) => '/cours/$id/seances';

  /// Documents pédagogiques d'un cours (JWT requis).
  static String courseDocuments(int id) => '/cours/$id/documents';

  /// Évaluations d'un cours (JWT requis), avec la note de l'étudiant.
  static String courseEvaluations(int id) => '/cours/$id/evaluations';
}
