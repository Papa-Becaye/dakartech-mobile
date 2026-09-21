import 'package:flutter/material.dart';

import '../../../../core/icons/app_icon.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../data/models/course_model.dart';

/// Carte d'un cours de l'étudiant.
///
/// Affiche UNIQUEMENT les propriétés réellement fournies par le backend
/// (`titre`, code de la matière, enseignant, volume horaire). Aucune
/// donnée inventée (pas de progression, horaires ou notes fictifs).
///
/// Reçoit un objet [Course] prêt à afficher — jamais de données en dur.
class CourseCard extends StatelessWidget {
  const CourseCard({super.key, required this.course, this.onTap});

  final Course course;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String? code = course.matiere?.code;
    final CourseEnseignant? teacher = course.enseignant;
    final bool showTeacher = teacher != null;
    final bool showHours = course.volumeHoraire > 0;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const AppIcon(
              AppIcons.courses,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        course.titre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.label.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    if (code != null && code.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _CodeBadge(code: code),
                    ],
                  ],
                ),
                if (showTeacher || showHours) ...[
                  const SizedBox(height: AppSpacing.xs + 2),
                  Row(
                    children: [
                      if (showTeacher) ...[
                        const AppIcon(
                          AppIcons.profile,
                          size: 16,
                          color: AppColors.grayLight,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Flexible(
                          child: Text(
                            teacher.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.gray,
                            ),
                          ),
                        ),
                      ],
                      if (showTeacher && showHours) ...[
                        const SizedBox(width: AppSpacing.sm),
                        const _MetaSeparator(),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      if (showHours) ...[
                        const AppIcon(
                          AppIcons.clock,
                          size: 16,
                          color: AppColors.grayLight,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '${course.volumeHoraire} h',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gray,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          const AppIcon(
            AppIcons.chevronRight,
            size: 24,
            color: AppColors.grayLight,
          ),
        ],
      ),
    );
  }
}

/// Pastille discrète affichant le code de la matière (ex. « BD301 »).
class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.graySoft,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        code,
        style: AppTextStyles.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }
}

/// Petit point séparateur entre les métadonnées.
class _MetaSeparator extends StatelessWidget {
  const _MetaSeparator();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: AppColors.borderLight,
        shape: BoxShape.circle,
      ),
    );
  }
}
