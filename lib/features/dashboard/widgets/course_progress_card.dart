import 'package:flutter/material.dart';

import '../../../core/icons/app_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/course_item.dart';

/// Carte d'un cours du dashboard.
///
/// Icône, titre, enseignant, prochaine séance. La barre de progression
/// et le pourcentage ne sont affichés que lorsque le backend fournit
/// réellement une progression ([CourseItem.progress] non nul) — sinon
/// l'information est simplement masquée, aucune valeur inventée.
class CourseProgressCard extends StatelessWidget {
  const CourseProgressCard({super.key, required this.course});

  final CourseItem course;

  @override
  Widget build(BuildContext context) {
    final double? progress = course.progress;
    final String? nextSession = course.nextSessionLabel;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.dark.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: progress == null
                      ? AppColors.primarySoft
                      : _accentColorFor(progress),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  _iconFor(course.iconName),
                  size: 22,
                  color: progress == null
                      ? AppColors.primaryContainer
                      : _iconColorFor(progress),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            course.title,
                            style: AppTextStyles.label.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (nextSession != null && nextSession.isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.xs),
                          Align(
                            child: _SessionLabel(
                              label: nextSession,
                              color: progress == null
                                  ? AppColors.grayLight
                                  : _sessionColorFor(progress),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Enseignant : ${course.teacherName ?? '—'}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grayLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0, 100) / 100,
                      minHeight: 6,
                      backgroundColor: AppColors.graySoft,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _progressColorFor(progress),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${progress.clamp(0, 100).toInt()}%',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _progressColorFor(progress),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionLabel extends StatelessWidget {
  const _SessionLabel({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// Couleur de fond de l'icône selon la progression (teintes discrètes).
Color _accentColorFor(double progress) {
  if (progress >= 85) return AppColors.greenLight;
  if (progress >= 65) return AppColors.blueLight;
  if (progress >= 40) return AppColors.orangeLight;
  return AppColors.redLight;
}

/// Couleur de l'icône (variant légèrement saturé du fond).
Color _iconColorFor(double progress) {
  if (progress >= 85) return AppColors.success;
  if (progress >= 65) return AppColors.primaryContainer;
  if (progress >= 40) return AppColors.warning;
  return AppColors.error;
}

/// Couleur de la barre de progression.
Color _progressColorFor(double progress) {
  if (progress >= 85) return AppColors.success;
  if (progress >= 65) return AppColors.primaryContainer;
  if (progress >= 40) return AppColors.warning;
  return AppColors.error;
}

/// Couleur du badge de prochaine séance.
Color _sessionColorFor(double progress) {
  if (progress >= 65) return AppColors.primaryContainer;
  return AppColors.grayLight;
}

/// Mappe le nom d'icône (API/mock) vers un [IconData] Material.
IconData _iconFor(String? iconName) {
  return switch (iconName) {
    'database' => AppIcons.database,
    'devices' => AppIcons.devices,
    'router' => AppIcons.router,
    'rocket_launch' => AppIcons.rocket,
    _ => AppIcons.courses,
  };
}
