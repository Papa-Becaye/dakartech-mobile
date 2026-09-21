import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dakartech_mobile/core/errors/api_exception.dart';
import 'package:dakartech_mobile/core/errors/app_exception.dart';
import 'package:dakartech_mobile/features/courses/data/models/course_detail.dart';
import 'package:dakartech_mobile/features/courses/data/models/course_model.dart';
import 'package:dakartech_mobile/features/courses/data/repositories/courses_repository.dart';
import 'package:dakartech_mobile/features/courses/presentation/screens/course_detail_screen.dart';

// ---------------------------------------------------------------------------
// Fixtures (dates relatives au jour du test pour un historique déterministe)
// ---------------------------------------------------------------------------

final DateTime _now = DateTime.now();

CourseSeance _seancePassee({
  required int id,
  required String chapitre,
  required int daysAgo,
  CoursePresence? presence,
}) {
  return CourseSeance(
    id: id,
    date: _now.subtract(Duration(days: daysAgo)),
    duree: 2,
    chapitre: chapitre,
    presence: presence,
  );
}

CourseDetail _fullDetail() => CourseDetail(
      id: 7,
      titre: 'Algorithmique avancée',
      volumeHoraire: 36,
      matiere: const CourseMatiere(
        id: 1,
        nom: 'Base de données',
        code: 'BD301',
        coefficient: 2.5,
      ),
      enseignant: const CourseEnseignant(id: 3, nom: 'Diop', prenom: 'Awa'),
      classe: const CourseClasse(
        id: 4,
        nom: 'L3 GL',
        filiere: CourseFiliere(id: 2, nom: 'Génie Logiciel'),
        annee: CourseAnnee(id: 1, libelle: '2025-2026', active: true),
      ),
      prochaineSeance: CourseSeance(
        id: 9,
        date: _now.add(const Duration(days: 4)),
        duree: 3,
        chapitre: 'Les tris',
      ),
    );

List<CourseSeance> _sessions() => <CourseSeance>[
      _seancePassee(
        id: 8,
        chapitre: 'Fusion',
        daysAgo: 7,
        presence: const CoursePresence(present: true),
      ),
      _seancePassee(
        id: 7,
        chapitre: 'Récursivité',
        daysAgo: 14,
        presence: const CoursePresence(present: false, remarque: 'Absent'),
      ),
      CourseSeance(
        id: 9,
        date: _now.add(const Duration(days: 4)),
        duree: 3,
        chapitre: 'Les tris',
      ),
    ];

List<CourseDocument> _documents() => <CourseDocument>[
      CourseDocument(
        id: 1,
        nom: 'CM1 - Introduction.pdf',
        type: 'PDF',
        createdAt: _now.subtract(const Duration(days: 10)),
      ),
    ];

List<CourseEvaluation> _evaluations() => <CourseEvaluation>[
      CourseEvaluation(
        id: 11,
        titre: 'Devoir sur table',
        date: _now.subtract(const Duration(days: 30)),
        type: CourseEvaluationType.devoir,
        note: 15,
      ),
      CourseEvaluation(
        id: 12,
        titre: 'Examen final',
        date: _now.add(const Duration(days: 25)),
        type: CourseEvaluationType.examen,
      ),
    ];

// ---------------------------------------------------------------------------
// Repositories de test
// ---------------------------------------------------------------------------

class _PendingRepository implements CoursesRepository {
  final Completer<CourseDetail> completer = Completer<CourseDetail>();

  @override
  Future<List<Course>> getMyCourses() async => const [];

  @override
  Future<CourseDetail> getCourseById(int id) => completer.future;

  @override
  Future<List<CourseSeance>> getCourseSeances(int id) async => const [];

  @override
  Future<List<CourseDocument>> getCourseDocuments(int id) async =>
      const [];

  @override
  Future<List<CourseEvaluation>> getCourseEvaluations(int id) async =>
      const [];
}

/// Données complètes (détail + les trois onglets).
class _FullRepository implements CoursesRepository {
  _FullRepository({
    required this.detail,
    this.seances = const [],
    this.documents = const [],
    this.evaluations = const [],
  });

  final CourseDetail detail;
  final List<CourseSeance> seances;
  final List<CourseDocument> documents;
  final List<CourseEvaluation> evaluations;

  @override
  Future<List<Course>> getMyCourses() async => const [];

  @override
  Future<CourseDetail> getCourseById(int id) async => detail;

  @override
  Future<List<CourseSeance>> getCourseSeances(int id) async => seances;

  @override
  Future<List<CourseDocument>> getCourseDocuments(int id) async =>
      documents;

  @override
  Future<List<CourseEvaluation>> getCourseEvaluations(int id) async =>
      evaluations;
}

/// Échoue au premier appel du détail puis réussit (bouton Réessayer).
class _ThenSucceedRepository implements CoursesRepository {
  _ThenSucceedRepository(this.detail);

  final CourseDetail detail;
  int calls = 0;

  @override
  Future<List<Course>> getMyCourses() async => const [];

  @override
  Future<CourseDetail> getCourseById(int id) async {
    calls++;
    if (calls == 1) {
      throw const AppException('Connexion impossible.');
    }
    return detail;
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

class _NotFoundRepository implements CoursesRepository {
  @override
  Future<List<Course>> getMyCourses() async => const [];

  @override
  Future<CourseDetail> getCourseById(int id) async {
    throw const ApiException('Cours introuvable', statusCode: 404);
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

/// Le détail réussit, mais l'onglet séances échoue une fois puis réussit.
class _SessionsThenSucceedRepository implements CoursesRepository {
  _SessionsThenSucceedRepository(this.detail);

  final CourseDetail detail;
  int seanceCalls = 0;

  @override
  Future<List<Course>> getMyCourses() async => const [];

  @override
  Future<CourseDetail> getCourseById(int id) async => detail;

  @override
  Future<List<CourseSeance>> getCourseSeances(int id) async {
    seanceCalls++;
    if (seanceCalls == 1) {
      throw const AppException('Connexion impossible.');
    }
    return _sessions();
  }

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

void _setSurface(
  WidgetTester tester, {
  double width = 800,
  double height = 2000,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _screen(CoursesRepository repository, {int courseId = 7}) {
  return MaterialApp(
    home: CourseDetailScreen(courseId: courseId, repository: repository),
  );
}

void main() {
  group('CourseDetailScreen - états', () {
    testWidgets('chargement → spinner puis contenu', (tester) async {
      _setSurface(tester);
      final _PendingRepository repo = _PendingRepository();

      await tester.pumpWidget(_screen(repo));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Chargement du cours…'), findsOneWidget);

      repo.completer.complete(_fullDetail());
      await tester.pumpAndSettle();

      expect(find.text('Algorithmique avancée'), findsOneWidget);
      expect(find.text('Chargement du cours…'), findsNothing);
    });

    testWidgets('erreur réseau → message + Réessayer relance l\'API',
        (tester) async {
      _setSurface(tester);
      final _ThenSucceedRepository repo = _ThenSucceedRepository(_fullDetail());

      await tester.pumpWidget(_screen(repo));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Impossible de charger les informations du cours.\n'
          'Vérifiez votre connexion puis réessayez.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(repo.calls, 2);
      expect(find.text('Algorithmique avancée'), findsOneWidget);
    });

    testWidgets('404 → état « Cours introuvable »', (tester) async {
      _setSurface(tester);

      await tester.pumpWidget(_screen(_NotFoundRepository()));
      await tester.pumpAndSettle();

      expect(find.text('Cours introuvable'), findsOneWidget);
      expect(find.text('Retour à la liste'), findsOneWidget);
      expect(find.text('Réessayer'), findsNothing);
    });
  });

  group('CourseDetailScreen - bannière et statistiques', () {
    testWidgets('affiche bannière, rattachement et stats dérivées',
        (tester) async {
      _setSurface(tester);

      await tester.pumpWidget(
        _screen(
          _FullRepository(
            detail: _fullDetail(),
            seances: _sessions(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Bannière : titre, code, rattachement académique, enseignant.
      expect(find.text('Algorithmique avancée'), findsOneWidget);
      expect(find.text('BD301'), findsOneWidget);
      expect(find.text('L3 GL • Génie Logiciel • 2025-2026'), findsOneWidget);
      expect(find.text('Awa Diop'), findsOneWidget);
      expect(find.text('Enseignant référent'), findsOneWidget);

      // Stats dérivées des données réelles (2 séances passées / 3 au
      // total, 1 présence sur 2, progression 2/3).
      expect(find.text('2/3'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
      expect(find.text('67%'), findsOneWidget);
    });

    testWidgets('masque les sections sans données', (tester) async {
      _setSurface(tester);

      await tester.pumpWidget(
        _screen(
          _FullRepository(
            detail: const CourseDetail(id: 7, titre: 'Cours sans détails'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cours sans détails'), findsOneWidget);
      // Pas d'enseignant ni de rattachement → bannière minimaliste.
      expect(find.text('Enseignant référent'), findsNothing);

      // Stats à zéro (valeur honnête, pas de données inventées).
      expect(find.text('0'), findsOneWidget);
      expect(find.text('—'), findsNWidgets(2));

      // Onglets vides, chacun avec son état dédié.
      expect(find.text('Historique'), findsOneWidget);
      expect(find.text('0 effectuée(s)'), findsOneWidget);
      expect(find.text('Aucune séance'), findsOneWidget);

      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();
      expect(find.text('Supports de cours'), findsOneWidget);
      expect(find.text('Aucun document'), findsOneWidget);

      await tester.tap(find.text('Évaluations'));
      await tester.pumpAndSettle();
      expect(find.text('Contrôles & examens'), findsOneWidget);
      expect(find.text('Aucune évaluation'), findsOneWidget);
    });
  });

  group('CourseDetailScreen - onglets', () {
    testWidgets('séances : prochaine + historique + badges de présence',
        (tester) async {
      _setSurface(tester);

      await tester.pumpWidget(
        _screen(
          _FullRepository(
            detail: _fullDetail(),
            seances: _sessions(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Teaser de la prochaine séance.
      expect(find.text('Prochaine séance'), findsOneWidget);
      expect(find.text('Les tris'), findsOneWidget);

      // Historique : séances passées avec présence réellement émargée.
      expect(find.text('Historique'), findsOneWidget);
      expect(find.text('2 effectuée(s)'), findsOneWidget);
      expect(find.text('Fusion'), findsOneWidget);
      expect(find.text('Récursivité'), findsOneWidget);
      expect(find.text('Présent'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);

      // La future séance n'apparaît que dans le teaser (« Les tris »).
      expect(find.byType(CourseDetailScreen), findsOneWidget);
    });

    testWidgets('documents : liste des supports déposés', (tester) async {
      _setSurface(tester);

      await tester.pumpWidget(
        _screen(
          _FullRepository(
            detail: _fullDetail(),
            documents: _documents(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Documents'));
      await tester.pumpAndSettle();

      expect(find.text('Supports de cours'), findsOneWidget);
      expect(find.text('1 fichier(s)'), findsOneWidget);
      expect(find.text('CM1 - Introduction.pdf'), findsOneWidget);
      expect(find.text('Tout télécharger'), findsOneWidget);
    });

    testWidgets('évaluations : note réelle, mention et statut dérivé',
        (tester) async {
      _setSurface(tester);

      await tester.pumpWidget(
        _screen(
          _FullRepository(
            detail: _fullDetail(),
            evaluations: _evaluations(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Évaluations'));
      await tester.pumpAndSettle();

      expect(find.text('Contrôles & examens'), findsOneWidget);
      expect(find.text('Devoir sur table'), findsOneWidget);

      // Moyenne dérivée des notes corrigées (1 note : 15).
      expect(find.text('Moyenne des notes corrigées'), findsOneWidget);
      expect(find.text('15 /20'), findsWidgets);

      // Statuts dérivés des données (note présente / évaluation future).
      expect(find.text('Notée'), findsOneWidget);
      expect(find.text('Prévu'), findsOneWidget);
      expect(find.text('Examen final'), findsOneWidget);
    });
  });

  group('CourseDetailScreen - erreur d\'onglet', () {
    testWidgets('séances en erreur → message + Réessayer propre à l\'onglet',
        (tester) async {
      _setSurface(tester);
      final _SessionsThenSucceedRepository repo =
          _SessionsThenSucceedRepository(_fullDetail());

      await tester.pumpWidget(_screen(repo));
      await tester.pumpAndSettle();

      expect(find.text('Algorithmique avancée'), findsOneWidget);

      // L'échec de l'onglet n'affecte pas la bannière.
      expect(
        find.text(
          'Impossible de charger les séances.\n'
          'Vérifiez votre connexion puis réessayez.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(repo.seanceCalls, 2);
      expect(find.text('Fusion'), findsOneWidget);
      expect(
        find.text(
          'Impossible de charger les séances.\n'
          'Vérifiez votre connexion puis réessayez.',
        ),
        findsNothing,
      );
    });
  });
}