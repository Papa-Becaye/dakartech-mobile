import 'package:flutter/material.dart';

import '../../../../core/icons/app_icon.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_format.dart';

/// Résumé du jour sélectionné : libellé (« Aujourd'hui », « Lundi 19
/// septembre »), nombre de séances et plage horaire réelle de la journée.
class ScheduleDaySummary extends StatelessWidget {
  const ScheduleDaySummary({
    super.key,
    required this.dayLabel,
    required this.sessionsCount,
    required this.firstStart,
    required this.lastEnd,
  });

  /// Libellé du jour (« Aujourd'hui », « Lundi 19 septembre », …).
  final String dayLabel;
  final int sessionsCount;

  /// Première heure de début (null si aucune séance).
  final DateTime? firstStart;

  /// Dernière heure de fin (null si aucune séance).
  final DateTime? lastEnd;

  @override
  Widget build(BuildContext context) {
    final DateTime? start = firstStart;
    final DateTime? end = lastEnd;
    final String rangeLabel = (start != null && end != null)
        ? '${formatFrenchHour(start)} — ${formatFrenchHour(end)}'
        : 'Aucune séance programmée';

    final String countLabel = sessionsCount <= 1
        ? '$sessionsCount séance'
        : '$sessionsCount séances';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.primarySoft,
              shape: BoxShape.circle,
            ),
            child: const AppIcon(
              AppIcons.calendarCheck,
              color: AppColors.primary,
              size: AppIconSize.md,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dayLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.dark,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '$countLabel · $rangeLabel',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grayLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
