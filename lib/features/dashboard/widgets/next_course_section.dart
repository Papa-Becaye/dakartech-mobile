import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/course_item.dart';
import 'course_day_label.dart';
import 'section_header.dart';

/// Libellé du temps restant avant le prochain cours.
///
/// Recalcule dynamiquement à partir de l'heure de début :
/// - « Commence maintenant » : si dans moins d'une minute ;
/// - « Dans X min » : si dans moins d'une heure ;
/// - « Dans X h » : sinon.
String nextCourseCountdown(CourseItem course, {DateTime? now}) {
  final DateTime current = now ?? DateTime.now();
  final DateTime? date = course.date;

  // Heure de début reconstruite à partir de la date + startTime.
  DateTime? start;
  final String? startTime = course.startTime;
  if (startTime != null && startTime.isNotEmpty) {
    final List<String> parts = startTime.split(':');
    if (parts.length == 2) {
      final int? h = int.tryParse(parts[0]);
      final int? m = int.tryParse(parts[1]);
      if (h != null && m != null) {
        final DateTime base = date ?? current;
        start = DateTime(base.year, base.month, base.day, h, m);
      }
    }
  }
  if (start == null) return '';

  final Duration diff = start.difference(current);
  if (diff.isNegative) return 'Terminé';
  final int minutes = diff.inMinutes;
  if (minutes < 1) return 'Commence maintenant';
  if (minutes < 60) return 'Dans $minutes min';
  final int hours = diff.inHours;
  if (hours < 24) return 'Dans $hours h';
  return 'Dans ${diff.inDays} j';
}

/// Section « Prochain cours » du dashboard.
///
/// Carte mise en avant avec fond blanc, rayon important, ombre légère
/// et un effet décoratif circulaire dans l'angle, badges horaire et
/// compte à rebours, informations (salle, campus, enseignant) et bouton
/// principal bleu.
class NextCourseSection extends StatelessWidget {
  const NextCourseSection({super.key, this.course});

  /// Prochain cours réel, ou `null` si aucune séance n'est programmée à
  /// venir (l'UI affiche alors un état vide explicite).
  final CourseItem? course;

  @override
  Widget build(BuildContext context) {
    final CourseItem? course = this.course;
    if (course == null) {
      return _buildEmpty(context);
    }

    final String detailRoute = AppRoutes.courseDetail.replaceFirst(
      ':id',
      '${course.id}',
    );
    final String countdown = nextCourseCountdown(course);
    final bool showCountdown = countdown.isNotEmpty && countdown != 'Terminé';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Prochain cours',
          trailing: course.date != null
              ? Text(
                  courseDayLabel(course.date!),
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: [
              BoxShadow(
                color: AppColors.dark.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Effets décoratifs circulaires (accents DakarTech).
              Positioned(
                top: -36,
                right: -36,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -28,
                right: 56,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.primarySoft.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md + 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OverflowBar(
                      alignment: MainAxisAlignment.spaceBetween,
                      spacing: AppSpacing.xs,
                      overflowSpacing: AppSpacing.sm,
                      overflowAlignment: OverflowBarAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs + 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                AppIcons.clock,
                                size: 14,
                                color: AppColors.primaryContainer,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                course.timeRange,
                                style: AppTextStyles.label.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryContainer,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (showCountdown)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xxs + 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(
                                AppRadius.full,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xxs),
                                Text(
                                  countdown,
                                  style: AppTextStyles.label.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      course.title,
                      style: AppTextStyles.title.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.dark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (course.room != null || course.campus != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _InfoRow(
                        icon: AppIcons.room,
                        text: [
                          if (course.room != null) 'Salle ${course.room}',
                          if (course.campus != null) course.campus,
                        ].join(' • '),
                      ),
                    ],
                    if (course.teacherName != null) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      _InfoRow(
                        icon: AppIcons.profile,
                        text: course.teacherName!,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => context.push(detailRoute),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                          ),
                        ),
                        icon: const Icon(AppIcons.forward, size: 18),
                        iconAlignment: IconAlignment.end,
                        label: const Text('Voir le cours'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// État vide : le planning ne contient aucune séance à venir.
  Widget _buildEmpty(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Prochain cours'),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            children: [
              const Icon(
                AppIcons.calendarCheck,
                size: 32,
                color: AppColors.grayLight,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Aucun prochain cours programmé',
                style: AppTextStyles.label.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.grayLight),
        const SizedBox(width: AppSpacing.xs + 2),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.label.copyWith(
              fontSize: 13,
              color: AppColors.gray,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
