import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/app_empty_state.dart';
import '../../../../shared/components/app_error_state.dart';
import '../../controllers/grades_controller.dart';
import '../../data/grades_repository.dart';
import '../../models/grades_releve.dart';
import '../widgets/grades_average_card.dart';
import '../widgets/grades_header.dart';
import '../widgets/grades_matiere_card.dart';
import '../widgets/grades_skeleton.dart';

/// Onglet « Notes & évaluations » de l'espace étudiant.
///
/// Le corps de l'écran (la coquille fournit l'AppBar « Notes » via le
/// [StudentShell]) orchestre uniquement les états d'interface :
/// - chargement initial → [GradesSkeleton] (pulsation) ;
/// - erreur initiale → message + Réessayer ;
/// - relevé → en-tête, carte « Moyenne générale » avec mention réelle,
///   puis la liste des matières (moyennes et coefficients réels), ou
///   l'état vide.
///
/// Toutes les valeurs — moyennes, mention, compte d'évaluations — sont
/// calculées par le backend (`GET /notes/mes-notes`, JWT) : aucun calcul
/// ni aucune donnée inventée côté client. Le pull-to-refresh recharge le
/// relevé sans effacer l'écran.
class GradesScreen extends StatefulWidget {
  const GradesScreen({super.key, this.repository});

  /// Point d'injection pour les tests (sinon fabriqué avec l'API réelle).
  final GradesRepository? repository;

  @override
  State<GradesScreen> createState() => _GradesScreenState();
}

class _GradesScreenState extends State<GradesScreen> {
  late final GradesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = GradesController(repository: widget.repository);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_controller.load());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GradesController>.value(
      value: _controller,
      child: Consumer<GradesController>(
        builder: (BuildContext context, GradesController controller, _) {
          final GradesReleve? releve = controller.releve;

          // Chargement initial ou erreur initiale (aucune donnée).
          if (releve == null) {
            if (controller.error != null) {
              return AppErrorState(
                message:
                    'Impossible de charger vos notes.\n'
                    'Vérifiez votre connexion puis réessayez.',
                onRetry: controller.load,
              );
            }
            return const GradesSkeleton();
          }

          return _buildContent(controller, releve);
        },
      ),
    );
  }

  Widget _buildContent(GradesController controller, GradesReleve releve) {
    return RefreshIndicator(
      onRefresh: () => _refresh(controller),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          const GradesHeader(),
          const SizedBox(height: AppSpacing.lg),
          GradesAverageCard(releve: releve),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Matières',
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${releve.matieres.length} matière(s)',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grayLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (releve.matieres.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: AppEmptyState(
                icon: AppIcons.evaluation,
                title: 'Aucune note',
                message:
                    'Vos relevés apparaîtront ici dès que vos '
                    'enseignants corrigeront vos évaluations.',
              ),
            )
          else
            for (final GradesMatiere matiere in releve.matieres) ...[
              GradesMatiereCard(
                matiere: matiere,
                onTap: () => _openMatiere(context, matiere),
              ),
              if (matiere != releve.matieres.last)
                const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }

  /// Navigation vers la fiche détaillée de la matière : la matière est
  /// passée telle quelle via `extra` (aucune seconde requête réseau).
  void _openMatiere(BuildContext context, GradesMatiere matiere) {
    context.push(
      AppRoutes.gradesMatiereDetail.replaceAll(':id', '${matiere.matiereId}'),
      extra: matiere,
    );
  }

  /// Pull-to-refresh : recharge sans effacer le contenu affiché ; une
  /// erreur de rafraîchissement est signalée par une snackbar.
  Future<void> _refresh(GradesController controller) async {
    await controller.refresh();
    if (!mounted) return;

    if (controller.error != null && controller.releve != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Impossible d\'actualiser vos notes.')),
        );
    }
  }
}
