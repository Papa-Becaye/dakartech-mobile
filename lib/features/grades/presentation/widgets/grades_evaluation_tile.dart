import 'package:flutter/material.dart';

import '../../../../core/icons/app_icon.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_format.dart';
import '../../../courses/data/models/course_detail.dart';
import '../../models/grades_releve.dart';

/// Tuile d'une évaluation de la fiche matière : type, titre, cours
/// d'origine, date réelle et indicateur réel — note corrigée, échéance à
/// venir ou attente de correction.
class GradesEvaluationTile extends StatelessWidget {
  const GradesEvaluationTile({super.key, required this.evaluation});

  final GradesEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A151C27),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _tintFor(evaluation.type),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: AppIcon(
                  _iconFor(evaluation.type),
                  color: _colorFor(evaluation.type),
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      evaluation.titre.isEmpty
                          ? evaluation.type.label
                          : evaluation.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      '${evaluation.type.label} · ${formatFrenchShortDate(evaluation.date)}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grayLight,
                      ),
                    ),
                    if (evaluation.cours.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        evaluation.cours,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _Footer(evaluation: evaluation),
        ],
      ),
    );
  }
}

/// Indicateur réel (note / échéance / attente) en pied de tuile.
class _Footer extends StatelessWidget {
  const _Footer({required this.evaluation});

  final GradesEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final double? note = evaluation.note;

    if (note != null) {
      final String mention = _mentionFor(note);
      final Color color = note >= 10 ? AppColors.success : AppColors.warning;

      return Row(
        children: [
          const Text('Note', style: AppTextStyles.caption),
          const Spacer(),
          Text(
            formatNotePour20(note),
            style: AppTextStyles.title.copyWith(
              fontSize: 18,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.xxs,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              mention,
              style: AppTextStyles.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );
    }

    if (!evaluation.estPassee) {
      return Row(
        children: [
          const AppIcon(AppIcons.calendar, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.xxs),
          Expanded(
            child: Text(
              'Prévu le ${formatFrenchShortDate(evaluation.date)}',
              style: AppTextStyles.caption.copyWith(color: AppColors.gray),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const AppIcon(AppIcons.hourglass, size: 16, color: AppColors.warning),
        const SizedBox(width: AppSpacing.xxs),
        Expanded(
          child: Text(
            'En attente de correction',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

IconData _iconFor(CourseEvaluationType type) {
  return switch (type) {
    CourseEvaluationType.devoir => AppIcons.evaluation,
    CourseEvaluationType.examen => AppIcons.school,
    CourseEvaluationType.projet => AppIcons.rocket,
  };
}

Color _colorFor(CourseEvaluationType type) {
  return switch (type) {
    CourseEvaluationType.devoir => AppColors.primary,
    CourseEvaluationType.examen => AppColors.success,
    CourseEvaluationType.projet => AppColors.accent,
  };
}

Color _tintFor(CourseEvaluationType type) {
  return switch (type) {
    CourseEvaluationType.devoir => AppColors.primarySoft,
    CourseEvaluationType.examen => AppColors.successSoft,
    CourseEvaluationType.projet => AppColors.accentSoft,
  };
}

String _mentionFor(double note) {
  if (note >= 16) return 'Très bien';
  if (note >= 14) return 'Bien';
  if (note >= 12) return 'Assez bien';
  if (note >= 10) return 'Passable';
  return 'Insuffisant';
}
