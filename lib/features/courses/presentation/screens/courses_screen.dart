import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/icons/app_icons.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/components/app_empty_state.dart';
import '../../../../shared/components/app_error_state.dart';
import '../../../../shared/components/app_loading.dart';
import '../../data/models/course_model.dart';
import '../../data/repositories/courses_repository.dart';
import '../../controllers/courses_controller.dart';
import '../widgets/course_card.dart';
import '../widgets/course_filter_chips.dart';
import '../widgets/course_search_bar.dart';

/// Écran « Mes cours » : liste des cours réellement retournés par
/// l'API (`GET /cours/mes-cours`).
///
/// Orchestre uniquement les états d'interface :
/// - chargement initial → [AppLoading] ;
/// - erreur initiale → message + Réessayer ;
/// - liste vide (API) → état vide « Aucun cours disponible » ;
/// - données → recherche + filtres (local, sur les champs réels du
///   backend) puis liste filtrée, ou état « Aucun cours trouvé ».
///
/// La recherche et les filtres sont appliqués par [CoursesController]
/// sur la liste déjà reçue de l'API : la source de vérité reste le
/// backend, aucune donnée n'est modifiée ni inventée ici. Aucun appel
/// réseau dans ce widget : tout passe par le contrôleur. L'AppBar et
/// la bottom navigation sont gérées par le [StudentShell].
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key, this.repository});

  /// Point d'injection pour les tests (sinon fabriqué avec l'API réelle).
  final CoursesRepository? repository;

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  late final CoursesController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = CoursesController(repository: widget.repository);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_controller.load());
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CoursesController>.value(
      value: _controller,
      child: Consumer<CoursesController>(
        builder: (BuildContext context, CoursesController controller, _) {
          final List<Course>? courses = controller.courses;

          // Chargement initial ou erreur initiale (aucune donnée).
          if (courses == null) {
            if (controller.error != null) {
              return AppErrorState(
                message:
                    'Impossible de charger vos cours.\n'
                    'Vérifiez votre connexion puis réessayez.',
                onRetry: controller.load,
              );
            }
            return const AppLoading(message: 'Chargement de vos cours…');
          }

          // Liste vide : état vide réel, aucun affichage de données fictives.
          if (courses.isEmpty) {
            return _ScrollableFill(
              onRefresh: controller.refresh,
              child: AppEmptyState(
                icon: AppIcons.courses,
                title: 'Aucun cours disponible',
                message:
                    'Aucun cours n\'est actuellement associé '
                    'à votre profil étudiant.',
                actionLabel: 'Actualiser',
                onAction: controller.load,
              ),
            );
          }

          final List<Course> visible = controller.visibleCourses;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.sm,
                  AppSpacing.md,
                  0,
                ),
                child: CourseSearchBar(
                  controller: _searchController,
                  onChanged: controller.setSearchQuery,
                  onClear: () => _clearSearch(controller),
                ),
              ),
              // Filtres uniquement déduits des données API (matières et
              // enseignants réellement présents) ; groupes cachés s'ils
              // n'ont qu'une valeur (filtrer n'aurait aucun sens).
              if (controller.matiereFilterOptions.length > 1 ||
                  controller.enseignantFilterOptions.length > 1)
                CourseFilterChips(
                  matiereOptions: controller.matiereFilterOptions,
                  enseignantOptions: controller.enseignantFilterOptions,
                  selectedMatiereId: controller.selectedMatiereId,
                  selectedEnseignantId: controller.selectedEnseignantId,
                  onMatiereSelected: controller.toggleMatiereFilter,
                  onEnseignantSelected: controller.toggleEnseignantFilter,
                ),
              Expanded(
                child: visible.isEmpty
                    ? _NoResultsView(
                        onRefresh: () => _refresh(controller),
                        onClearFilters: () => _clearAllFilters(controller),
                      )
                    : RefreshIndicator(
                        onRefresh: () => _refresh(controller),
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            AppSpacing.xxl,
                          ),
                          itemCount: visible.length,
                          itemBuilder: (BuildContext context, int index) {
                            final Course course = visible[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: CourseCard(
                                course: course,
                                onTap: () => _openCourse(context, course),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Efface uniquement le texte de recherche (les filtres restent).
  void _clearSearch(CoursesController controller) {
    _searchController.clear();
    controller.setSearchQuery('');
  }

  /// Efface recherche + filtres : la liste complète reçue de l'API est
  /// de nouveau affichée.
  void _clearAllFilters(CoursesController controller) {
    _searchController.clear();
    controller.clearFilters();
  }

  /// Pull-to-refresh : recharge en gardant la liste affichée.
  Future<void> _refresh(CoursesController controller) async {
    await controller.refresh();
    if (!mounted) return;

    if (controller.error != null && controller.courses != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Impossible d\'actualiser vos cours.')),
        );
    }
  }

  /// Navigation vers la fiche du cours.
  ///
  /// La route `AppRoutes.courseDetail` (`/course/:id`) existe déjà
  /// (placeholder) — la page de détail complète sera créée à l'étape
  /// suivante. On prépare simplement le clic avec le vrai `course.id`.
  void _openCourse(BuildContext context, Course course) {
    context.push(AppRoutes.courseDetail.replaceAll(':id', '${course.id}'));
  }
}

/// Zone scrollable pleine hauteur : rend le pull-to-refresh utilisable
/// même quand le contenu ne remplit pas l'écran (états vides).
class _ScrollableFill extends StatelessWidget {
  const _ScrollableFill({required this.onRefresh, required this.child});

  final RefreshCallback onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// État « aucun résultat » : visible uniquement quand la recherche et/ou
/// les filtres écartent tous les cours réellement reçus de l'API.
/// Propose « Effacer les filtres » pour revenir à la liste complète.
class _NoResultsView extends StatelessWidget {
  const _NoResultsView({required this.onRefresh, required this.onClearFilters});

  final RefreshCallback onRefresh;
  final VoidCallback onClearFilters;

  @override
  Widget build(BuildContext context) {
    return _ScrollableFill(
      onRefresh: onRefresh,
      child: AppEmptyState(
        icon: AppIcons.searchOff,
        title: 'Aucun cours trouvé',
        message: 'Aucun cours ne correspond à votre recherche.',
        actionLabel: 'Effacer les filtres',
        onAction: onClearFilters,
      ),
    );
  }
}
