import 'package:flutter/material.dart';

import '../../../../core/icons/app_icon.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../models/grades_releve.dart';

/// Carte d'une matière du relevé : nom, code et
/// coefficient réels, moyenne réelle (ou « — ») et nombre d'évaluations.
///
/// Toute la carte est cliquable → fiche détaillée de la matière.
class GradesMatiereCard extends StatelessWidget {
  const GradesMatiereCard({super.key, required this.matiere, this.onTap});

  final GradesMatiere matiere;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String subtitle = (matiere.code == null || matiere.code!.isEmpty)
        ? 'Coefficient ${formatCoefficient(matiere.coefficient)}'
        : '${matiere.code} · Coefficient ${formatCoefficient(matiere.coefficient)}';

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  matiere.matiere,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grayLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${matiere.evaluations.length} évaluation(s)',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grayLight,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                matiere.estNotee ? formatNotePour20(matiere.moyenne!) : '—',
                style: TextStyle(
                  fontFamily: 'Geist',
                  fontSize: 16,
                  height: 1.3,
                  fontWeight: FontWeight.w700,
                  color: matiere.estNotee
                      ? (matiere.moyenne! < 10
                            ? AppColors.warning
                            : AppColors.success)
                      : AppColors.grayLight,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              const AppIcon(
                AppIcons.chevronRight,
                size: 20,
                color: AppColors.grayLight,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
