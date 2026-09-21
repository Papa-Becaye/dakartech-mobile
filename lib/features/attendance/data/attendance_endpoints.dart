/// Chemins des endpoints « Présences » centralisés.
///
/// Le backend NestJS n'utilise pas de préfixe global (`/api/v1`), les
/// routes sont directement au niveau racine du contrôleur `presences`.
abstract final class AttendanceEndpoints {
  /// Bilan d'assiduité de l'étudiant connecté (JWT + rôle étudiant).
  static const String monAssiduite = '/presences/mon-assiduite';

  /// Émarge la présence à la séance [seanceId] (fenêtre ouverte requise).
  static String emarger(int seanceId) => '/presences/$seanceId/emarger';
}
