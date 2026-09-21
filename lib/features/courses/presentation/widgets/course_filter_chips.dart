import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../data/models/course_model.dart';

/// Filtres de la liste des cours.
///
/// Uniquement déduits des données réellement reçues de l'API : les
/// matières et les enseignants présents dans la liste (via
/// [CoursesController]). Aucun filtre inventé pour des informations
/// absentes du backend.
///
/// Un groupe n'est affiché que s'il propose au moins deux valeurs
/// (filtrer sur une valeur unique n'aurait aucun sens). Chaque groupe
/// est sélectionnable indépendamment : les filtres se combinent entre
/// eux et avec la recherche.
class CourseFilterChips extends StatelessWidget {
  const CourseFilterChips({
    super.key,
    required this.matiereOptions,
    required this.enseignantOptions,
    this.selectedMatiereId,
    this.selectedEnseignantId,
    required this.onMatiereSelected,
    required this.onEnseignantSelected,
  });

  final List<CourseMatiere> matiereOptions;
  final List<CourseEnseignant> enseignantOptions;
  final int? selectedMatiereId;
  final int? selectedEnseignantId;

  /// Appelé avec l'id de la matière choisie (le contrôleur gère la
  /// désélection par un second appui).
  final ValueChanged<int> onMatiereSelected;

  final ValueChanged<int> onEnseignantSelected;

  @override
  Widget build(BuildContext context) {
    final bool showMatiere = matiereOptions.length > 1;
    final bool showEnseignant = enseignantOptions.length > 1;
    if (!showMatiere && !showEnseignant) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        0,
        AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showMatiere) ...[
            const _GroupLabel(label: 'Matière'),
            const SizedBox(height: AppSpacing.xxs),
            _ChipRow(
              children: [
                for (final CourseMatiere matiere in matiereOptions)
                  _FilterChip(
                    label: matiere.nom,
                    selected: matiere.id == selectedMatiereId,
                    onSelected: () => onMatiereSelected(matiere.id),
                  ),
              ],
            ),
          ],
          if (showEnseignant) ...[
            if (showMatiere) const SizedBox(height: AppSpacing.sm),
            const _GroupLabel(label: 'Enseignant'),
            const SizedBox(height: AppSpacing.xxs),
            _ChipRow(
              children: [
                for (final CourseEnseignant enseignant in enseignantOptions)
                  _FilterChip(
                    label: enseignant.fullName,
                    selected: enseignant.id == selectedEnseignantId,
                    onSelected: () => onEnseignantSelected(enseignant.id),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Libellé discret d'un groupe de filtres (« Matière », « Enseignant »).
class _GroupLabel extends StatelessWidget {
  const _GroupLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.caption.copyWith(
        color: AppColors.grayLight,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

/// Ligne de puces déroulable horizontalement (jamais d'overflow sur
/// petits écrans).
class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final Widget child in children) ...[
            child,
            const SizedBox(width: AppSpacing.xs),
          ],
          const SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }
}

/// Puce de filtre unique, stylée avec les couleurs DakarTech.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      backgroundColor: AppColors.graySoft,
      selectedColor: AppColors.primarySoft,
      checkmarkColor: AppColors.primary,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      labelStyle: AppTextStyles.label.copyWith(
        fontSize: 13,
        height: 1.2,
        color: selected ? AppColors.primary : AppColors.gray,
      ),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      showCheckmark: true,
    );
  }
}
