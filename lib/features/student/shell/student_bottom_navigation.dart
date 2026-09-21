import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'student_destination.dart';

/// Barre de navigation inférieure de l'espace étudiant.
///
/// Widget purement déclaratif : il reçoit l'index actif et le callback de
/// sélection, sans aucune logique métier ni connaissance du routeur.
/// L'apparence (couleurs, indicateur, hauteur) vient du thème
/// (`AppTheme.navigationBarTheme`).
class StudentBottomNavigation extends StatelessWidget {
  const StudentBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.white),
      child: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: [
          for (final StudentDestinations d in StudentDestinations.values)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
