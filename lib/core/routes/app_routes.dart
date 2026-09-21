/// Constantes des routes de l'application.
abstract final class AppRoutes {
  // Routes publiques (sans session).
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Espace étudiant (branches de la bottom navigation).
  static const String dashboard = '/dashboard';
  static const String courses = '/courses';
  static const String schedule = '/schedule';
  static const String grades = '/grades';
  static const String profile = '/profile';

  // Routes réservées pour les prochaines étapes.
  static const String attendance = '/attendance';
  static const String notifications = '/notifications';
  static const String courseDetail = '/course/:id';

  // Fiche détaillée d'une matière de l'onglet Notes (la matière est
  // passée via `extra`, aucune seconde requête réseau).
  static const String gradesMatiereDetail = '/notes/matiere/:id';

  /// Écran intermédiaire pour les rôles encore non développés
  /// (ADMIN, ENSEIGNANT). Sera remplacé par leurs propres dashboards.
  static const String rolePending = '/role-pending';
}
