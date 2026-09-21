import 'package:flutter/material.dart';

import '../../../../core/icons/app_icon.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/course_colors.dart';
import '../../../../core/utils/date_format.dart';
import '../../models/schedule_session.dart';

/// Bandeau « Prochain cours » du jour sélectionné.
///
/// Affiché uniquement aujourd'hui : la première séance à venir du jour,
/// son horaire et un compte à rebours réel (« Dans X min », calculé à la
/// construction — aucune simulation, aucune donnée inventée).
class ScheduleNextSessionBanner extends StatelessWidget {
  const ScheduleNextSessionBanner({super.key, required this.session});

  final ScheduleSession session;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String rangeLabel = session.timeRangeLabel;
    final CourseTone tone = CourseTones.toneFor(
      matiereId: session.course.matiere?.id,
      name: session.course.titre,
    );

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
            decoration: BoxDecoration(color: tone.soft, shape: BoxShape.circle),
            child: AppIcon(
              AppIcons.clock,
              color: tone.strong,
              size: AppIconSize.md,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prochain cours',
                  style: AppTextStyles.caption.copyWith(
                    color: tone.strong,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  session.course.titre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.dark,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$rangeLabel · ${timeUntilLabel(session.start, now: now)}',
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
