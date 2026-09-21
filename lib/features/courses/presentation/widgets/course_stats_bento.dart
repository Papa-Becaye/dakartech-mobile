import 'package:flutter/material.dart';

import '../../../../core/icons/app_icon.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Données affichées par les stats, pré-calculées par le contrôleur à
/// partir de données réelles (aucune valeur en dur ici).
class CourseStatsData {
  const CourseStatsData({
    required this.seancesLabel,
    required this.seancesProgress,
    this.attendanceLabel,
    required this.attendanceProgress,
    required this.progressionLabel,
    required this.progressionProgress,
  });

  /// « 5/7 » (séances effectuées / total).
  final String seancesLabel;
  final double seancesProgress;

  /// « 86% » ou `null` quand aucune présence n'a été émargée.
  final String? attendanceLabel;
  final double attendanceProgress;

  /// « 71% » (séances effectuées / total, affichées en pourcentage).
  final String progressionLabel;
  final double progressionProgress;
}

/// Bandeau de statistiques du détail de cours.
///
/// Les trois métriques vivent dans un seul encart blanc et se partagent
/// la largeur : label discret au-dessus, valeur forte en dessous,
/// séparées par de fins filets verticaux — lecture « tableau de bord »
/// sans cartes répétées ni barres de progression génériques.
class CourseStatsBento extends StatelessWidget {
  const CourseStatsBento({super.key, required this.data});

  final CourseStatsData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.card,
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Expanded(
                child: _StatMetric(
                  icon: AppIcons.repeat,
                  color: AppColors.primary,
                  label: 'Séances',
                  value: data.seancesLabel,
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _StatMetric(
                  icon: AppIcons.checkCircle,
                  color: AppColors.success,
                  label: 'Présence',
                  value: data.attendanceLabel ?? '—',
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _StatMetric(
                  icon: AppIcons.trendingUp,
                  color: AppColors.accent,
                  label: 'Progression',
                  value: data.progressionLabel,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filet vertical fin entre deux métriques (étiré à la hauteur du
/// bandeau via [IntrinsicHeight]).
class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Container(width: 1, color: AppColors.border),
    );
  }
}

/// Une métrique du bandeau : icône + label discrets, valeur en exergue.
class _StatMetric extends StatelessWidget {
  const _StatMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AppIcon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.gray,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTextStyles.title.copyWith(
            fontSize: 22,
            color: AppColors.dark,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ],
    );
  }
}
