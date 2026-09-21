import 'package:flutter/material.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Navigation de semaine de l'emploi du temps.
///
/// Affiche le libellé de la semaine (« 19 — 25 septembre 2026 ») avec des
/// flèches précédent/suivant (décalage local — aucun rechargement). La
/// semaine en cours porte un badge « Cette semaine » ; hors semaine en
/// cours, un lien « Aujourd'hui » permet de revenir au jour réel.
class ScheduleWeekNavigator extends StatelessWidget {
  const ScheduleWeekNavigator({
    super.key,
    required this.weekRangeLabel,
    required this.isCurrentWeek,
    required this.onPreviousWeek,
    required this.onNextWeek,
    required this.onGoToday,
  });

  final String weekRangeLabel;
  final bool isCurrentWeek;
  final VoidCallback onPreviousWeek;
  final VoidCallback onNextWeek;
  final VoidCallback onGoToday;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A00395F),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _WeekArrow(
            icon: AppIcons.chevronLeft,
            onPressed: onPreviousWeek,
            tooltip: 'Semaine précédente',
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  weekRangeLabel,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                if (isCurrentWeek)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primarySoft,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      'Cette semaine',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  GestureDetector(
                    onTap: onGoToday,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xxs,
                      ),
                      child: Text(
                        'Aujourd\'hui',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          _WeekArrow(
            icon: AppIcons.chevronRight,
            onPressed: onNextWeek,
            tooltip: 'Semaine suivante',
          ),
        ],
      ),
    );
  }
}

class _WeekArrow extends StatelessWidget {
  const _WeekArrow({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon, color: AppColors.primary),
    );
  }
}
