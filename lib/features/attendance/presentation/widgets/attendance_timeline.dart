import 'package:flutter/material.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/components/app_badge.dart';
import '../../models/attendance_overview.dart';

/// Historique des séances passées de l'étudiant, statut de présence réel
/// côté serveur (`PRESENT` / `ABSENT`).
class AttendanceTimeline extends StatelessWidget {
  const AttendanceTimeline({super.key, required this.entries});

  final List<AttendanceHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final List<Widget> cards = <Widget>[];
    for (int i = 0; i < entries.length; i++) {
      cards.add(_AttendanceEntryCard(entry: entries[i]));
      if (i < entries.length - 1) {
        cards.add(const SizedBox(height: AppSpacing.sm));
      }
    }
    return Column(children: cards);
  }
}

class _AttendanceEntryCard extends StatelessWidget {
  const _AttendanceEntryCard({required this.entry});

  final AttendanceHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final AttendanceCours cours = entry.cours;
    final DateTime fin = entry.date.add(Duration(hours: entry.duree));
    final bool present = entry.estPresent;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bloc date (jour + mois abrégé).
          Container(
            width: 48,
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            decoration: BoxDecoration(
              color: present ? AppColors.successSoft : AppColors.errorSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              children: [
                Text(
                  '${entry.date.day}',
                  style: AppTextStyles.title.copyWith(
                    color: present ? AppColors.success : AppColors.error,
                    fontSize: 18,
                  ),
                ),
                Text(
                  formatFrenchMonthShort(entry.date),
                  style: AppTextStyles.caption.copyWith(
                    color: present ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Contenu principal.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cours.titre,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (cours.matiereNom != null &&
                    cours.matiereNom != cours.titre) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Matière : ${cours.matiereNom}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.grayLight,
                    ),
                  ),
                ],
                if (entry.chapitre.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    entry.chapitre,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.gray,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${formatFrenchDay(entry.date)} — '
                  '${formatFrenchHour(entry.date)} à ${formatFrenchHour(fin)}h',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.grayLight,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    AppBadge(
                      label: entry.statut.label,
                      variant: present
                          ? AppBadgeVariant.success
                          : AppBadgeVariant.error,
                      icon: present ? AppIcons.checkCircle : AppIcons.xCircle,
                    ),
                    if (entry.remarque != null &&
                        entry.remarque!.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          entry.remarque!,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.error,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                if (present && entry.emargeLe != null) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Émargé à ${formatFrenchHour(entry.emargeLe!)}',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
