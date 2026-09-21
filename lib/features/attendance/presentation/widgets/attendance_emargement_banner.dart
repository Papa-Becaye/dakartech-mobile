import 'package:flutter/material.dart';

import '../../../../core/icons/app_icon.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/components/app_badge.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../models/attendance_overview.dart';

/// Bandeau d'émargement de la séance en cours (fenêtre ouverte), ou vide
/// quand aucune séance n'est émargeable.
///
/// Affiché uniquement quand le backend renvoie une séance dont la fenêtre
/// `[date, date + duree)` est ouverte : bouton réel d'émargement (utilisé
/// une seule fois, contraint par `@@unique` côté serveur), état « déjà
/// émargé » après succès.
class AttendanceEmargementBanner extends StatelessWidget {
  const AttendanceEmargementBanner({
    super.key,
    required this.emargement,
    required this.isSubmitting,
    required this.onEmarger,
  });

  final AttendanceEmargementState emargement;
  final bool isSubmitting;

  /// Déclenché par le bouton d'émargement (jamais quand la séance est
  /// absente ou déjà émargée).
  final VoidCallback onEmarger;

  @override
  Widget build(BuildContext context) {
    final AttendanceOngoingSeance? seance = emargement.seance;
    if (seance == null) return const SizedBox.shrink();

    final DateTime fin = seance.date.add(Duration(hours: seance.duree));
    final String horaire =
        '${formatFrenchHour(seance.date)} – '
        '${formatFrenchHour(fin)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: emargement.fait ? AppColors.successSoft : AppColors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppIcon(
                emargement.fait ? AppIcons.taskDone : AppIcons.clock,
                size: 18,
                color: emargement.fait ? AppColors.success : AppColors.primary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Séance en cours',
                  style: AppTextStyles.label.copyWith(
                    color: emargement.fait
                        ? AppColors.success
                        : AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppBadge(
                label: emargement.fait ? 'Émargé' : 'En cours',
                variant: emargement.fait
                    ? AppBadgeVariant.success
                    : AppBadgeVariant.primary,
                icon: emargement.fait ? AppIcons.check : AppIcons.inProgress,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            seance.chapitre.isEmpty
                ? seance.cours.titre
                : '${seance.chapitre} — ${seance.cours.titre}',
            style: AppTextStyles.body.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            '${formatFrenchDay(seance.date)} • $horaire',
            style: AppTextStyles.caption.copyWith(color: AppColors.gray),
          ),
          if (seance.cours.enseignantFullName != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(
              seance.cours.enseignantFullName!,
              style: AppTextStyles.caption.copyWith(color: AppColors.grayLight),
            ),
          ],
          if (emargement.fait) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Votre présence a bien été enregistrée.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ] else if (emargement.autorise) ...[
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Émarger ma présence',
              icon: AppIcons.userCheck,
              variant: AppButtonVariant.primary,
              isLoading: isSubmitting,
              onPressed: isSubmitting ? null : onEmarger,
            ),
          ],
        ],
      ),
    );
  }
}
