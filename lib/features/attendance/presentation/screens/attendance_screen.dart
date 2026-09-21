import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/components/app_empty_state.dart';
import '../../../../shared/components/app_error_state.dart';
import '../../data/attendance_repository.dart';
import '../../controllers/attendance_controller.dart';
import '../../models/attendance_overview.dart';
import '../widgets/attendance_bilan_card.dart';
import '../widgets/attendance_emargement_banner.dart';
import '../widgets/attendance_filter_chips.dart';
import '../widgets/attendance_skeleton.dart';
import '../widgets/attendance_timeline.dart';

/// Écran « Présences » (assiduité + émargement).
///
/// Ouvert par l'action rapide « Émarger » du Dashboard (route
/// `/attendance`). Orchestre uniquement les états d'interface :
/// - chargement initial → [AttendanceSkeleton] (pulsation) ;
/// - erreur initiale → message + Réessayer ;
/// - données → bandeau d'émargement réel (si une séance est en cours),
///   carte de bilan calculée par le backend, historique filtré
///   localement (Toutes / Présents / Absences), ou état vide.
///
/// Toutes les valeurs sont celles renvoyées par le backend (aucune donnée
/// fictive) : le taux, l'appréciation et les statuts PRESENT/ABSENT sont
/// décidés côté serveur, l'émargement clique sur
/// `POST /presences/:seanceId/emarger` (JWT) et l'écran reflète ensuite
/// l'état réel regagné par le serveur.
class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key, this.repository});

  /// Point d'injection pour les tests (sinon fabriqué avec l'API réelle).
  final AttendanceRepository? repository;

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late final AttendanceController _controller;
  AttendanceFilter _filter = AttendanceFilter.all;

  @override
  void initState() {
    super.initState();
    _controller = AttendanceController(repository: widget.repository);
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
    return Scaffold(
      appBar: AppBar(title: const Text('Présences')),
      body: ChangeNotifierProvider<AttendanceController>.value(
        value: _controller,
        child: Consumer<AttendanceController>(
          builder: (BuildContext context, AttendanceController controller, _) {
            final AttendanceOverview? overview = controller.overview;

            // Chargement initial ou erreur initiale (aucune donnée).
            if (overview == null) {
              if (controller.error != null) {
                return AppErrorState(
                  message:
                      'Impossible de charger votre assiduité.\n'
                      'Vérifiez votre connexion puis réessayez.',
                  onRetry: controller.load,
                );
              }
              return const AttendanceSkeleton();
            }

            return _buildContent(controller, overview);
          },
        ),
      ),
    );
  }

  Widget _buildContent(
    AttendanceController controller,
    AttendanceOverview overview,
  ) {
    final List<AttendanceHistoryEntry> history = _filteredHistory(overview);

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
          // Séance en cours : émargement réel (si la fenêtre est ouverte).
          AttendanceEmargementBanner(
            emargement: overview.emargement,
            isSubmitting:
                controller.emargingSeanceId == overview.emargement.seance?.id,
            onEmarger: () => _emarger(controller, overview.emargement.seance!),
          ),
          if (overview.emargement.seance != null)
            const SizedBox(height: AppSpacing.md),

          // Bilan d'assiduité calculé par le backend.
          AttendanceBilanCard(
            bilan: overview.bilan,
            etudiant: overview.etudiant,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Historique + filtres locaux.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Historique',
                  style: AppTextStyles.title.copyWith(
                    color: AppColors.dark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${overview.historique.length} séance(s)',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.grayLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          AttendanceFilterChips(
            value: _filter,
            onChanged: (AttendanceFilter filter) {
              setState(() => _filter = filter);
            },
          ),
          const SizedBox(height: AppSpacing.md),

          if (history.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg),
              child: AppEmptyState(
                icon: AppIcons.clipboardCheck,
                title: _filter == AttendanceFilter.all
                    ? 'Aucune séance passée'
                    : 'Aucun résultat',
                message: _filter == AttendanceFilter.all
                    ? 'L\'historique de présence apparaîtra ici dès que '
                          'vos séances commenceront.'
                    : 'Aucune séance ne correspond à ce filtre.',
              ),
            )
          else
            AttendanceTimeline(entries: history),
        ],
      ),
    );
  }

  /// Historique localement filtré (Toutes / Présents / Absences).
  List<AttendanceHistoryEntry> _filteredHistory(AttendanceOverview overview) {
    return switch (_filter) {
      AttendanceFilter.all => overview.historique,
      AttendanceFilter.present =>
        overview.historique
            .where((entry) => entry.estPresent)
            .toList(growable: false),
      AttendanceFilter.absent =>
        overview.historique
            .where((entry) => !entry.estPresent)
            .toList(growable: false),
    };
  }

  /// Émarge la présence de la séance en cours puis affiche le résultat
  /// (succès vert, ou message d'erreur — déjà émargé / fenêtre fermée).
  Future<void> _emarger(
    AttendanceController controller,
    AttendanceOngoingSeance seance,
  ) async {
    final AppException? failure = await controller.emarger(seance.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failure == null
                ? 'Présence émargée avec succès.'
                : (failure.message.isEmpty
                      ? 'Impossible d\'émarger votre présence.'
                      : failure.message),
          ),
          backgroundColor: failure == null
              ? AppColors.success
              : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Pull-to-refresh : recharge sans effacer le contenu affiché ; une
  /// erreur de rafraîchissement est signalée par une snackbar.
  Future<void> _refresh(AttendanceController controller) async {
    await controller.refresh();
    if (!mounted) return;

    if (controller.error != null && controller.overview != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'actualiser votre assiduité.'),
          ),
        );
    }
  }
}
