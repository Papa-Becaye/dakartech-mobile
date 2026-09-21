import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:dakartech_mobile/core/errors/app_exception.dart';
import 'package:dakartech_mobile/features/courses/data/models/course_detail.dart';
import 'package:dakartech_mobile/features/courses/data/models/course_model.dart';
import 'package:dakartech_mobile/features/courses/data/repositories/courses_repository.dart';
import 'package:dakartech_mobile/features/courses/presentation/screens/course_detail_screen.dart';
import 'package:dakartech_mobile/features/courses/presentation/screens/courses_screen.dart';
import 'package:dakartech_mobile/features/courses/presentation/widgets/course_card.dart';

// ---------------------------------------------------------------------------
// Fixtures (données modélisées, jamais de mapping vers l'UI ici)
// ---------------------------------------------------------------------------

Course _course(
  int id, {
  required String titre,
  int volumeHoraire = 0,
  CourseMatiere? matiere,
  CourseEnseignant? enseignant,
}) {
  return Course(
    id: id,
    titre: titre,
    volumeHoraire: volumeHoraire,
    matiere: matiere,
    enseignant: enseignant,
  );
}

List<Course> _twoCourses() => [
      _course(
        1,
        titre: 'Bases de données',
        volumeHoraire: 36,
        matiere: const CourseMatiere(
          id: 1,
          nom: 'Base de données',
          code: 'BD301',
          coefficient: 3,
        ),
        enseignant: const CourseEnseignant(id: 1, nom: 'Diop', prenom: 'Awa'),
      ),
      _course(
        2,
        titre: 'Réseaux & Télécoms',
        volumeHoraire: 30,
        matiere: const CourseMatiere(
          id: 2,
          nom: 'Réseaux & Télécoms',
          code: 'RT302',
          coefficient: 2,
        ),
        // Sans prénom : le nom seul doit rester affiché.
        enseignant: const CourseEnseignant(id: 2, nom: 'Fall'),
      ),
    ];

/// Détail factice minimal pour les repositories de test.
CourseDetail _courseDetail(int id) => CourseDetail(
      id: id,
      titre: 'Détail du cours #$id',
      volumeHoraire: 36,
      matiere: const CourseMatiere(
        id: 1,
        nom: 'Base de données',
        code: 'BD301',
        coefficient: 3,
      ),
      enseignant: const CourseEnseignant(id: 1, nom: 'Diop', prenom: 'Awa'),
    );

// ---------------------------------------------------------------------------
// Repositories de test
// ---------------------------------------------------------------------------

/// Reste en cours tant que le test ne complète pas le [Completer].
class _PendingRepository implements CoursesRepository {
  final Completer<List<Course>> completer = Completer<List<Course>>();

  @override
  Future<List<Course>> getMyCourses() => completer.future;

  @override
  Future<CourseDetail> getCourseById(int id) async => _courseDetail(id);

  @override
  Future<List<CourseSeance>> getCourseSeances(int id) async => const [];

  @override
  Future<List<CourseDocument>> getCourseDocuments(int id) async =>
      const [];

  @override
  Future<List<CourseEvaluation>> getCourseEvaluations(int id) async =>
      const [];
}

/// Compte les appels (vérifie chargement, réessayer et pull-to-refresh).
class _CountingRepository implements CoursesRepository {
  _CountingRepository(this.data);

  final List<Course> data;
  int calls = 0;

  /// Dernier identifiant transmis à [getCourseById] (navigation détail).
  int? lastDetailId;

  @override
  Future<List<Course>> getMyCourses() async {
    calls++;
    return data;
  }

  @override
  Future<CourseDetail> getCourseById(int id) async {
    lastDetailId = id;
    return _courseDetail(id);
  }

  @override
  Future<List<CourseSeance>> getCourseSeances(int id) async => const [];

  @override
  Future<List<CourseDocument>> getCourseDocuments(int id) async =>
      const [];

  @override
  Future<List<CourseEvaluation>> getCourseEvaluations(int id) async =>
      const [];
}

/// Renvoie la liste vide de l'API (état réel : aucun cours).
class _ThenSucceedRepository implements CoursesRepository {
  bool _failed = false;

  @override
  Future<List<Course>> getMyCourses() async {
    if (!_failed) {
      _failed = true;
      throw const AppException('Connexion impossible.');
    }
    return _twoCourses();
  }

  @override
  Future<CourseDetail> getCourseById(int id) async => _courseDetail(id);

  @override
  Future<List<CourseSeance>> getCourseSeances(int id) async => const [];

  @override
  Future<List<CourseDocument>> getCourseDocuments(int id) async =>
      const [];

  @override
  Future<List<CourseEvaluation>> getCourseEvaluations(int id) async =>
      const [];
}

/// Toujours en erreur.
class _AlwaysFailRepository implements CoursesRepository {
  @override
  Future<List<Course>> getMyCourses() async {
    throw const AppException('Connexion impossible.');
  }

  @override
  Future<CourseDetail> getCourseById(int id) async {
    throw const AppException('Connexion impossible.');
  }

  @override
  Future<List<CourseSeance>> getCourseSeances(int id) async => const [];

  @override
  Future<List<CourseDocument>> getCourseDocuments(int id) async =>
      const [];

  @override
  Future<List<CourseEvaluation>> getCourseEvaluations(int id) async =>
      const [];
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Agrandit l'écran pour rendre toute la liste (pas de lazy build).
void _setSurface(
  WidgetTester tester, {
  double width = 800,
  double height = 2000,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Texte recherché UNIQUEMENT dans une carte de cours (les mêmes libellés
/// peuvent aussi apparaître dans les puces de filtres de l'interface).
Finder _cardText(String text) => find.descendant(
      of: find.byType(CourseCard),
      matching: find.text(text),
    );

/// Application complète avec le routeur nécessaire à la navigation
/// vers le détail du cours (`/course/:id`).
Widget _buildAppWithRoutes(CoursesRepository repository) {
  final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            Scaffold(body: CoursesScreen(repository: repository)),
      ),
      GoRoute(
        path: '/course/:id',
        builder: (context, state) => CourseDetailScreen(
          courseId: int.parse(state.pathParameters['id']!),
          repository: repository,
        ),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

const String _errorMessage =
    'Impossible de charger vos cours.\n'
    'Vérifiez votre connexion puis réessayez.';

const String _emptyMessage =
    'Aucun cours n\'est actuellement associé à votre profil étudiant.';

void main() {
  group('CoursesScreen - données', () {
    testWidgets('chargement initial → spinner', (tester) async {
      final _PendingRepository repo = _PendingRepository();

      await tester.pumpWidget(_wrap(CoursesScreen(repository: repo)));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Chargement de vos cours…'), findsOneWidget);

      // Fin du chargement : la liste apparaît.
      repo.completer.complete(_twoCourses());
      await tester.pumpAndSettle();
      expect(find.text('Bases de données'), findsOneWidget);
    });

    testWidgets('données réelles → une carte par cours', (tester) async {
      _setSurface(tester);
      final _CountingRepository repo = _CountingRepository(_twoCourses());

      await tester.pumpWidget(_wrap(CoursesScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(repo.calls, 1);
      expect(find.byType(CourseCard), findsNWidgets(2));

      // Contenu : unique titre, code matière, enseignant, volume horaire.
      expect(_cardText('Bases de données'), findsOneWidget);
      expect(find.text('BD301'), findsOneWidget);
      expect(_cardText('Awa Diop'), findsOneWidget);
      expect(find.text('36 h'), findsOneWidget);

      // Deuxième cours : code et enseignant sans prénom.
      expect(_cardText('Réseaux & Télécoms'), findsOneWidget);
      expect(find.text('RT302'), findsOneWidget);
      expect(_cardText('Fall'), findsOneWidget);
      expect(find.text('30 h'), findsOneWidget);
    });

    testWidgets('liste vide → état vide + bouton Actualiser', (tester) async {
      final _CountingRepository repo = _CountingRepository(const []);

      await tester.pumpWidget(_wrap(CoursesScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.text('Aucun cours disponible'), findsOneWidget);
      expect(find.text(_emptyMessage), findsOneWidget);
      expect(find.text('Actualiser'), findsOneWidget);
      expect(repo.calls, 1);

      // Relance réelle de l'API (re-fetch), pas d'affichage statique.
      await tester.tap(find.text('Actualiser'));
      await tester.pumpAndSettle();
      expect(repo.calls, 2);
    });
  });

  group('CoursesScreen - erreur', () {
    testWidgets('erreur initiale → message + Réessayer', (tester) async {
      await tester.pumpWidget(
        _wrap(CoursesScreen(repository: _AlwaysFailRepository())),
      );
      await tester.pumpAndSettle();

      expect(find.text(_errorMessage), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);
      // Le message technique ne doit pas apparaître.
      expect(find.text('Connexion impossible.'), findsNothing);
    });

    testWidgets('Réessayer après erreur → liste affichée', (tester) async {
      _setSurface(tester);
      final _ThenSucceedRepository repo = _ThenSucceedRepository();

      await tester.pumpWidget(_wrap(CoursesScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.text(_errorMessage), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(_cardText('Bases de données'), findsOneWidget);
      expect(find.byType(CourseCard), findsNWidgets(2));
    });
  });

  group('CoursesScreen - rafraîchissement', () {
    testWidgets('pull-to-refresh → nouvel appel API', (tester) async {
      final _CountingRepository repo = _CountingRepository(_twoCourses());

      await tester.pumpWidget(_wrap(CoursesScreen(repository: repo)));
      await tester.pumpAndSettle();
      expect(repo.calls, 1);

      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(repo.calls, 2);
      expect(find.text('Bases de données'), findsOneWidget);
    });

    testWidgets('échec du refresh → snackbar, la liste reste', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CoursesScreen(
            repository: _RefreshFailsRepository(success: _twoCourses()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bases de données'), findsOneWidget);

      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible d\'actualiser vos cours.'),
        findsOneWidget,
      );
      // Les cours restent affichés après l'échec.
      expect(find.text('Bases de données'), findsOneWidget);
    });
  });

  group('CoursesScreen - navigation', () {
    testWidgets('appui sur une carte → détail chargé avec le bon id',
        (tester) async {
      _setSurface(tester);
      final _CountingRepository repo = _CountingRepository(_twoCourses());

      await tester.pumpWidget(_buildAppWithRoutes(repo));
      await tester.pumpAndSettle();

      await tester.tap(_cardText('Réseaux & Télécoms'));
      await tester.pumpAndSettle();

      // L'id réel de la carte (2) est transmis à l'API de détail.
      expect(repo.lastDetailId, 2);
      expect(find.text('Détail du cours #2'), findsOneWidget);
      expect(find.text('Awa Diop'), findsOneWidget);
    });
  });

  group('CoursesScreen - recherche et filtres', () {
    testWidgets('recherche insensible à la casse et aux espaces superflus',
        (tester) async {
      _setSurface(tester);

      await tester.pumpWidget(
        _wrap(CoursesScreen(repository: _CountingRepository(_twoCourses()))),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CourseCard), findsNWidgets(2));

      // Titre : casse et espaces inutiles tolérés.
      await tester.enterText(find.byType(TextField), '  bases   ');
      await tester.pumpAndSettle();
      expect(find.byType(CourseCard), findsOneWidget);
      expect(_cardText('Bases de données'), findsOneWidget);

      // Enseignant (nom seul).
      await tester.enterText(find.byType(TextField), 'fall');
      await tester.pumpAndSettle();
      expect(find.byType(CourseCard), findsOneWidget);
      expect(_cardText('Réseaux & Télécoms'), findsOneWidget);

      // Prénom + nom de l'enseignant.
      await tester.enterText(find.byType(TextField), 'awa diop');
      await tester.pumpAndSettle();
      expect(find.byType(CourseCard), findsOneWidget);
      expect(_cardText('Bases de données'), findsOneWidget);

      // Code de la matière.
      await tester.enterText(find.byType(TextField), 'rt3');
      await tester.pumpAndSettle();
      expect(find.byType(CourseCard), findsOneWidget);
      expect(_cardText('Réseaux & Télécoms'), findsOneWidget);
    });

    testWidgets('recherche vide → la liste complète réapparaît',
        (tester) async {
      _setSurface(tester);

      await tester.pumpWidget(
        _wrap(CoursesScreen(repository: _CountingRepository(_twoCourses()))),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'bases');
      await tester.pumpAndSettle();
      expect(find.byType(CourseCard), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      expect(find.byType(CourseCard), findsNWidgets(2));
    });

    testWidgets('bouton d\'effacement de la recherche → liste complète',
        (tester) async {
      _setSurface(tester);

      await tester.pumpWidget(
        _wrap(CoursesScreen(repository: _CountingRepository(_twoCourses()))),
      );
      await tester.pumpAndSettle();

      // Sans texte saisi, pas de bouton d'effacement.
      expect(find.byTooltip('Effacer la recherche'), findsNothing);

      await tester.enterText(find.byType(TextField), 'bases');
      await tester.pumpAndSettle();
      expect(find.byType(CourseCard), findsOneWidget);

      await tester.tap(find.byTooltip('Effacer la recherche'));
      await tester.pumpAndSettle();
      expect(find.byType(CourseCard), findsNWidgets(2));

      // Le champ est bien vidé.
      final TextField field =
          tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, isEmpty);
    });

    testWidgets('filtre par matière, combinaison avec la recherche',
        (tester) async {
      _setSurface(tester);

      await tester.pumpWidget(
        _wrap(CoursesScreen(repository: _CountingRepository(_twoCourses()))),
      );
      await tester.pumpAndSettle();

      // Filtre matière « Base de données ».
      await tester.tap(find.widgetWithText(FilterChip, 'Base de données'));
      await tester.pumpAndSettle();
      expect(find.byType(CourseCard), findsOneWidget);
      expect(_cardText('Bases de données'), findsOneWidget);

      // Recherche + filtre : « diop » garde bien le cours de la matière.
      await tester.enterText(find.byType(TextField), 'diop');
      await tester.pumpAndSettle();
      expect(find.byType(CourseCard), findsOneWidget);

      // Recherche + filtre : « fall » ne correspond plus à rien.
      await tester.enterText(find.byType(TextField), 'fall');
      await tester.pumpAndSettle();
      expect(find.byType(CourseCard), findsNothing);
      expect(find.text('Aucun cours trouvé'), findsOneWidget);
    });

    testWidgets('filtre par enseignant et désélection', (tester) async {
      _setSurface(tester);

      await tester.pumpWidget(
        _wrap(CoursesScreen(repository: _CountingRepository(_twoCourses()))),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Fall'));
      await tester.pumpAndSettle();
      expect(find.byType(CourseCard), findsOneWidget);
      expect(_cardText('Réseaux & Télécoms'), findsOneWidget);

      // Second appui sur le même filtre → désélection, liste complète.
      await tester.tap(find.widgetWithText(FilterChip, 'Fall'));
      await tester.pumpAndSettle();
      expect(find.byType(CourseCard), findsNWidgets(2));
    });

    testWidgets('aucun résultat → « Effacer les filtres » restaure la liste',
        (tester) async {
      _setSurface(tester);

      await tester.pumpWidget(
        _wrap(CoursesScreen(repository: _CountingRepository(_twoCourses()))),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'informatique quantique');
      await tester.pumpAndSettle();
      expect(find.text('Aucun cours trouvé'), findsOneWidget);
      expect(find.byType(CourseCard), findsNothing);

      await tester.tap(find.text('Effacer les filtres'));
      await tester.pumpAndSettle();
      expect(find.text('Aucun cours trouvé'), findsNothing);
      expect(find.byType(CourseCard), findsNWidgets(2));

      // Le champ de recherche est bien réinitialisé.
      final TextField field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, isEmpty);
    });

    testWidgets('filtres conservés après pull-to-refresh (données API intactes)',
        (tester) async {
      _setSurface(tester);
      final _CountingRepository repo = _CountingRepository(_twoCourses());

      await tester.pumpWidget(_wrap(CoursesScreen(repository: repo)));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilterChip, 'Base de données'));
      await tester.pumpAndSettle();
      expect(find.byType(CourseCard), findsOneWidget);

      await tester.fling(
        find.byType(ListView),
        const Offset(0, 600),
        1200,
      );
      await tester.pumpAndSettle();

      // L'API est re-contactée, la liste source intacte, le filtre actif.
      expect(repo.calls, 2);
      expect(find.byType(CourseCard), findsOneWidget);
      expect(_cardText('Bases de données'), findsOneWidget);
    });
  });
}

/// Échoue uniquement lors du deuxième appel (simulation de refresh raté).
class _RefreshFailsRepository implements CoursesRepository {
  _RefreshFailsRepository({required this.success});

  final List<Course> success;
  int _calls = 0;

  @override
  Future<List<Course>> getMyCourses() async {
    _calls++;
    if (_calls >= 2) {
      throw const AppException('Connexion impossible.');
    }
    return success;
  }

  @override
  Future<CourseDetail> getCourseById(int id) async => _courseDetail(id);

  @override
  Future<List<CourseSeance>> getCourseSeances(int id) async => const [];

  @override
  Future<List<CourseDocument>> getCourseDocuments(int id) async =>
      const [];

  @override
  Future<List<CourseEvaluation>> getCourseEvaluations(int id) async =>
      const [];
}