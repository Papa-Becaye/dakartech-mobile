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
import 'course_progress_card.dart';

/// Section « Mes cours » du dashboard.
///
/// Affiche « Mes cours » avec le nombre d'UEs, un lien « Tout afficher »
/// et une carte de progression par cours.
class CoursesSection extends StatelessWidget {
  const CoursesSection({super.key, required this.courses});

  final List<CourseItem> courses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text('Mes cours', style: AppTextStyles.title),
                  if (courses.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs - 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primarySoft,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '${courses.length} UEs',
                        style: AppTextStyles.caption.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.go(AppRoutes.courses),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Tout afficher'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (courses.isEmpty)
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
                Icon(AppIcons.courses, size: 32, color: AppColors.grayLight),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Aucun cours à afficher',
                  style: AppTextStyles.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.dark,
                  ),
                ),
              ],
            ),
          )
        else
          ..._buildCourseList(),
      ],
    );
  }

  List<Widget> _buildCourseList() {
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < courses.length; i++) {
      children.add(CourseProgressCard(course: courses[i]));
      if (i < courses.length - 1) {
        children.add(const SizedBox(height: AppSpacing.sm));
      }
    }
    return children;
  }
}
