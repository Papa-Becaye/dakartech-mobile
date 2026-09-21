import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Contenu temporaire d'une section de l'espace étudiant.
///
/// Variante « corps seul » (sans Scaffold ni AppBar) du placeholder
/// global, destinée à être affichée à l'intérieur du [StudentShell].
/// Chaque écran réel remplacera ce widget à la prochaine étape.
class StudentSectionPlaceholder extends StatelessWidget {
  const StudentSectionPlaceholder({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyLong,
            ),
          ],
        ),
      ),
    );
  }
}
