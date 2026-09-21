import 'package:flutter/material.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../data/models/course_detail.dart';

/// Teaser de la prochaine séance d'un cours (fournie par le détail) :
/// date en bloc, chapitre, horaire-durée et rappel (action confiée à
/// l'écran).
class CourseNextSessionCard extends StatelessWidget {
  const CourseNextSessionCard({
    super.key,
    required this.seance,
    this.onReminder,
  });

  final CourseSeance seance;
  final VoidCallback? onReminder;

  @override
  Widget build(BuildContext context) {
    final List<String> meta = <String>[
      formatFrenchDay(seance.date),
      if (seance.duree > 0) '${seance.duree} h',
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  '${seance.date.day}',
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  formatFrenchMonthShort(seance.date),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Prochaine séance',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.gray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  seance.chapitre.isNotEmpty
                      ? seance.chapitre
                      : 'Séance à venir',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${formatFrenchHour(seance.date)}'
                  '${meta.length > 1 ? ' • ${meta.last}' : ''}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.gray),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppIconButton(
            icon: AppIcons.bellRing,
            iconColor: AppColors.primary,
            backgroundColor: AppColors.primarySoft,
            onPressed: onReminder,
            tooltip: 'Recevoir un rappel',
          ),
        ],
      ),
    );
  }
}
