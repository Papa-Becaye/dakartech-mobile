import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// En-tête de l'onglet « Notes », dans le corps de l'écran (l'AppBar
/// affiche déjà « Notes » via le [StudentShell]).
///
/// Titre « Notes & évaluations » + sous-titre « Votre progression
/// académique », conformément au design de l'étape 8.
class GradesHeader extends StatelessWidget {
  const GradesHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Notes & évaluations',
                style: AppTextStyles.title.copyWith(
                  color: AppColors.dark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                'Votre progression académique',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grayLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
