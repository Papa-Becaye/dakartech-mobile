import 'package:flutter/material.dart';

import '../../../../core/icons/app_icon.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_format.dart';
import '../../models/grades_releve.dart';
import 'grades_mention.dart';

/// Carte « Moyenne générale » : moyenne réelle sur 20 (forme à virgule
/// française), mention dérivée par le backend, barre de progression et
/// informations de classe / année académique réelles.
///
/// Aucune valeur inventée : [moyenneGenerale], [mention] et le nombre
/// d'évaluations notées proviennent de `GET /notes/mes-notes`.
class GradesAverageCard extends StatelessWidget {
  const GradesAverageCard({super.key, required this.releve});

  final GradesReleve releve;

  @override
  Widget build(BuildContext context) {
    final double? moyenne = releve.moyenneGenerale;
    final (Color strong, Color soft) = mentionBand(releve.mention);
    final int notee = releve.matieres.fold<int>(
      0,
      (total, matiere) => total + matiere.evaluationsNotees,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryContainer],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Moyenne générale',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                notee > 0 ? '$notee évaluation(s) notée(s)' : 'Aucune note',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.white.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            textBaseline: TextBaseline.alphabetic,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            children: [
              Text(
                moyenne == null ? '—' : formatCoefficient(moyenne),
                style: AppTextStyles.display.copyWith(color: AppColors.white),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                '/20',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.white.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (releve.mention != null) ...[
                const SizedBox(width: AppSpacing.sm),
                _MentionChip(mention: releve.mention!, strong: strong),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (moyenne != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.full),
              child: LinearProgressIndicator(
                value: (moyenne / 20).clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.white.withValues(alpha: 0.25),
                valueColor: AlwaysStoppedAnimation<Color>(strong),
              ),
            )
          else
            Text(
              'Vos notes apparaîtront ici dès que vos enseignants '
              'corrigeront vos évaluations.',
              style: AppTextStyles.caption.copyWith(
                color: AppColors.white.withValues(alpha: 0.8),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          _ClasseFooter(releve: releve),
        ],
      ),
    );
  }
}

/// Pastille de la mention de la moyenne générale (calculée par le
/// backend).
class _MentionChip extends StatelessWidget {
  const _MentionChip({required this.mention, required this.strong});

  final String mention;
  final Color strong;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        mention,
        style: AppTextStyles.caption.copyWith(
          color: strong,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Ligne d'information : classe réelle + année académique réelle.
class _ClasseFooter extends StatelessWidget {
  const _ClasseFooter({required this.releve});

  final GradesReleve releve;

  @override
  Widget build(BuildContext context) {
    final String annee = releve.etudiant.classe.annee?.libelle ?? '';
    final String classe = releve.etudiant.classe.nom;

    return Row(
      children: [
        const AppIcon(AppIcons.school, size: 16, color: Colors.white),
        const SizedBox(width: AppSpacing.xxs),
        Expanded(
          child: Text(
            annee.isEmpty ? classe : '$classe · $annee',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
