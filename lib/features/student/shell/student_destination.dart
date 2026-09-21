import 'package:flutter/material.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/routes/app_routes.dart';

/// Les 5 onglets de l'espace étudiant.
///
/// Source unique des onglets : labels, icônes et routes sont regroupés
/// ici pour alimenter à la fois la bottom navigation, l'AppBar et le
/// routeur. Une seule couleur (le Primary du Design System) est utilisée
/// pour l'état actif.
enum StudentDestinations {
  dashboard(
    route: AppRoutes.dashboard,
    label: 'Accueil',
    icon: AppIcons.home,
    selectedIcon: AppIcons.homeFilled,
  ),
  courses(
    route: AppRoutes.courses,
    label: 'Cours',
    icon: AppIcons.courses,
    selectedIcon: AppIcons.coursesFilled,
  ),
  schedule(
    route: AppRoutes.schedule,
    label: 'Planning',
    icon: AppIcons.planning,
    selectedIcon: AppIcons.planningFilled,
  ),
  grades(
    route: AppRoutes.grades,
    label: 'Notes',
    icon: AppIcons.grades,
    selectedIcon: AppIcons.gradesFilled,
  ),
  profile(
    route: AppRoutes.profile,
    label: 'Profil',
    icon: AppIcons.profile,
    selectedIcon: AppIcons.profileFilled,
  );

  const StudentDestinations({
    required this.route,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String route;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  /// Vérifie si une localisation correspond à une branche de l'espace
  /// étudiant (utilisé par le contrôleur de rôles du routeur).
  static bool isStudentRoute(String location) {
    return values.any((StudentDestinations d) => d.route == location);
  }

  /// Retourne l'onglet correspondant à un index de branche.
  static StudentDestinations byIndex(int index) {
    assert(index >= 0 && index < values.length, 'Index de branche invalide');
    return values[index];
  }
}
