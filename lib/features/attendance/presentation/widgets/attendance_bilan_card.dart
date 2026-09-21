import 'package:flutter/material.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/app_badge.dart';
import '../../models/attendance_overview.dart';

/// Carte récapitulative de l'assiduité : taux global, décompte des séances
/// passées/présences/absences et appréciation dérivée par le backend.
class AttendanceBilanCard extends StatelessWidget {
  const AttendanceBilanCard({
    super.key,
    required this.bilan,
    required this.etudiant,
  });

  final AttendanceBilan bilan;
  final AttendanceEtudiant etudiant;

  AppBadgeVariant _varianteAppreciation() {
    if (bilan.seancesPassees == 0 || bilan.taux >= 90) {
      return AppBadgeVariant.success;
    }
    if (bilan.taux >= 75) return AppBadgeVariant.primary;
    if (bilan.taux >= 50) return AppBadgeVariant.warning;
    return AppBadgeVariant.error;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Étudiant concerné + classe.
          Text(
            'Assiduité de ${etudiant.fullName}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          if (etudiant.classeNom != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              'Classe ${etudiant.classeNom}',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Taux global.
              Text(
                '${bilan.taux}%',
                style: AppTextStyles.display.copyWith(color: AppColors.white),
              ),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Text(
                  'de présence',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ],
          ),
          if (bilan.appreciation != null) ...[
            const SizedBox(height: AppSpacing.xs),
            AppBadge(
              label: bilan.appreciation!,
              icon: AppIcons.trendingUp,
              variant: _varianteAppreciation(),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _StatCount(
                  label: 'Séances passées',
                  value: bilan.seancesPassees,
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatCount(label: 'Présences', value: bilan.presences),
                const SizedBox(width: AppSpacing.sm),
                _StatCount(label: 'Absences', value: bilan.absences),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCount extends StatelessWidget {
  const _StatCount({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: AppTextStyles.title.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.white.withValues(alpha: 0.8),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
