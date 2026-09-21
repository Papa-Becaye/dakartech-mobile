import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/controllers/auth_controller.dart';
import '../widgets/student_section_placeholder.dart';

/// Ecran provisoire « Mon profil ».
///
/// Point d'entrée de la déconnexion : le bouton appelle [AuthController.logout],
/// la redirection vers le login est pilotée par le routeur.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StudentSectionPlaceholder(
              icon: AppIcons.profile,
              title: 'Mon profil',
              description: 'Vos informations et préférences seront gérées ici.',
            ),
            const SizedBox(height: AppSpacing.xl),
            OutlinedButton.icon(
              onPressed: () => context.read<AuthController>().logout(),
              icon: const Icon(AppIcons.logout, size: 18),
              label: const Text('Se déconnecter'),
            ),
          ],
        ),
      ),
    );
  }
}
