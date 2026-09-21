import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/routes/app_routes.dart';
import '../../auth/controllers/auth_controller.dart';
import 'student_app_bar.dart';
import 'student_bottom_navigation.dart';
import 'student_destination.dart';

/// Coquille de l'espace étudiant.
///
/// Assemble l'AppBar, le corps (branche active) et la bottom navigation.
/// Contient uniquement de la navigation d'interface — aucune logique
/// métier, aucun appel réseau.
///
/// Comportement du bouton retour :
/// - depuis un autre onglet → retour à l'onglet Accueil ;
/// - depuis l'Accueil → double appui pour quitter (évite une fermeture
///   accidentelle) ;
/// - depuis un sous-écran poussé au-dessus du shell → retour au niveau
///   précédent (géré nativement par le routeur, sans pile inutile).
class StudentShell extends StatefulWidget {
  const StudentShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<StudentShell> createState() => _StudentShellState();
}

class _StudentShellState extends State<StudentShell> {
  static const Duration _exitWindow = Duration(seconds: 2);

  DateTime? _lastBackPress;

  StatefulNavigationShell get _navigationShell => widget.navigationShell;

  @override
  Widget build(BuildContext context) {
    final AuthController auth = context.watch<AuthController>();
    final StudentDestinations current = StudentDestinations.byIndex(
      _navigationShell.currentIndex,
    );

    // L'AppBar reste neutre (titre de l'onglet) : le message de
    // bienvenue personnalisé est affiché dans l'en-tête du dashboard.
    final String title = current.label;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        _handleSystemBack();
      },
      child: Scaffold(
        appBar: StudentAppBar(
          title: title,
          avatarInitials: auth.currentUser?.fullName,
          onNotificationsTap: () => context.push(AppRoutes.notifications),
          onAvatarTap: () => _navigationShell.goBranch(
            StudentDestinations.profile.index,
            initialLocation: true,
          ),
        ),
        body: _navigationShell,
        bottomNavigationBar: StudentBottomNavigation(
          currentIndex: _navigationShell.currentIndex,
          onDestinationSelected: (int index) => _navigationShell.goBranch(
            index,
            initialLocation: index == _navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }

  void _handleSystemBack() {
    // Depuis un autre onglet, le retour ramène à l'Accueil.
    if (_navigationShell.currentIndex != StudentDestinations.dashboard.index) {
      _navigationShell.goBranch(
        StudentDestinations.dashboard.index,
        initialLocation: true,
      );
      return;
    }

    // Sur l'Accueil : double appui pour quitter l'application.
    final DateTime now = DateTime.now();
    final bool canExit =
        _lastBackPress != null && now.difference(_lastBackPress!) < _exitWindow;

    if (canExit) {
      SystemNavigator.pop();
      return;
    }

    _lastBackPress = now;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Appuyer à nouveau pour quitter')),
      );
  }
}
