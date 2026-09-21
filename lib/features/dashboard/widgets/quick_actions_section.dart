import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/icons/app_icon.dart';
import '../../../core/icons/app_icons.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import 'section_header.dart';

/// Accès rapides du dashboard : Émarger, Ressources, Scolarité.
///
/// Trois actions en ligne avec séparateurs verticaux discrets.
/// Les fonctionnalités derrière ces boutons ne sont pas développées ici :
/// elles pointent vers les routes existantes (ou poussent une route
/// placeholder si aucune page ne correspond encore).
class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Actions rapides'),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.card,
          ),
          child: Row(
            children: [
              _QuickAction(
                icon: AppIcons.qrCode,
                label: 'Émarger',
                onTap: () => context.push(AppRoutes.attendance),
              ),
              const _VerticalDivider(),
              _QuickAction(
                icon: AppIcons.download,
                label: 'Ressources',
                onTap: () {},
              ),
              const _VerticalDivider(),
              _QuickAction(
                icon: AppIcons.support,
                label: 'Scolarité',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  shape: BoxShape.circle,
                ),
                child: AppIcon(
                  icon,
                  size: 24,
                  color: AppColors.primaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.dark,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.borderLight.withValues(alpha: 0.4),
    );
  }
}
