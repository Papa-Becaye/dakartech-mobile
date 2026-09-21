import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

enum AppBadgeVariant { neutral, primary, accent, success, warning, error }

/// Élément d'étiquette arrondi pour les statuts, catégories, etc.
class AppBadge extends StatelessWidget {
  const AppBadge({
    super.key,
    required this.label,
    this.variant = AppBadgeVariant.neutral,
    this.icon,
  });

  final String label;
  final AppBadgeVariant variant;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (Color background, Color foreground) = switch (variant) {
      AppBadgeVariant.neutral => (AppColors.graySoft, AppColors.gray),
      AppBadgeVariant.primary => (AppColors.primarySoft, AppColors.primary),
      AppBadgeVariant.accent => (AppColors.accentSoft, AppColors.accent),
      AppBadgeVariant.success => (AppColors.successSoft, AppColors.success),
      AppBadgeVariant.warning => (AppColors.warningSoft, AppColors.warning),
      AppBadgeVariant.error => (AppColors.errorSoft, AppColors.error),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 2,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: AppSpacing.xxs),
          ],
          Text(
            label,
            style: AppTextStyles.label.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}
