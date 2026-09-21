import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dakartech_mobile/core/errors/api_exception.dart';
import 'package:dakartech_mobile/core/errors/attendance_exception.dart';
import 'package:dakartech_mobile/core/network/api_client.dart';
import 'package:dakartech_mobile/core/routes/app_router.dart';
import 'package:dakartech_mobile/core/theme/app_theme.dart';
import 'package:dakartech_mobile/features/attendance/controllers/attendance_controller.dart';
import 'package:dakartech_mobile/features/attendance/data/attendance_repository.dart';
import 'package:dakartech_mobile/features/attendance/models/attendance_overview.dart';
import 'package:dakartech_mobile/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:dakartech_mobile/features/attendance/presentation/widgets/attendance_bilan_card.dart';
import 'package:dakartech_mobile/features/auth/controllers/auth_controller.dart';
import 'package:dakartech_mobile/features/auth/data/auth_repository.dart';
import 'package:dakartech_mobile/features/auth/data/auth_service.dart';
import 'package:dakartech_mobile/features/auth/data/token_storage.dart';
import 'package:dakartech_mobile/main.dart';

// ---------------------------------------------------------------------------
// Données de test (formes réelles des modèles backend)
// ---------------------------------------------------------------------------

const AttendanceCours _cours1 = AttendanceCours(
  id: 1,
  titre: 'Algorithmique et Programmation I',
  classeNom: 'IG1',
  matiereNom: 'Algorithmique et Programmation',
  enseignantNom: 'Diop',
  enseignantPrenom: 'Mamadou',
);

const AttendanceCours _cours2 = AttendanceCours(
  id: 2,
  titre: 'Réseaux I',
  classeNom: 'IG1',
  matiereNom: 'Réseaux',
  enseignantNom: 'Ndiaye',
  enseignantPrenom: 'Awa',
);

const AttendanceEtudiant _etudiant = AttendanceEtudiant(
  id: 1,
  matricule: 'DT2025001',
  prenom: 'Jean',
  nom: 'Dupont',
  classeNom: 'IG1',
);

const AttendanceBilan _bilan = AttendanceBilan(
  seancesPassees: 3,
  presences: 2,
  absences: 1,
  taux: 67,
  appreciation: 'Assiduité moyenne',
);

enum _AttendanceVariant {
  /// Séance en cours émargeable + historique mixte.
  withOngoing,

  /// Aucune séance en cours (bandeau absent).
  withoutOngoing,

  /// L'API échoue à chaque appel.
  alwaysFail,

  /// Échoue au premier appel, puis renvoie des données.
  thenSucceed,

  /// L'émargement renvoie un 409 « déjà émargé ».
  emargerAlready,
}

/// Repository de substitution : construit un état d'assiduité autour de
/// l'instant présent (mêmes formes que l'API réelle), sans aucune donnée
/// fictive métier. L'émargement réussit et bascule l'état « fait ».
class _FakeAttendanceRepository implements AttendanceRepository {
  _FakeAttendanceRepository({this.variant = _AttendanceVariant.withOngoing});

  final _AttendanceVariant variant;
  bool _emarged = false;
  int fetchCalls = 0;

  @override
  Future<AttendanceOverview> fetchMonAssiduite() async {
    fetchCalls++;
    if (variant == _AttendanceVariant.alwaysFail) {
      throw const ApiException('Connexion impossible.');
    }
    if (variant == _AttendanceVariant.thenSucceed && fetchCalls == 1) {
      throw const ApiException('Connexion impossible.');
    }
    return _overview();
  }

  @override
  Future<AttendanceEmargementResult> emarger(int seanceId) async {
    if (variant == _AttendanceVariant.emargerAlready) {
      throw const AttendanceException(
        'Vous avez déjà émargé votre présence à cette séance.',
        kind: AttendanceConflictCode.alreadyRecorded,
        statusCode: 409,
      );
    }
    _emarged = true;
    return AttendanceEmargementResult(
      presenceId: 900,
      seanceId: seanceId,
      present: true,
    );
  }

  AttendanceOverview _overview() {
    final DateTime now = DateTime.now();
    final bool ongoing = variant == _AttendanceVariant.withOngoing ||
        variant == _AttendanceVariant.emargerAlready;

    final DateTime passe1 = now.subtract(const Duration(days: 5));
    return AttendanceOverview(
      etudiant: _etudiant,
      bilan: _bilan,
      historique: [
        AttendanceHistoryEntry(
          seanceId: 101,
          date: passe1,
          duree: 2,
          chapitre: 'Fonctions et récursivité',
          statut: PresenceStatut.present,
          emargeLe: passe1.add(const Duration(minutes: 5)),
          cours: _cours1,
        ),
        AttendanceHistoryEntry(
          seanceId: 102,
          date: now.subtract(const Duration(days: 3)),
          duree: 1,
          chapitre: 'Modèle OSI',
          statut: PresenceStatut.absent,
          remarque: 'Retard',
          cours: _cours2,
        ),
        AttendanceHistoryEntry(
          seanceId: 103,
          date: now.subtract(const Duration(days: 1)),
          duree: 2,
          chapitre: 'Listes chaînées',
          statut: PresenceStatut.present,
          emargeLe: now.subtract(const Duration(days: 1)),
          cours: _cours1,
        ),
      ],
      emargement: AttendanceEmargementState(
        seance: ongoing
            ? AttendanceOngoingSeance(
                id: 50,
                date: now,
                duree: 2,
                chapitre: 'Récursivité (exercices)',
                cours: _cours1,
              )
            : null,
        autorise: ongoing && !_emarged,
        fait: ongoing && _emarged,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Application complète (router + shell) : adapter Dio simulé
// ---------------------------------------------------------------------------

/// Profil étudiant pour les tests full-app.
const Map<String, Object> _etudiantProfile = {
  'id': 1,
  'nom': 'Dupont',
  'prenom': 'Jean',
  'email': 'jean@exemple.com',
  'role': 'ETUDIANT',
  'createdAt': '2026-09-16T00:00:00.000Z',
};

/// Adapter simulé : le dashboard consomme les cours/séances (comme dans
/// les tests planning), l'écran Présences consomme `/presences/...`.
class _FakeDioAdapter implements HttpClientAdapter {
  bool _emarged = false;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/presences/mon-assiduite')) {
      return _json(_monAssiduiteJson());
    }
    if (options.method == 'POST' && options.path.endsWith('/emarger')) {
      _emarged = true;
      return _json({'id': 900, 'present': true, 'seance': {'id': 50}});
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
    return _json(_etudiantProfile);
  }

  Map<String, Object> _monAssiduiteJson() {
    final String now = DateTime.now().toIso8601String();
    final String yesterday =
        DateTime.now().subtract(const Duration(days: 1)).toIso8601String();
    return {
      'etudiant': {
        'id': 1,
        'matricule': 'DT2025001',
        'prenom': 'Jean',
        'nom': 'Dupont',
        'classe': {'id': 1, 'nom': 'IG1'},
      },
      'bilan': {
        'seancesPassees': 1,
        'presences': 1,
        'absences': 0,
        'taux': 100,
        'appreciation': 'Excellente assiduité',
      },
      'historique': [
        {
          'seanceId': 103,
          'date': yesterday,
          'duree': 2,
          'chapitre': 'Listes chaînées',
          'statut': 'PRESENT',
          'emargeLe': yesterday,
          'remarque': null,
          'cours': {
            'id': 1,
            'titre': 'Algorithmique et Programmation I',
            'classe': {'id': 1, 'nom': 'IG1'},
            'matiere': {
              'id': 1,
              'nom': 'Algorithmique et Programmation',
            },
            'enseignant': {'id': 1, 'nom': 'Diop', 'prenom': 'Mamadou'},
          },
        },
      ],
      'emargement': {
        'seance': {
          'id': 50,
          'date': now,
          'duree': 2,
          'chapitre': 'Récursivité (exercices)',
          'cours': {
            'id': 1,
            'titre': 'Algorithmique et Programmation I',
            'classe': {'id': 1, 'nom': 'IG1'},
            'matiere': {
              'id': 1,
              'nom': 'Algorithmique et Programmation',
            },
            'enseignant': {'id': 1, 'nom': 'Diop', 'prenom': 'Mamadou'},
          },
        },
        'autorise': !_emarged,
        'fait': _emarged,
      },
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
  AttendanceRepository? repository,
}) async {
  await tester.pumpWidget(
    _wrap(
      AttendanceScreen(repository: repository ?? _FakeAttendanceRepository()),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
  await tester.pump(const Duration(milliseconds: 80));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Attendances - données (séance en cours + historique)', () {
    testWidgets('bandeau d\'émargement, bilan et historique s\'affichent',
        (tester) async {
      _setSurface(tester);
      await _pumpData(tester);

      // Bandeau d'émargement de la séance en cours.
      expect(find.text('Séance en cours'), findsOneWidget);
      expect(find.text('Émarger ma présence'), findsOneWidget);

      // Carte de bilan : taux réel + appréciation backend.
      expect(find.text('67%'), findsOneWidget);
      expect(find.text('Assiduité moyenne'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AttendanceBilanCard),
          matching: find.text('Présences'),
        ),
        findsOneWidget,
      );
      expect(find.text('Absences'), findsOneWidget);

      // Historique complet + filtres.
      expect(find.text('Historique'), findsOneWidget);
      expect(find.text('3 séance(s)'), findsOneWidget);
      expect(find.text('Fonctions et récursivité'), findsOneWidget);
      expect(find.text('Modèle OSI'), findsOneWidget);
      expect(find.text('Retard'), findsOneWidget);
      expect(find.text('Présent'), findsNWidgets(2));
      expect(find.text('Absent'), findsOneWidget);
    });

    testWidgets('filtre local « Absences » réduit la timeline', (tester) async {
      _setSurface(tester);
      await _pumpData(tester);

      await tester.tap(find.text('Absents'));
      await tester.pumpAndSettle();

      expect(find.text('Modèle OSI'), findsOneWidget);
      expect(find.text('Fonctions et récursivité'), findsNothing);
      expect(find.text('Retard'), findsOneWidget);
    });

    testWidgets('filtre local « Présents » ne montre que les présences',
        (tester) async {
      _setSurface(tester);
      await _pumpData(tester);

      await tester.tap(find.text('Présents'));
      await tester.pumpAndSettle();

      expect(find.text('Présent'), findsNWidgets(2));
      expect(find.text('Absent'), findsNothing);
      expect(find.text('Modèle OSI'), findsNothing);
    });

    testWidgets('aucune séance en cours → bandeau masqué', (tester) async {
      _setSurface(tester);
      await _pumpData(
        tester,
        repository: _FakeAttendanceRepository(
          variant: _AttendanceVariant.withoutOngoing,
        ),
      );

      expect(find.text('Séance en cours'), findsNothing);
      expect(find.text('Émarger ma présence'), findsNothing);
      // Le reste (bilan + historique) est bien là.
      expect(find.text('67%'), findsOneWidget);
      expect(find.text('Historique'), findsOneWidget);
    });
  });

  group('Attendances - émargement', () {
    testWidgets('émarger affiche le succès et bascule le bandeau',
        (tester) async {
      _setSurface(tester);
      await _pumpData(tester);

      await tester.tap(find.text('Émarger ma présence'));
      await tester.pumpAndSettle();

      // Snackbar de succès + bandeau marqué « Émargé » après rechargement.
      expect(find.text('Présence émargée avec succès.'), findsOneWidget);
      expect(find.text('Émargé'), findsOneWidget);
      expect(find.text('Votre présence a bien été enregistrée.'), findsOneWidget);
      expect(find.text('Émarger ma présence'), findsNothing);
    });

    testWidgets('409 déjà émargé → message clair, bandeau conservé',
        (tester) async {
      _setSurface(tester);
      await _pumpData(
        tester,
        repository: _FakeAttendanceRepository(
          variant: _AttendanceVariant.emargerAlready,
        ),
      );

      await tester.tap(find.text('Émarger ma présence'));
      await tester.pumpAndSettle();

      expect(
        find.text('Vous avez déjà émargé votre présence à cette séance.'),
        findsOneWidget,
      );
      expect(find.text('Émarger ma présence'), findsOneWidget);
    });
  });

  group('Attendances - états d\'erreur', () {
    testWidgets('erreur API → message + Réessayer, pas de message technique',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          AttendanceScreen(
            repository: _FakeAttendanceRepository(
              variant: _AttendanceVariant.alwaysFail,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de charger votre assiduité.\n'
            'Vérifiez votre connexion puis réessayez.'),
        findsOneWidget,
      );
      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.text('Connexion impossible.'), findsNothing);
    });

    testWidgets('réessayer après erreur → affiche l\'assiduité',
        (tester) async {
      _setSurface(tester);
      await tester.pumpWidget(
        _wrap(
          AttendanceScreen(
            repository: _FakeAttendanceRepository(
              variant: _AttendanceVariant.thenSucceed,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Réessayer'), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(find.text('67%'), findsOneWidget);
      expect(find.text('Historique'), findsOneWidget);
    });
  });

  group('Attendances - logique du contrôleur', () {
    test('load remplit overview sans erreur', () async {
      final AttendanceController controller = AttendanceController(
        repository: _FakeAttendanceRepository(),
      );
      await controller.load();

      expect(controller.overview, isNotNull);
      expect(controller.overview!.bilan.taux, 67);
      expect(controller.overview!.historique.length, 3);
      expect(controller.error, isNull);
    });

    test('emarger réussi → rechargement de l\'état réel', () async {
      final _FakeAttendanceRepository repo = _FakeAttendanceRepository();
      final AttendanceController controller = AttendanceController(
        repository: repo,
      );
      await controller.load();
      final int calls = repo.fetchCalls;

      final Object? failure = await controller.emarger(50);

      expect(failure, isNull);
      expect(controller.lastEmargementSucceeded, isTrue);
      // L'assiduité est rechargée après l'émargement.
      expect(repo.fetchCalls, calls + 1);
      expect(controller.overview!.emargement.fait, isTrue);
      expect(controller.overview!.emargement.autorise, isFalse);
    });

    test('emarger en échec → exception typée sans rechargement', () async {
      final _FakeAttendanceRepository repo = _FakeAttendanceRepository(
        variant: _AttendanceVariant.emargerAlready,
      );
      final AttendanceController controller = AttendanceController(
        repository: repo,
      );
      await controller.load();
      final int calls = repo.fetchCalls;

      final Object? failure = await controller.emarger(50);

      expect(failure, isA<AttendanceException>());
      final AttendanceException ex = failure as AttendanceException;
      expect(ex.kind, AttendanceConflictCode.alreadyRecorded);
      expect(controller.lastEmargementSucceeded, isFalse);
      expect(repo.fetchCalls, calls);
    });
  });

  group('Attendances - repository réel (parsing des réponses API)', () {
    test('fetchMonAssiduite et emarger consomment les réponses réelles',
        () async {
      final Dio dio = Dio()..httpClientAdapter = _FakeDioAdapter();
      final ApiAttendanceRepository repository = ApiAttendanceRepository(dio);

      final AttendanceOverview overview =
          await repository.fetchMonAssiduite();
      expect(overview.etudiant.fullName, 'Jean Dupont');
      expect(overview.bilan.taux, 100);
      expect(overview.bilan.presences, 1);
      expect(overview.historique.single.statut, PresenceStatut.present);
      expect(overview.emargement.seance!.id, 50);
      expect(overview.emargement.autorise, isTrue);

      final AttendanceEmargementResult result = await repository.emarger(50);
      expect(result.presenceId, 900);
      expect(result.present, isTrue);
      expect(result.seanceId, 50);
    });
  });

  group('Attendances - route /attendance (router + shell)', () {
    testWidgets('action rapide « Émarger » ouvre l\'écran Présences',
        (tester) async {
      _setSurface(tester);
      await tester.pumpWidget(_buildFullApp());
      await tester.pumpAndSettle();

      // Dashboard → action rapide « Émarger ».
      await tester.tap(find.text('Émarger'));
      await tester.pumpAndSettle();

      // L'écran réel est affiché : bandeau d'émargement branché sur l'API.
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Présences'),
        ),
        findsOneWidget,
      );
      expect(find.text('Émarger ma présence'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);

      // Le flow d'émargement fonctionne de bout en bout.
      await tester.tap(find.text('Émarger ma présence'));
      await tester.pumpAndSettle();

      expect(find.text('Présence émargée avec succès.'), findsOneWidget);
      expect(find.text('Émargé'), findsOneWidget);
    });
  });
}