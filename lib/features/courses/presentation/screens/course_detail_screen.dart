import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/icons/app_icon.dart';
import '../../../../core/icons/app_icons.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_format.dart';
import '../../../../features/auth/widgets/dakartech_logo.dart';
import '../../../../shared/components/app_avatar.dart';
import '../../../../shared/components/app_empty_state.dart';
import '../../../../shared/components/app_error_state.dart';
import '../../../../shared/components/app_loading.dart';
import '../../../../shared/widgets/app_icon_button.dart';
import '../../controllers/course_detail_controller.dart';
import '../../data/models/course_detail.dart';
import '../../data/repositories/courses_repository.dart';
import '../widgets/course_banner.dart';
import '../widgets/course_document_card.dart';
import '../widgets/course_evaluation_card.dart';
import '../widgets/course_next_session_card.dart';
import '../widgets/course_session_card.dart';
import '../widgets/course_stats_bento.dart';

/// Écran de détail d'un cours (refonte Stitch).
///
/// Tout provient de données réelles du backend :
/// - la bannière et la prochaine séance de `GET /cours/:id` ;
/// - les séances + présence de `GET /cours/:id/seances` ;
/// - les documents de `GET /cours/:id/documents` ;
/// - les évaluations + note de `GET /cours/:id/evaluations`.
///
/// Les statistiques (séances effectuées, taux de présence, progression,
/// moyenne) sont **dérivées** de ces mêmes données — aucune valeur
/// inventée. Les actions non encore réalisables côté backend (favori,
/// contact, rappels, téléchargement) affichent un message explicite.
/// Les sections vides ou en erreur ont chacune leur propre état.
///
/// Disposition : l'en-tête et la bannière bleue restent **épinglés** ;
/// les statistiques, les onglets et le contenu défilent ensemble
/// (seule la bannière est sticky).
class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({
    super.key,
    required this.courseId,
    this.repository,
    this.studentInitials,
  });

  /// Identifiant réel du cours sélectionné dans la liste.
  final int courseId;

  /// Point d'injection pour les tests (sinon fabriqué avec l'API réelle).
  final CoursesRepository? repository;

  /// Initiales de l'étudiant affichées dans l'en-tête (fournies par le
  /// routeur, qui a accès à la session).
  final String? studentInitials;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late final CourseDetailController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CourseDetailController(
      courseId: widget.courseId,
      repository: widget.repository,
    );
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ChangeNotifierProvider<CourseDetailController>.value(
          value: _controller,
          child: Consumer<CourseDetailController>(
            builder: (BuildContext context, controller, _) {
              final CourseDetail? detail = controller.detail;

              if (detail == null) {
                if (controller.isNotFound) {
                  return AppEmptyState(
                    icon: AppIcons.searchOff,
                    title: 'Cours introuvable',
                    message:
                        'Ce cours n\'existe pas ou n\'est plus '
                        'disponible.',
                    actionLabel: 'Retour à la liste',
                    onAction: () => _goBack(context),
                  );
                }
                if (controller.error != null) {
                  return AppErrorState(
                    message:
                        'Impossible de charger les informations du '
                        'cours.\nVérifiez votre connexion puis réessayez.',
                    onRetry: controller.load,
                  );
                }
                return const AppLoading(message: 'Chargement du cours…');
              }

              return _buildContent(context, controller, detail);
            },
          ),
        ),
      ),
    );
  }

  /// En-tête fixe + bannière épinglée ; le reste défile dans
  /// [_ScrollableTabs].
  Widget _buildContent(
    BuildContext context,
    CourseDetailController controller,
    CourseDetail detail,
  ) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: <Widget>[
          _CourseHeader(
            studentInitials: widget.studentInitials,
            onBack: () => _goBack(context),
          ),
          CourseBanner(
            detail: detail,
            onBookmark: () => _showInfoSnack(
              context,
              'La mise en favori n\'est pas disponible pour le moment.',
            ),
            onContactTeacher: () => _showInfoSnack(
              context,
              'La messagerie de l\'enseignant arrive prochainement.',
            ),
          ),
          Expanded(
            child: _ScrollableTabs(
              controller: controller,
              stats: _buildStats(controller),
              onReminder: () => _showInfoSnack(
                context,
                'Les rappels de séance arrivent prochainement.',
              ),
              onDownload: () => _showInfoSnack(
                context,
                'Le téléchargement n\'est pas encore disponible.',
              ),
              onDownloadAll: () => _showInfoSnack(
                context,
                'Le téléchargement groupé n\'est pas encore disponible.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Statistiques dérivées uniquement des données réelles chargées.
  CourseStatsData _buildStats(CourseDetailController controller) {
    final int total = controller.seancesTotal;
    final int done = controller.seancesHistorique.length;
    final double? attendance = controller.attendanceRate;
    final int progressionPct = (controller.progression * 100).round();

    return CourseStatsData(
      seancesLabel: total == 0 ? '0' : '$done/$total',
      seancesProgress: controller.progression,
      attendanceLabel: attendance == null
          ? null
          : '${(attendance * 100).round()}%',
      attendanceProgress: attendance ?? 0,
      progressionLabel: total == 0 ? '—' : '$progressionPct%',
      progressionProgress: controller.progression,
    );
  }

  void _goBack(BuildContext context) {
    final NavigatorState navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    // Accès direct sans pile : retour à la liste des cours.
    context.go(AppRoutes.courses);
  }
}

/// En-tête fixe : retour, logo, titre et avatar de l'étudiant.
class _CourseHeader extends StatelessWidget {
  const _CourseHeader({required this.onBack, this.studentInitials});

  final VoidCallback onBack;
  final String? studentInitials;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      color: AppColors.background,
      child: Row(
        children: <Widget>[
          AppIconButton(
            icon: AppIcons.back,
            onPressed: onBack,
            tooltip: 'Retour',
            backgroundColor: AppColors.white,
          ),
          const SizedBox(width: AppSpacing.xs),
          const DakarTechLogo(
            size: 34,
            backgroundColor: AppColors.primarySoft,
            iconColor: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Détails du cours',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.title.copyWith(
                fontSize: 16,
                color: AppColors.dark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          AppAvatar(initials: studentInitials, size: 36),
        ],
      ),
    );
  }
}

/// Zone défilante sous la bannière sticky : stats, onglets, puis le
/// contenu de l'onglet actif — tout défile ensemble dans un seul
/// [CustomScrollView]. Changer d'onglet reconstruit la sélection de
/// slivers affichée (même axe de défilement partagé).
class _ScrollableTabs extends StatelessWidget {
  const _ScrollableTabs({
    required this.controller,
    required this.stats,
    this.onReminder,
    this.onDownload,
    this.onDownloadAll,
  });

  final CourseDetailController controller;
  final CourseStatsData stats;
  final VoidCallback? onReminder;
  final VoidCallback? onDownload;
  final VoidCallback? onDownloadAll;

  @override
  Widget build(BuildContext context) {
    final TabController tabController = DefaultTabController.of(context);
    return ListenableBuilder(
      listenable: tabController,
      builder: (BuildContext context, _) {
        return CustomScrollView(
          slivers: <Widget>[
            SliverToBoxAdapter(child: CourseStatsBento(data: stats)),
            const SliverToBoxAdapter(child: _SegmentTabs()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.xxl,
              ),
              sliver: _contentFor(tabController.index),
            ),
          ],
        );
      },
    );
  }

  Widget _contentFor(int index) {
    return SliverMainAxisGroup(
      slivers: switch (index) {
        1 => _documentsSlivers(),
        2 => _evaluationsSlivers(),
        _ => _seancesSlivers(),
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Onglet Séances
  // ---------------------------------------------------------------------------

  List<Widget> _seancesSlivers() {
    if (controller.seancesLoading) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppLoading(message: 'Chargement des séances…'),
        ),
      ];
    }
    if (controller.seancesError != null) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorState(
            message:
                'Impossible de charger les séances.\n'
                'Vérifiez votre connexion puis réessayez.',
            onRetry: controller.reloadSeances,
          ),
        ),
      ];
    }

    final List<CourseSeance> historique = controller.seancesHistorique;
    final Map<int, int> numbers = controller.seancesNumbers;
    final CourseSeance? prochaine = controller.prochaineSeance;

    final List<Widget> slivers = <Widget>[
      if (prochaine != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: CourseNextSessionCard(
              seance: prochaine,
              onReminder: onReminder,
            ),
          ),
        ),
      SliverToBoxAdapter(
        child: _TabSectionHeader(
          title: 'Historique',
          count: '${historique.length} effectuée(s)',
        ),
      ),
    ];

    if (historique.isEmpty) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: AppIcons.calendarX,
            title: 'Aucune séance',
            message: 'Les séances planifiées de ce cours apparaîtront ici.',
          ),
        ),
      );
    } else {
      slivers.add(
        SliverList.builder(
          itemCount: historique.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: CourseSessionCard(
                number: numbers[historique[index].id] ?? index + 1,
                seance: historique[index],
              ),
            );
          },
        ),
      );
    }
    return slivers;
  }

  // ---------------------------------------------------------------------------
  // Onglet Documents
  // ---------------------------------------------------------------------------

  List<Widget> _documentsSlivers() {
    if (controller.documentsLoading) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppLoading(message: 'Chargement des documents…'),
        ),
      ];
    }
    if (controller.documentsError != null) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorState(
            message:
                'Impossible de charger les documents.\n'
                'Vérifiez votre connexion puis réessayez.',
            onRetry: controller.reloadDocuments,
          ),
        ),
      ];
    }

    final List<CourseDocument> documents = controller.documents;
    final List<Widget> slivers = <Widget>[
      SliverToBoxAdapter(
        child: _TabSectionHeader(
          title: 'Supports de cours',
          count: '${documents.length} fichier(s)',
          trailing: documents.isEmpty
              ? null
              : TextButton(
                  onPressed: onDownloadAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Tout télécharger',
                    style: AppTextStyles.label.copyWith(
                      fontSize: 12,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
        ),
      ),
    ];

    if (documents.isEmpty) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: AppIcons.folderOpen,
            title: 'Aucun document',
            message:
                'Les supports publiés par votre enseignant '
                'apparaîtront ici.',
          ),
        ),
      );
    } else {
      slivers.add(
        SliverList.builder(
          itemCount: documents.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: CourseDocumentCard(
                document: documents[index],
                onDownload: onDownload,
              ),
            );
          },
        ),
      );
    }
    return slivers;
  }

  // ---------------------------------------------------------------------------
  // Onglet Évaluations
  // ---------------------------------------------------------------------------

  List<Widget> _evaluationsSlivers() {
    if (controller.evaluationsLoading) {
      return const <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppLoading(message: 'Chargement des évaluations…'),
        ),
      ];
    }
    if (controller.evaluationsError != null) {
      return <Widget>[
        SliverFillRemaining(
          hasScrollBody: false,
          child: AppErrorState(
            message:
                'Impossible de charger les évaluations.\n'
                'Vérifiez votre connexion puis réessayez.',
            onRetry: controller.reloadEvaluations,
          ),
        ),
      ];
    }

    final List<CourseEvaluation> evaluations = controller.evaluations;
    final double? moyenne = controller.moyenneNotes;
    final List<Widget> slivers = <Widget>[
      if (moyenne != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _MoyenneCard(moyenne: moyenne),
          ),
        ),
      SliverToBoxAdapter(
        child: _TabSectionHeader(
          title: 'Contrôles & examens',
          count: '${evaluations.length}',
        ),
      ),
    ];

    if (evaluations.isEmpty) {
      slivers.add(
        const SliverFillRemaining(
          hasScrollBody: false,
          child: AppEmptyState(
            icon: AppIcons.evaluation,
            title: 'Aucune évaluation',
            message: 'Les contrôles et examens planifiés apparaîtront ici.',
          ),
        ),
      );
    } else {
      slivers.add(
        SliverList.builder(
          itemCount: evaluations.length,
          itemBuilder: (BuildContext context, int index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: CourseEvaluationCard(evaluation: evaluations[index]),
            );
          },
        ),
      );
    }
    return slivers;
  }
}

/// Onglets segmentés (Séances / Documents / Évaluations) avec pilule
/// blanche sur fond gris, pilotés par le [DefaultTabController] — ils
/// défilent avec le contenu (seule la bannière reste épinglée).
class _SegmentTabs extends StatelessWidget {
  const _SegmentTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.graySoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.gray,
        labelStyle: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: AppTextStyles.caption,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        tabs: const <Widget>[
          Tab(text: 'Séances'),
          Tab(text: 'Documents'),
          Tab(text: 'Évaluations'),
        ],
      ),
    );
  }
}

/// En-tête de liste par onglet : titre, pastille compteur, action.
class _TabSectionHeader extends StatelessWidget {
  const _TabSectionHeader({required this.title, this.count, this.trailing});

  final String title;
  final String? count;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Text(
          title,
          style: AppTextStyles.title.copyWith(
            fontSize: 17,
            color: AppColors.dark,
          ),
        ),
        if (count != null) ...[
          const SizedBox(width: AppSpacing.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.graySoft,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              count!,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.gray,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        const Spacer(),
        ?trailing,
      ],
    );
  }
}

/// Bandeau de moyenne, dérivé des notes réellement corrigées.
class _MoyenneCard extends StatelessWidget {
  const _MoyenneCard({required this.moyenne});

  final double moyenne;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: <Widget>[
          const AppIcon(AppIcons.chart, size: 20, color: AppColors.success),
          const SizedBox(width: AppSpacing.sm),
          const Expanded(
            child: Text(
              'Moyenne des notes corrigées',
              style: AppTextStyles.caption,
            ),
          ),
          Text(
            formatNotePour20(moyenne),
            style: AppTextStyles.label.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Affiche un message honnête pour une action pas encore possible côté
/// backend (favori, contact, rappel, téléchargement…).
void _showInfoSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
