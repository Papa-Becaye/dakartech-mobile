import 'package:flutter/material.dart';

import '../../../../core/icons/app_icon.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_format.dart';
import '../../data/models/course_detail.dart';

/// Carte d'une évaluation : type, titre, date, statut dérivé (notée,
/// prévue, en attente), note réelle + mention ou échéance dérivée de la
/// date fournie.
class CourseEvaluationCard extends StatelessWidget {
  const CourseEvaluationCard({super.key, required this.evaluation});

  final CourseEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final double? note = evaluation.note;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _tintFor(evaluation.type),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: AppIcon(
                  _iconFor(evaluation.type),
                  color: _colorFor(evaluation.type),
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      evaluation.type.label.toUpperCase(),
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grayLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      evaluation.titre,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.dark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _StatusBadge(evaluation: evaluation),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (note != null)
            _NotationBlock(note: note)
          else if (!evaluation.estPassee)
            _DeadlineBlock(date: evaluation.date)
          else
            Row(
              children: <Widget>[
                const AppIcon(
                  AppIcons.hourglass,
                  size: 16,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.xxs),
                Text(
                  'En attente de correction',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Bloc « Note réelle + mention » (uniquement si corrigée).
class _NotationBlock extends StatelessWidget {
  const _NotationBlock({required this.note});

  final double note;

  @override
  Widget build(BuildContext context) {
    final String mention = _mentionFor(note);
    final Color color = note >= 10 ? AppColors.success : AppColors.warning;

    return Row(
      children: <Widget>[
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
}

/// Échéance dérivée de la date réelle de l'évaluation à venir.
class _DeadlineBlock extends StatelessWidget {
  const _DeadlineBlock({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final int jours = date.difference(DateTime.now()).inDays.clamp(0, 10000);

    return Row(
      children: <Widget>[
        const AppIcon(AppIcons.calendar, size: 16, color: AppColors.primary),
        const SizedBox(width: AppSpacing.xxs),
        Expanded(
          child: Text(
            'Échéance le ${formatFrenchShortDate(date)}',
            style: AppTextStyles.caption.copyWith(color: AppColors.gray),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Text(
            'Dans $jours j',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

/// Badge de statut (coloré par état, dérivé des données).
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.evaluation});

  final CourseEvaluation evaluation;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color, Color soft) = _statusOf(evaluation);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: soft,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

(String, Color, Color) _statusOf(CourseEvaluation evaluation) {
  final double? note = evaluation.note;
  if (note != null) {
    return ('Notée', AppColors.success, AppColors.successSoft);
  }
  if (!evaluation.estPassee) {
    return ('Prévu', AppColors.primary, AppColors.primarySoft);
  }
  return ('À corriger', AppColors.warning, AppColors.warningSoft);
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

/// Mention française standard dérivée de la note réelle (sur 20).
String _mentionFor(double note) {
  if (note >= 16) return 'Très bien';
  if (note >= 14) return 'Bien';
  if (note >= 12) return 'Assez bien';
  if (note >= 10) return 'Passable';
  return 'Insuffisant';
}
