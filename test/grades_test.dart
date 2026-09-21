import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dakartech_mobile/core/errors/api_exception.dart';
import 'package:dakartech_mobile/core/network/api_client.dart';
import 'package:dakartech_mobile/core/routes/app_router.dart';
import 'package:dakartech_mobile/core/theme/app_theme.dart';
import 'package:dakartech_mobile/features/courses/data/models/course_detail.dart';
import 'package:dakartech_mobile/features/grades/controllers/grades_controller.dart';
import 'package:dakartech_mobile/features/grades/data/grades_repository.dart';
import 'package:dakartech_mobile/features/grades/models/grades_releve.dart';
import 'package:dakartech_mobile/features/grades/presentation/screens/grades_matiere_screen.dart';
import 'package:dakartech_mobile/features/grades/presentation/screens/grades_screen.dart';
import 'package:dakartech_mobile/features/auth/controllers/auth_controller.dart';
import 'package:dakartech_mobile/features/auth/data/auth_repository.dart';
import 'package:dakartech_mobile/features/auth/data/auth_service.dart';
import 'package:dakartech_mobile/features/auth/data/token_storage.dart';
import 'package:dakartech_mobile/main.dart';

// ---------------------------------------------------------------------------
// Fixtures : formes réelles de `GET /notes/mes-notes`
// ---------------------------------------------------------------------------

const GradesEtudiant _etudiant = GradesEtudiant(
  id: 5,
  matricule: 'IG1-0005',
  prenom: 'Jean',
  nom: 'Dupont',
  classe: GradesClasse(
    id: 10,
    nom: 'Informatique & Génie logiciel 1ère année',
    annee: GradesAnnee(id: 1, libelle: '2025-2026'),
  ),
);

/// Relevé avec une matière non notée : moyenne générale pondérée 13,7.
GradesReleve _releveAvecDonnees() {
  return GradesReleve(
    etudiant: _etudiant,
    moyenneGenerale: 13.7,
    mention: 'Assez bien',
    matieres: [
      GradesMatiere(
        matiereId: 1,
        matiere: 'Algorithmique et Programmation',
        code: 'ALGO101',
        coefficient: 4,
        moyenne: 15,
        evaluationsNotees: 2,
        evaluations: [
          GradesEvaluation(
            id: 11,
            titre: 'Devoir 1',
            date: DateTime.now().subtract(const Duration(days: 10)),
            type: CourseEvaluationType.devoir,
            coursId: 1,
            cours: 'Algorithmique et Programmation I',
            note: 14,
          ),
          GradesEvaluation(
            id: 12,
            titre: 'Examen final',
            date: DateTime.now().subtract(const Duration(days: 5)),
            type: CourseEvaluationType.examen,
            coursId: 1,
            cours: 'Algorithmique et Programmation I',
            note: 16,
          ),
        ],
      ),
      GradesMatiere(
        matiereId: 2,
        matiere: 'Mathématiques',
        code: 'MATH201',
        coefficient: 3,
        moyenne: 12,
        evaluationsNotees: 1,
        evaluations: [
          GradesEvaluation(
            id: 21,
            titre: 'Devoir 1',
            date: DateTime.now().subtract(const Duration(days: 8)),
            type: CourseEvaluationType.devoir,
            coursId: 2,
            cours: 'Mathématiques I',
            note: 12,
          ),
        ],
      ),
      GradesMatiere(
        matiereId: 3,
        matiere: 'Bases de données',
        code: 'BDD201',
        coefficient: 2,
        moyenne: null,
        evaluationsNotees: 0,
        evaluations: [
          GradesEvaluation(
            id: 31,
            titre: 'Devoir 1',
            date: DateTime.now().subtract(const Duration(days: 4)),
            type: CourseEvaluationType.devoir,
            coursId: 3,
            cours: 'Bases de données I',
            note: null,
          ),
        ],
      ),
    ],
  );
}

GradesReleve _releveVide() {
  return GradesReleve(
    etudiant: _etudiant,
    moyenneGenerale: null,
    mention: null,
    matieres: const [],
  );
}

/// Matière riche pour la fiche détaillée : 4 évaluations différents types
/// (dont une à venir, non corrigée).
GradesMatiere _matiereRiche() {
  return GradesMatiere(
    matiereId: 1,
    matiere: 'Algorithmique et Programmation',
    code: 'ALGO101',
    coefficient: 4,
    moyenne: 15.7,
    evaluationsNotees: 3,
    evaluations: [
      GradesEvaluation(
        id: 11,
        titre: 'Devoir 1',
        date: DateTime.now().subtract(const Duration(days: 10)),
        type: CourseEvaluationType.devoir,
        coursId: 1,
        cours: 'Algorithmique et Programmation I',
        note: 14,
      ),
      GradesEvaluation(
        id: 12,
        titre: 'Examen final',
        date: DateTime.now().subtract(const Duration(days: 5)),
        type: CourseEvaluationType.examen,
        coursId: 1,
        cours: 'Algorithmique et Programmation I',
        note: 16,
      ),
      GradesEvaluation(
        id: 13,
        titre: 'Mini-projet livret',
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: CourseEvaluationType.projet,
        coursId: 1,
        cours: 'Algorithmique et Programmation I',
        note: 17,
      ),
      GradesEvaluation(
        id: 14,
        titre: 'Test blanc',
        date: DateTime.now().add(const Duration(days: 20)),
        type: CourseEvaluationType.devoir,
        coursId: 1,
        cours: 'Algorithmique et Programmation I',
        note: null,
      ),
    ],
  );
}

enum _ReleveVariant {
  /// Relevé complet (avec une matière non notée).
  data,

  /// Aucune matière (état vide).
  empty,

  /// L'API échoue à chaque appel.
  alwaysFail,

  /// Échoue au premier appel, puis renvoie des données.
  thenSucceed,
}

/// Repository de substitution (formes réelles, aucune donnée métier
/// inventée au-delà de la fixture).
class _FakeGradesRepository implements GradesRepository {
  _FakeGradesRepository({this.variant = _ReleveVariant.data});

  final _ReleveVariant variant;
  int fetchCalls = 0;

  @override
  Future<GradesReleve> fetchMonReleve() async {
    fetchCalls++;
    if (variant == _ReleveVariant.alwaysFail) {
      throw const ApiException('Connexion impossible.');
    }
    if (variant == _ReleveVariant.thenSucceed && fetchCalls == 1) {
      throw const ApiException('Connexion impossible.');
    }
    return switch (variant) {
      _ReleveVariant.data => _releveAvecDonnees(),
      _ReleveVariant.empty => _releveVide(),
      _ => _releveAvecDonnees(),
    };
  }
}

// ---------------------------------------------------------------------------
// Application complète (router + shell) : adapter Dio simulé
// ---------------------------------------------------------------------------

/// Adapter simulé : le dashboard consomme les cours (comme dans les tests
/// planning), l'onglet Notes consomme `/notes/mes-notes`.
class _FakeDioAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/notes/mes-notes')) {
      return _json(_mesNotesJson());
    }
    if (options.path.endsWith('/cours/mes-cours')) {
      return _json([
        {
          'id': 1,
          'titre': 'Algorithmique et Programmation I',
          'volumeHoraire': 42,
          'matiere': {
            'id': 1,
            'nom': 'Algorithmique et Programmation',
            'code': 'ALGO101',
            'coefficient': 4,
          },
          'enseignant': {'id': 1, 'nom': 'Diop', 'prenom': 'Mamadou'},
        },
      ]);
    }
    if (options.path.endsWith('/cours/1/evaluations')) {
      return _json(<Object>[]);
    }
    if (options.path.endsWith('/cours/1/seances')) {
      return _json(<Object>[]);
    }
    if (options.path.endsWith('/cours/1')) {
      return _json({
        'id': 1,
        'titre': 'Algorithmique et Programmation I',
        'volumeHoraire': 42,
        'matiere': {
          'id': 1,
          'nom': 'Algorithmique et Programmation',
          'code': 'ALGO101',
          'coefficient': 4,
        },
        'enseignant': {'id': 1, 'nom': 'Diop', 'prenom': 'Mamadou'},
        'classe': {
          'id': 1,
          'nom': 'IG1',
          'filiere': {'id': 1, 'nom': 'Informatique de Gestion'},
          'annee': {'id': 1, 'libelle': '2025-2026', 'active': true},
        },
        'prochaineSeance': null,
      });
    }
    return _json(_profilJson());
  }

  /// Réponse réelle de `GET /notes/mes-notes`.
  Map<String, Object> _mesNotesJson() {
    return {
      'etudiant': {
        'id': 5,
        'matricule': 'IG1-0005',
        'prenom': 'Jean',
        'nom': 'Dupont',
        'classe': {
          'id': 10,
          'nom': 'Informatique & Génie logiciel 1ère année',
          'annee': {'id': 1, 'libelle': '2025-2026'},
        },
      },
      'moyenneGenerale': 13.7,
      'mention': 'Assez bien',
      'matieres': [
        {
          'matiereId': 1,
          'matiere': 'Algorithmique et Programmation',
          'code': 'ALGO101',
          'coefficient': 4,
          'moyenne': 15,
          'evaluationsNotees': 2,
          'evaluations': [
            {
              'id': 11,
              'titre': 'Devoir 1',
              'date': '2025-11-03T09:00:00.000Z',
              'type': 'DEVOIR',
              'coursId': 1,
              'cours': 'Algorithmique et Programmation I',
              'note': 14,
            },
            {
              'id': 12,
              'titre': 'Examen final',
              'date': '2025-12-15T09:00:00.000Z',
              'type': 'EXAMEN',
              'coursId': 1,
              'cours': 'Algorithmique et Programmation I',
              'note': 16,
            },
          ],
        },
        {
          'matiereId': 2,
          'matiere': 'Mathématiques',
          'code': 'MATH201',
          'coefficient': 3,
          'moyenne': null,
          'evaluationsNotees': 0,
          'evaluations': [
            {
              'id': 21,
              'titre': 'Devoir 1',
              'date': '2025-10-20T09:00:00.000Z',
              'type': 'DEVOIR',
              'coursId': 2,
              'cours': 'Mathématiques I',
              'note': null,
            },
          ],
        },
      ],
    };
  }

  /// Profil du `GET /auth/me` initial.
  Map<String, Object> _profilJson() {
    return {
      'id': 1,
      'nom': 'Dupont',
      'prenom': 'Jean',
      'email': 'jean@exemple.com',
      'role': 'ETUDIANT',
      'createdAt': '2026-09-16T00:00:00.000Z',
    };
  }

  static ResponseBody _json(Object payload) => ResponseBody.fromString(
        const JsonEncoder().convert(payload),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  void close({bool force = false}) {}
}

class _InMemoryTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<String?> readAccessToken() async => token;
  @override
  Future<void> writeAccessToken(String value) async => token = value;
  @override
  Future<void> deleteAccessToken() async => token = null;
}

Widget _buildFullApp() {
  final _FakeDioAdapter adapter = _FakeDioAdapter();
  final Dio dio = Dio()..httpClientAdapter = adapter;
  final AuthController controller = AuthController(
    AuthService(
      authRepository: AuthRepository(dio),
      tokenStorage: _InMemoryTokenStorage()..token = 'fake.jwt.token',
    ),
  );

  if (!ApiClient.instance.isInitialized) {
    ApiClient.instance.init(
      tokenProvider: () => 'fake.jwt.token',
      onUnauthorized: () => controller.handleSessionExpired(),
    );
  }
  ApiClient.instance.dio.httpClientAdapter = adapter;

  return ChangeNotifierProvider<AuthController>.value(
    value: controller,
    child: DakarTechApp(routerConfig: createAppRouter(controller)),
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Agrandit l'écran de test pour rendre toute la liste (pas de lazy build).
void _setSurface(
  WidgetTester tester, {
  double width = 800,
  double height = 2000,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Widget _wrap(Widget child) {
  return MaterialApp(theme: AppTheme.light, home: Scaffold(body: child));
}

Future<void> _pumpData(
  WidgetTester tester, {
  GradesRepository? repository,
}) async {
  await tester.pumpWidget(
    _wrap(GradesScreen(repository: repository ?? _FakeGradesRepository())),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
  await tester.pump(const Duration(milliseconds: 80));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Notes - relevé (données réelles)', () {
    testWidgets(
        'moyenne générale, mention, matières et coefficients s\'affichent',
        (tester) async {
      _setSurface(tester);
      await _pumpData(tester);

      // En-tête de section.
      expect(find.text('Notes & évaluations'), findsOneWidget);
      expect(find.text('Votre progression académique'), findsOneWidget);

      // Carte moyenne générale : nombre à virgule française + mention
      // (valeurs calculées par le backend).
      expect(find.text('Moyenne générale'), findsOneWidget);
      expect(find.text('13,7'), findsOneWidget);
      expect(find.text('/20'), findsOneWidget);
      expect(find.text('Assez bien'), findsOneWidget);
      expect(find.text('3 évaluation(s) notée(s)'), findsOneWidget);
      expect(find.text('Informatique & Génie logiciel 1ère année · 2025-2026'),
          findsOneWidget);

      // Matières.
      expect(find.text('Matières'), findsOneWidget);
      expect(find.text('3 matière(s)'), findsOneWidget);
      expect(find.text('Algorithmique et Programmation'), findsOneWidget);
      expect(find.text('ALGO101 · Coefficient 4'), findsOneWidget);
      expect(find.text('2 évaluation(s)'), findsOneWidget);
      expect(find.text('15 /20'), findsOneWidget);
      expect(find.text('Mathématiques'), findsOneWidget);
      expect(find.text('12 /20'), findsOneWidget);

      // Matière non notée : « — » à la place d'une moyenne inventée.
      expect(find.text('Bases de données'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('étudiant sans aucune matière → état vide', (tester) async {
      _setSurface(tester);
      await _pumpData(
        tester,
        repository: _FakeGradesRepository(variant: _ReleveVariant.empty),
      );

      expect(find.text('Moyenne générale'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('Aucune note'), findsNWidgets(2)); // carte + état vide
      expect(
        find.text('Vos relevés apparaîtront ici dès que vos '
            'enseignants corrigeront vos évaluations.'),
        findsOneWidget,
      );
      expect(find.text('0 matière(s)'), findsOneWidget);
    });
  });

  group('Notes - états d\'erreur', () {
    testWidgets('erreur API → message + Réessayer, pas de message technique',
        (tester) async {
      _setSurface(tester);
      await tester.pumpWidget(
        _wrap(
          GradesScreen(
            repository: _FakeGradesRepository(
              variant: _ReleveVariant.alwaysFail,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de charger vos notes.\n'
            'Vérifiez votre connexion puis réessayez.'),
        findsOneWidget,
      );
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.text('Connexion impossible.'), findsNothing);
    });

    testWidgets('réessayer après erreur → affiche le relevé', (tester) async {
      _setSurface(tester);
      await tester.pumpWidget(
        _wrap(
          GradesScreen(
            repository: _FakeGradesRepository(
              variant: _ReleveVariant.thenSucceed,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Réessayer'), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(find.text('Moyenne générale'), findsOneWidget);
      expect(find.text('13,7'), findsOneWidget);
      expect(find.text('Algorithmique et Programmation'), findsOneWidget);
    });
  });

  group('Notes - fiche détaillée d\'une matière', () {
    testWidgets(
        'moyenne, coefficient, nombre et notes des évaluations s\'affichent',
        (tester) async {
      _setSurface(tester);
      await tester.pumpWidget(
        _wrap(GradesMatiereScreen(matiere: _matiereRiche())),
      );
      await tester.pumpAndSettle();

      // Synthèse de la matière (moyenne réelle + mention dérivée).
      expect(find.text('Moyenne de la matière'), findsOneWidget);
      expect(find.text('15,7'), findsOneWidget);
      expect(find.text('/20'), findsOneWidget);
      expect(find.text('Bien'), findsWidgets); // mention 15,7 + éval. 14/20
      expect(find.text('3'), findsOneWidget); // notée(s)
      expect(find.text('4'), findsNWidgets(2)); // coefficient + évaluation(s)

      // Évaluations : notes réelles + mentions.
      expect(find.text('Évaluations'), findsOneWidget);
      expect(find.text('4 évaluation(s)'), findsOneWidget);
      expect(find.text('Devoir 1'), findsOneWidget);
      expect(find.text('Examen final'), findsOneWidget);
      expect(find.text('Mini-projet livret'), findsOneWidget);
      expect(find.text('14 /20'), findsOneWidget);
      expect(find.text('16 /20'), findsOneWidget);
      expect(find.text('17 /20'), findsOneWidget);

      // Évaluation à venir (non corrigée) → échéance, pas de note.
      expect(find.text('Test blanc'), findsOneWidget);
      expect(find.textContaining('Prévu le'), findsOneWidget);
      expect(find.text('En attente de correction'), findsNothing);
    });

    testWidgets('filtre local par type d\'évaluation', (tester) async {
      _setSurface(tester);
      await tester.pumpWidget(
        _wrap(GradesMatiereScreen(matiere: _matiereRiche())),
      );
      await tester.pumpAndSettle();

      // « Devoirs » : seules les évaluations DEVOIR restent.
      await tester.tap(find.text('Devoirs'));
      await tester.pumpAndSettle();

      expect(find.text('Devoir 1'), findsOneWidget);
      expect(find.text('Test blanc'), findsOneWidget);
      expect(find.text('Examen final'), findsNothing);
      expect(find.text('Mini-projet livret'), findsNothing);

      // « Projets » : seule la PROJET reste.
      await tester.tap(find.text('Projets'));
      await tester.pumpAndSettle();

      expect(find.text('Mini-projet livret'), findsOneWidget);
      expect(find.text('Devoir 1'), findsNothing);
      expect(find.text('Examen final'), findsNothing);

      // « Examens » : seule l'EXAMEN reste.
      await tester.tap(find.text('Examens'));
      await tester.pumpAndSettle();

      expect(find.text('Examen final'), findsOneWidget);
      expect(find.text('Mini-projet livret'), findsNothing);

      // Retour à « Toutes ».
      await tester.tap(find.text('Toutes'));
      await tester.pumpAndSettle();

      expect(find.text('Devoir 1'), findsOneWidget);
      expect(find.text('Examen final'), findsOneWidget);
      expect(find.text('Mini-projet livret'), findsOneWidget);
    });

    testWidgets('matière sans évaluation → état vide de la fiche',
        (tester) async {
      _setSurface(tester);
      final GradesMatiere sansEvaluation = GradesMatiere(
        matiereId: 9,
        matiere: 'Anglais technique',
        code: 'ANG201',
        coefficient: 1,
        moyenne: null,
        evaluationsNotees: 0,
        evaluations: const [],
      );
      await tester.pumpWidget(
        _wrap(GradesMatiereScreen(matiere: sansEvaluation)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Moyenne de la matière'), findsOneWidget);
      expect(find.text('—'), findsOneWidget);
      expect(find.text('0'), findsNWidgets(2)); // notée(s) + évaluation(s)
      expect(find.text('Aucune évaluation'), findsOneWidget);
      expect(
        find.text('Aucune évaluation pour cette matière pour le moment.'),
        findsOneWidget,
      );
    });
  });

  group('Notes - logique du contrôleur', () {
    test('load remplit le relevé sans erreur', () async {
      final GradesController controller = GradesController(
        repository: _FakeGradesRepository(),
      );
      await controller.load();

      expect(controller.releve, isNotNull);
      expect(controller.releve!.moyenneGenerale, 13.7);
      expect(controller.releve!.mention, 'Assez bien');
      expect(controller.releve!.matieres.length, 3);
      expect(controller.releve!.matieres.last.estNotee, isFalse);
      expect(controller.error, isNull);
    });

    test('load en échec met une erreur sans données', () async {
      final GradesController controller = GradesController(
        repository: _FakeGradesRepository(variant: _ReleveVariant.alwaysFail),
      );
      await controller.load();

      expect(controller.releve, isNull);
      expect(controller.error, isNotNull);
    });

    test('refresh conserve les données et efface l\'erreur', () async {
      final _FakeGradesRepository repo = _FakeGradesRepository(
        variant: _ReleveVariant.thenSucceed,
      );
      final GradesController controller = GradesController(repository: repo);
      await controller.load();
      expect(controller.releve, isNull);
      expect(controller.error, isNotNull);

      await controller.refresh();

      expect(controller.releve, isNotNull);
      expect(controller.releve!.moyenneGenerale, 13.7);
      expect(controller.error, isNull);
      expect(repo.fetchCalls, 2);
    });
  });

  group('Notes - repository réel (parsing des réponses API)', () {
    test('fetchMonReleve consomme la réponse réelle de /notes/mes-notes',
        () async {
      final Dio dio = Dio()..httpClientAdapter = _FakeDioAdapter();
      final ApiGradesRepository repository = ApiGradesRepository(dio);

      final GradesReleve releve = await repository.fetchMonReleve();

      expect(releve.etudiant.fullName, 'Jean Dupont');
      expect(releve.etudiant.classe.nom,
          'Informatique & Génie logiciel 1ère année');
      expect(releve.etudiant.classe.annee!.libelle, '2025-2026');
      expect(releve.moyenneGenerale, 13.7);
      expect(releve.mention, 'Assez bien');
      expect(releve.matieres.length, 2);

      final GradesMatiere algo = releve.matieres.first;
      expect(algo.matiere, 'Algorithmique et Programmation');
      expect(algo.code, 'ALGO101');
      expect(algo.coefficient, 4);
      expect(algo.moyenne, 15);
      expect(algo.evaluationsNotees, 2);
      expect(algo.evaluations.length, 2);
      expect(algo.evaluations.first.type, CourseEvaluationType.devoir);
      expect(algo.evaluations.first.note, 14);
      expect(algo.evaluations.last.type, CourseEvaluationType.examen);

      // Matière non notée : moyenne et note null.
      final GradesMatiere maths = releve.matieres.last;
      expect(maths.moyenne, isNull);
      expect(maths.evaluations.single.note, isNull);
    });
  });

  group('Notes - route /notes/matiere/:id (router + shell)', () {
    testWidgets('ouvrir la fiche matière depuis l\'onglet Notes',
        (tester) async {
      _setSurface(tester);
      await tester.pumpWidget(_buildFullApp());
      await tester.pumpAndSettle();

      // Accueil → onglet « Notes » (bottom navigation).
      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();

      // AppBar « Notes » + contenu réel branché sur /notes/mes-notes.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Notes'),
        ),
        findsOneWidget,
      );
      expect(find.text('Notes & évaluations'), findsOneWidget);
      expect(find.text('13,7'), findsOneWidget);
      expect(find.text('Assez bien'), findsOneWidget);

      // Ouverture de la fiche de la première matière.
      await tester.tap(find.text('Algorithmique et Programmation'));
      await tester.pumpAndSettle();

      expect(find.text('Moyenne de la matière'), findsOneWidget);
      expect(find.text('15'), findsOneWidget); // moyenne en grand format
      expect(find.text('16 /20'), findsOneWidget); // note réelle de l'examen
    });
  });
}