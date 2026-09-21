import 'package:flutter/material.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../shared/components/app_empty_state.dart';
import '../../../courses/data/models/course_detail.dart';
import '../../models/grades_releve.dart';
import '../widgets/grades_evaluation_tile.dart';
import '../widgets/grades_mention.dart';

/// Filtre local par type d'évaluation (aucun appel réseau, aucune moyenne
/// recalculée — seul l'affichage des évaluations est filtré).
enum GradesEvaluationFilter { all, devoir, examen, projet }

/// Fiche détaillée d'une matière : moyenne réelle (calculée par le
/// backend), coefficient, nombre d'évaluations et liste des évaluations
/// filtrée localement par type.
///
/// La matière affichée provient du relevé déjà chargé de l'onglet
/// « Notes » (passée via `extra` de la route `/notes/matiere/:id`) :
/// l'écran ne refait aucun appel réseau.
class GradesMatiereScreen extends StatefulWidget {
  const GradesMatiereScreen({super.key, required this.matiere});

  final GradesMatiere matiere;

  @override
  State<GradesMatiereScreen> createState() => _GradesMatiereScreenState();
}

class _GradesMatiereScreenState extends State<GradesMatiereScreen> {
  GradesEvaluationFilter _filter = GradesEvaluationFilter.all;

  @override
  Widget build(BuildContext context) {
    final GradesMatiere matiere = widget.matiere;
    final List<GradesEvaluation> evaluations = _filtered(
      matiere.evaluations,
      _filter,
    );

    return Scaffold(
      appBar: AppBar(title: Text(matiere.matiere)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          _MatiereSummaryCard(matiere: matiere),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Évaluations',
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${matiere.evaluations.length} évaluation(s)',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grayLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _FilterChips(
            value: _filter,
            onChanged: (GradesEvaluationFilter filter) {
              setState(() => _filter = filter);
            },
          ),
          const SizedBox(height: AppSpacing.md),
          if (evaluations.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: AppEmptyState(
                icon: AppIcons.evaluation,
                title: matiere.evaluations.isEmpty
                    ? 'Aucune évaluation'
                    : 'Aucun résultat',
                message: matiere.evaluations.isEmpty
                    ? 'Aucune évaluation pour cette matière pour le moment.'
                    : 'Aucune évaluation ne correspond à ce filtre.',
              ),
            )
          else
            for (final GradesEvaluation evaluation in evaluations) ...[
              GradesEvaluationTile(evaluation: evaluation),
              if (evaluation != evaluations.last)
                const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }

  /// Filtre local : n'altère jamais les moyennes (le backend les calcule
  /// sur l'ensemble des notes de la matière).
  List<GradesEvaluation> _filtered(
    List<GradesEvaluation> evaluations,
    GradesEvaluationFilter filter,
  ) {
    return switch (filter) {
      GradesEvaluationFilter.all => evaluations,
      GradesEvaluationFilter.devoir =>
        evaluations
            .where(
              (evaluation) => evaluation.type == CourseEvaluationType.devoir,
            )
            .toList(growable: false),
      GradesEvaluationFilter.examen =>
        evaluations
            .where(
              (evaluation) => evaluation.type == CourseEvaluationType.examen,
            )
            .toList(growable: false),
      GradesEvaluationFilter.projet =>
        evaluations
            .where(
              (evaluation) => evaluation.type == CourseEvaluationType.projet,
            )
            .toList(growable: false),
    };
  }
}

/// Carte de synthèse de la matière : moyenne réelle + mention dérivée
/// localement, coefficient et nombre d'évaluations notées.
class _MatiereSummaryCard extends StatelessWidget {
  const _MatiereSummaryCard({required this.matiere});

  final GradesMatiere matiere;

  @override
  Widget build(BuildContext context) {
    final double? moyenne = matiere.moyenne;
    final (Color strong, Color soft) = mentionBand(
      moyenne == null ? null : localMentionForMoyenne(moyenne),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A151C27),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Moyenne de la matière',
            style: AppTextStyles.caption.copyWith(color: AppColors.grayLight),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                moyenne == null ? '—' : formatCoefficient(moyenne),
                style: AppTextStyles.display.copyWith(
                  fontSize: 34,
                  color: AppColors.dark,
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Text(
                '/20',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grayLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (moyenne != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    localMentionForMoyenne(moyenne),
                    style: AppTextStyles.caption.copyWith(
                      color: strong,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: AppIcons.ticket,
                  value: '${matiere.evaluationsNotees}',
                  label: 'notée(s)',
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: AppIcons.scale,
                  value: formatCoefficient(matiere.coefficient),
                  label: 'coefficient',
                ),
              ),
              Expanded(
                child: _StatItem(
                  icon: AppIcons.clipboardCheck,
                  value: '${matiere.evaluations.length}',
                  label: 'évaluation(s)',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Statistique compacte (icône, valeur, libellé) de la fiche matière.
class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: AppTextStyles.title.copyWith(
            fontSize: 18,
            color: AppColors.dark,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.grayLight),
        ),
      ],
    );
  }
}

/// Sélecteur de filtre local (Toutes / Devoirs / Examens / Projets).
class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.value, required this.onChanged});

  final GradesEvaluationFilter value;
  final ValueChanged<GradesEvaluationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final GradesEvaluationFilter filter
              in GradesEvaluationFilter.values) ...[
            _Chip(
              label: switch (filter) {
                GradesEvaluationFilter.all => 'Toutes',
                GradesEvaluationFilter.devoir => 'Devoirs',
                GradesEvaluationFilter.examen => 'Examens',
                GradesEvaluationFilter.projet => 'Projets',
              },
              selected: value == filter,
              onTap: () => onChanged(filter),
            ),
            if (filter != GradesEvaluationFilter.values.last)
              const SizedBox(width: AppSpacing.xs),
          ],
          const SizedBox(width: AppSpacing.md),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : AppColors.white,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'Geist',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.white : AppColors.gray,
            ),
          ),
        ),
      ),
    );
  }
}
