import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dakartech_mobile/core/errors/api_exception.dart';
import 'package:dakartech_mobile/core/network/api_client.dart';
import 'package:dakartech_mobile/core/routes/app_router.dart';
import 'package:dakartech_mobile/core/theme/app_theme.dart';
import 'package:dakartech_mobile/core/utils/date_format.dart';
import 'package:dakartech_mobile/features/auth/controllers/auth_controller.dart';
import 'package:dakartech_mobile/features/auth/data/auth_repository.dart';
import 'package:dakartech_mobile/features/auth/data/auth_service.dart';
import 'package:dakartech_mobile/features/auth/data/token_storage.dart';
import 'package:dakartech_mobile/features/courses/data/models/course_detail.dart';
import 'package:dakartech_mobile/features/courses/data/models/course_model.dart';
import 'package:dakartech_mobile/features/courses/data/repositories/courses_repository.dart';
import 'package:dakartech_mobile/features/schedule/controllers/schedule_controller.dart';
import 'package:dakartech_mobile/features/schedule/data/schedule_repository.dart';
import 'package:dakartech_mobile/features/schedule/models/schedule_session.dart';
import 'package:dakartech_mobile/features/schedule/presentation/screens/schedule_screen.dart';
import 'package:dakartech_mobile/main.dart';

// ---------------------------------------------------------------------------
// Données de test (formes réelles des modèles backend)
// ---------------------------------------------------------------------------

const Course _course1 = Course(
  id: 1,
  titre: 'Algorithmique et Programmation I',
  volumeHoraire: 42,
  matiere: CourseMatiere(
    id: 1,
    nom: 'Algorithmique et Programmation',
    code: 'ALGO101',
    coefficient: 4,
  ),
  enseignant: CourseEnseignant(id: 1, nom: 'Diop', prenom: 'Mamadou'),
);

const Course _course2 = Course(
  id: 2,
  titre: 'Réseaux I',
  volumeHoraire: 36,
  matiere: CourseMatiere(id: 2, nom: 'Réseaux', code: 'RES102', coefficient: 3),
  enseignant: CourseEnseignant(id: 2, nom: 'Ndiaye', prenom: 'Awa'),
);

DateTime _at(DateTime base, int dayOffset, int hour) =>
    DateTime(base.year, base.month, base.day + dayOffset, hour);

/// Date-only d'aujourd'hui (comparaisons de jour indépendantes de l'heure).
DateTime _todayOnly(DateTime now) => DateTime(now.year, now.month, now.day);

DateTime _nextMonday(DateTime base) {
  final DateTime monday = _todayOnly(base)
      .subtract(Duration(days: _todayOnly(base).weekday - 1));
  return monday.add(const Duration(days: 7));
}

ScheduleSession _session(
  Course course,
  int id,
  DateTime start, {
  int duree = 2,
  String chapitre = '',
}) {
  return ScheduleSession(
    course: course,
    seance: CourseSeance(
      id: id,
      date: start,
      duree: duree,
      chapitre: chapitre,
    ),
  );
}

enum _ScheduleVariant { full, withoutOngoing, todayEmpty }

/// Repository de substitution : renvoie des [ScheduleSession] construites
/// autour de l'instant présent (mêmes formes que l'API réelle), sans
/// aucune donnée fictive métier.
class _FakeScheduleRepository implements ScheduleRepository {
  const _FakeScheduleRepository({this.variant = _ScheduleVariant.full});

  final _ScheduleVariant variant;

  @override
  Future<List<ScheduleSession>> fetchSessions() async {
    return switch (variant) {
      _ScheduleVariant.full => _fullSessions(),
      _ScheduleVariant.withoutOngoing => _withoutOngoingSessions(),
      _ScheduleVariant.todayEmpty => _todayEmptySessions(),
    };
  }

  /// Aujourd'hui contient une séance terminée, une en cours et une à
  /// venir ; demain et lundi prochain des séances à venir. La séance
  /// « terminée » est placée le même jour (déterminisme quel que soit le
  /// moment d'exécution des tests).
  List<ScheduleSession> _fullSessions() {
    final DateTime now = DateTime.now();
    return [
      _session(
        _course1,
        1,
        now.subtract(const Duration(hours: 3)),
        duree: 2,
        chapitre: 'Séance terminée',
      ),
      _session(
        _course2,
        2,
        now.subtract(const Duration(minutes: 30)),
        chapitre: 'Séance en cours',
      ),
      _session(
        _course1,
        3,
        now.add(const Duration(hours: 2)),
        chapitre: 'Séance à venir',
      ),
      _session(_course2, 4, _at(now, 1, 10), chapitre: 'Séance demain'),
      _session(_course2, 5, _nextMonday(now).add(const Duration(hours: 9))),
    ];
  }

  /// Identique à [full] sans la séance en cours (aucun badge animé).
  List<ScheduleSession> _withoutOngoingSessions() {
    final List<ScheduleSession> all = _fullSessions();
    return all
        .where((ScheduleSession s) => s.seance.chapitre != 'Séance en cours')
        .toList(growable: false);
  }

  /// Aujourd'hui ne contient aucune séance (hier + lundi prochain).
  List<ScheduleSession> _todayEmptySessions() {
    final DateTime now = DateTime.now();
    return [
      _session(_course1, 1, _at(now, -1, 15), chapitre: 'Séance passée'),
      _session(_course2, 5, _nextMonday(now).add(const Duration(hours: 9))),
    ];
  }
}

/// Compteur d'appels (vérifie le rechargement).
class _CountingScheduleRepository implements ScheduleRepository {
  int calls = 0;

  @override
  Future<List<ScheduleSession>> fetchSessions() async {
    calls++;
    return _FakeScheduleRepository(
      variant: _ScheduleVariant.withoutOngoing,
    ).fetchSessions();
  }
}

/// Échoue au premier appel, puis renvoie des données.
class _ThenSucceedScheduleRepository implements ScheduleRepository {
  bool _failed = false;

  @override
  Future<List<ScheduleSession>> fetchSessions() async {
    if (!_failed) {
      _failed = true;
      throw const ApiException('Connexion impossible.');
    }
    // Sans séance en cours : pas de badge animé, `pumpAndSettle` reste sûr.
    return _FakeScheduleRepository(
      variant: _ScheduleVariant.withoutOngoing,
    ).fetchSessions();
  }
}

/// Toujours en erreur.
class _AlwaysFailScheduleRepository implements ScheduleRepository {
  @override
  Future<List<ScheduleSession>> fetchSessions() async {
    throw const ApiException('Connexion impossible.');
  }
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

/// Pompe jusqu'à l'affichage des données SANS `pumpAndSettle` : utilisé
/// dès qu'une séance en cours (badge animé) est à l'écran.
Future<void> _pumpData(
  WidgetTester tester, {
  ScheduleRepository repository = const _FakeScheduleRepository(),
}) async {
  await tester.pumpWidget(_wrap(ScheduleScreen(repository: repository)));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
  await tester.pump(const Duration(milliseconds: 80));
}

Future<void> _render(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(_wrap(widget));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 80));
  await tester.pump(const Duration(milliseconds: 80));
}

// ---------------------------------------------------------------------------
// Repository réel : composition des deux endpoints (fichiers distincts).
// ---------------------------------------------------------------------------

class _FakeCoursesRepository implements CoursesRepository {
  @override
  Future<List<Course>> getMyCourses() async => const [_course1, _course2];

  @override
  Future<List<CourseSeance>> getCourseSeances(int courseId) async {
    final DateTime now = DateTime.now();
    if (courseId == _course1.id) {
      return [
        // En vrac : l'ordre final est imposé par le repo planning.
        CourseSeance(
          id: 101,
          date: _at(now, 1, 10),
          duree: 2,
          chapitre: 'Séance demain (cours 1)',
        ),
        CourseSeance(
          id: 102,
          date: now.subtract(const Duration(days: 3)),
          duree: 2,
          chapitre: 'Séance ancienne (cours 1)',
        ),
      ];
    }
    return [
      CourseSeance(
        id: 201,
        date: now.add(const Duration(hours: 4)),
        duree: 2,
        chapitre: 'Séance aujourd\'hui (cours 2)',
      ),
    ];
  }

  @override
  Future<CourseDetail> getCourseById(int id) async =>
      throw UnimplementedError();

  @override
  Future<List<CourseDocument>> getCourseDocuments(int courseId) async =>
      throw UnimplementedError();

  @override
  Future<List<CourseEvaluation>> getCourseEvaluations(int courseId) async =>
      throw UnimplementedError();
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

/// Adapter simulé : deux cours avec des séances aujourd'hui à venir
/// (aucune séance en cours → pas de badge animé, `pumpAndSettle` sûr).
class _FakeDioAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final DateTime base = DateTime.now();
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
        {
          'id': 2,
          'titre': 'Réseaux I',
          'volumeHoraire': 36,
          'matiere': {
            'id': 2,
            'nom': 'Réseaux',
            'code': 'RES102',
            'coefficient': 3,
          },
          'enseignant': {'id': 2, 'nom': 'Ndiaye', 'prenom': 'Awa'},
        },
      ]);
    }
    if (options.path.endsWith('/cours/1/seances')) {
      return _json([
        {
          'id': 101,
          'date': _iso(_at(base, 1, 10)),
          'duree': 2,
          'chapitre': 'Séance demain (cours 1)',
        },
        {
          'id': 102,
          'date': _iso(DateTime(base.year, base.month, base.day)),
          'duree': 2,
          'chapitre': 'Séance aujourd\'hui (cours 1)',
        },
      ]);
    }
    if (options.path.endsWith('/cours/2/seances')) {
      return _json([
        {
          'id': 201,
          'date': _iso(DateTime(base.year, base.month, base.day, 23, 59)),
          'duree': 2,
          'chapitre': 'Séance aujourd\'hui (cours 2)',
        },
      ]);
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
        'prochaineSeance': {
          'id': 11,
          'date': _iso(_at(base, 1, 10)),
          'duree': 2,
          'chapitre': 'Séance aujourd\'hui (cours 1)',
        },
      });
    }
    if (options.path.endsWith('/cours/2')) {
      return _json({
        'id': 2,
        'titre': 'Réseaux I',
        'volumeHoraire': 36,
        'matiere': {
          'id': 2,
          'nom': 'Réseaux',
          'code': 'RES102',
          'coefficient': 3,
        },
        'enseignant': {'id': 2, 'nom': 'Ndiaye', 'prenom': 'Awa'},
        'classe': {
          'id': 1,
          'nom': 'IG1',
          'filiere': {'id': 1, 'nom': 'Informatique de Gestion'},
          'annee': {'id': 1, 'libelle': '2025-2026', 'active': true},
        },
        'prochaineSeance': {
          'id': 21,
          'date': _iso(DateTime(base.year, base.month, base.day, 23, 59)),
          'duree': 2,
          'chapitre': 'Séance aujourd\'hui (cours 2)',
        },
      });
    }
    return _json(_etudiantProfile);
  }

  static ResponseBody _json(Object payload) => ResponseBody.fromString(
        const JsonEncoder().convert(payload),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  static String _iso(DateTime date) => date.toIso8601String();

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

Widget _buildFullApp({String? storedToken}) {
  final _FakeDioAdapter adapter = _FakeDioAdapter();
  final Dio dio = Dio()..httpClientAdapter = adapter;
  final AuthController controller = AuthController(
    AuthService(
      authRepository: AuthRepository(dio),
      tokenStorage: _InMemoryTokenStorage()
        ..token = (storedToken?.isNotEmpty ?? false) ? storedToken : null,
    ),
  );

  if (!ApiClient.instance.isInitialized) {
    ApiClient.instance.init(
      tokenProvider: () => storedToken,
      onUnauthorized: () => controller.handleSessionExpired(),
    );
  }
  ApiClient.instance.dio.httpClientAdapter = adapter;

  return ChangeNotifierProvider<AuthController>.value(
    value: controller,
    child: DakarTechApp(routerConfig: createAppRouter(controller)),
  );
}

Finder _navLabel(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Schedule - données (jour courant complet)', () {
    testWidgets('timeline, résumé et bandeau prochain cours', (tester) async {
      _setSurface(tester);
      await _pumpData(tester);

      // Header + navigateur de semaine (label réel).
      expect(find.text('Votre emploi du temps'), findsOneWidget);
      expect(
        find.text('Cette semaine'),
        findsOneWidget,
      );

      // Résumé de la journée : « Aujourd'hui », 3 séances et la plage
      // horaire réelle menée par la séance du début de journée.
      expect(find.text('Aujourd\'hui'), findsOneWidget);
      expect(find.textContaining('3 séances'), findsOneWidget);

      final DateTime now = DateTime.now();
      final DateTime passedStart = now.subtract(const Duration(hours: 3));
      final DateTime upcomingEnd = now.add(const Duration(hours: 4));
      expect(
        find.textContaining(
          '${formatFrenchHour(passedStart)} — '
          '${formatFrenchHour(upcomingEnd)}',
        ),
        findsOneWidget,
      );

      // Bandeau « Prochain cours » : séance à venir + compte à rebours
      // réel (libellé calculé au build, d'où l'assertion souple).
      expect(find.text('Prochain cours'), findsOneWidget);
      expect(find.textContaining('Dans '), findsOneWidget);

      // Timeline : les trois séances réelles d'aujourd'hui s'affichent.
      expect(find.text('Séance en cours'), findsOneWidget);
      expect(find.text('Séance à venir'), findsOneWidget);
      expect(find.text('Séance terminée'), findsOneWidget);
      expect(find.text('Mamadou Diop'), findsNWidgets(2));
      expect(find.text('Awa Ndiaye'), findsWidgets);
    });

    testWidgets('séance en cours → badge « EN COURS » animé', (tester) async {
      _setSurface(tester);
      await _pumpData(tester);

      expect(find.text('EN COURS'), findsOneWidget);
      // Une séance terminée affiche « Terminée ».
      expect(find.text('Terminée'), findsOneWidget);
    });

    testWidgets('pull-to-refresh recharge les séances', (tester) async {
      _setSurface(tester);
      final _CountingScheduleRepository repo = _CountingScheduleRepository();

      await _render(tester, ScheduleScreen(repository: repo));
      expect(repo.calls, 1);

      // Déclenche le pull-to-refresh via la RefreshCallback réellement
// câblée par l'écran (celle invoquée par le geste du composant).
      final RefreshIndicator indicator =
          tester.widget<RefreshIndicator>(find.byType(RefreshIndicator));
      await indicator.onRefresh();
      await tester.pumpAndSettle();
      expect(repo.calls, 2);
    });
  });

  group('Schedule - sélection et navigation de semaine', () {
    testWidgets('changer de jour affiche les séances de ce jour',
        (tester) async {
      _setSurface(tester);
      final DateTime tomorrow = _at(DateTime.now(), 1, 10);

      await _render(
        tester,
        ScheduleScreen(
          repository: const _FakeScheduleRepository(
            variant: _ScheduleVariant.withoutOngoing,
          ),
        ),
      );

      // Aujourd'hui : séances à venir et terminée affichées.
      expect(find.text('Séance à venir'), findsOneWidget);
      expect(find.text('Terminée'), findsOneWidget);

      // Le jour suivant ne montre que sa propre séance.
      await tester.tap(find.text('${tomorrow.day}'));
      await tester.pumpAndSettle();

      expect(find.text('Séance demain'), findsOneWidget);
      expect(find.text('Séance à venir'), findsNothing);
      expect(find.text('Terminée'), findsNothing);
    });

    testWidgets('navigation semaine + retour « Aujourd\'hui »', (tester) async {
      _setSurface(tester);
      await _render(
        tester,
        ScheduleScreen(
          repository: const _FakeScheduleRepository(
            variant: _ScheduleVariant.todayEmpty,
          ),
        ),
      );

      final DateTime now = DateTime.now();
      final DateTime thisMonday = _todayOnly(now)
          .subtract(Duration(days: _todayOnly(now).weekday - 1));
      final String thisWeekLabel = formatFrenchWeekRange(thisMonday);

      // Aujourd'hui est vide : état vide + pas de bouton « Aujourd'hui ».
      expect(find.text('Aucun cours prévu'), findsOneWidget);
      expect(find.text('Cette semaine'), findsOneWidget);
      expect(find.text('Voir aujourd\'hui'), findsNothing);

      // Semaine précédente : libellé décalé + lien « Aujourd'hui ».
      await tester.tap(find.byTooltip('Semaine précédente'));
      await tester.pumpAndSettle();

      expect(
        find.text(formatFrenchWeekRange(thisMonday.subtract(
          const Duration(days: 7),
        ))),
        findsOneWidget,
      );
      expect(find.text('Cette semaine'), findsNothing);
      expect(find.text('Voir aujourd\'hui'), findsOneWidget);

      // Retour à aujourd'hui via l'action de l'état vide.
      await tester.tap(find.text('Voir aujourd\'hui'));
      await tester.pumpAndSettle();

      expect(find.text(thisWeekLabel), findsOneWidget);
      expect(find.text('Cette semaine'), findsOneWidget);

      // Semaine suivante depuis aujourd'hui.
      await tester.tap(find.byTooltip('Semaine suivante'));
      await tester.pumpAndSettle();

      expect(
        find.text(formatFrenchWeekRange(thisMonday.add(
          const Duration(days: 7),
        ))),
        findsOneWidget,
      );
      expect(find.text('Cette semaine'), findsNothing);
    });
  });

  group('Schedule - états d\'erreur', () {
    testWidgets('erreur API → message + Réessayer', (tester) async {
      await tester.pumpWidget(
        _wrap(ScheduleScreen(repository: _AlwaysFailScheduleRepository())),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Impossible de charger votre emploi du temps.\n'
            'Vérifiez votre connexion puis réessayez.'),
        findsOneWidget,
      );
      expect(find.text('Réessayer'), findsOneWidget);
      // Le message technique ne doit pas apparaître.
      expect(find.text('Connexion impossible.'), findsNothing);
    });

    testWidgets('réessayer après erreur → affiche les données',
        (tester) async {
      final _ThenSucceedScheduleRepository repo = _ThenSucceedScheduleRepository();

      await tester.pumpWidget(_wrap(ScheduleScreen(repository: repo)));
      await tester.pumpAndSettle();

      expect(find.text('Réessayer'), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(find.text('Aujourd\'hui'), findsOneWidget);
      expect(find.text('Séance à venir'), findsOneWidget);
    });
  });

  group('Schedule - logique du contrôleur', () {
    test('jour frais : aujourd\'hui sélectionné, semaine en cours',
        () async {
      final ScheduleController controller =
          ScheduleController(repository: _FakeScheduleRepository());
      final DateTime now = DateTime.now();

      expect(controller.selectedDate, _todayOnly(now));
      expect(controller.isCurrentWeek, isTrue);
      expect(controller.selectedWeekOffset, 0);
      expect(controller.weekDays.length, 7);
      expect(
        controller.weekDays.first,
        _todayOnly(now).subtract(Duration(days: now.weekday - 1)),
      );
      expect(
        controller.weekRangeLabel,
        formatFrenchWeekRange(_todayOnly(now)
            .subtract(Duration(days: now.weekday - 1))),
      );
    });

    test('semaine précédente/suivante et retour à aujourd\'hui', () async {
      final ScheduleController controller =
          ScheduleController(repository: _FakeScheduleRepository());

      controller.nextWeek();
      expect(controller.selectedWeekOffset, 1);
      expect(controller.isCurrentWeek, isFalse);

      controller.previousWeek();
      controller.previousWeek();
      expect(controller.selectedWeekOffset, -1);

      controller.goToday();
      expect(controller.selectedWeekOffset, 0);
      expect(controller.isCurrentWeek, isTrue);
    });

    test('sessionsForDay filtre par jour ; en cours et prochain', () async {
      final DateTime now = DateTime.now();
      final List<ScheduleSession> data = [
        _session(
          _course1,
          1,
          now.subtract(const Duration(minutes: 30)),
          chapitre: 'Séance en cours',
        ),
        _session(
          _course2,
          2,
          now.add(const Duration(hours: 2)),
          chapitre: 'Séance à venir',
        ),
        _session(_course2, 3, _at(now, 1, 10), chapitre: 'Séance demain'),
      ];
      final _StaticRepository repo = _StaticRepository(data);
      final ScheduleController controller = ScheduleController(repository: repo);
      await controller.load();

      expect(controller.sessionsForSelectedDay().length, 2);
      expect(controller.selectedDate, _todayOnly(now));

      final ScheduleSession? ongoing =
          controller.ongoingSessionForSelectedDay(now: now);
      expect(ongoing?.seance.chapitre, 'Séance en cours');

      final ScheduleSession? next =
          controller.nextSessionForSelectedDay(now: now);
      expect(next?.seance.chapitre, 'Séance à venir');

      // « Demain » n'est pas dans le jour sélectionné.
      expect(controller.sessionsForDay(_at(now, 1, 10)).length, 1);
    });
  });

  group('Schedule - repository réel (composition API)', () {
    test('fetchSessions fusionne les séances de tous les cours, triées',
        () async {
      final DateTime now = DateTime.now();
      final ApiScheduleRepository repository =
          ApiScheduleRepository(_FakeCoursesRepository());

      final List<ScheduleSession> sessions = await repository.fetchSessions();

      // 2 cours → 2 + 1 = 3 séances au total.
      expect(sessions.length, 3);

      // Trié par date croissante.
      for (int i = 1; i < sessions.length; i++) {
        expect(
          sessions[i].start.isAfter(sessions[i - 1].start),
          isTrue,
        );
      }

      // Les séances des deux cours sont bien présentes.
      expect(
        sessions.any((ScheduleSession s) => s.course.id == 1),
        isTrue,
      );
      expect(
        sessions.any((ScheduleSession s) => s.course.id == 2),
        isTrue,
      );
      expect(sessions.first.seance.chapitre, 'Séance ancienne (cours 1)');

      // Statut calculé à partir de l'instant courant.
      expect(
        sessions.first.statusAt(now),
        ScheduleSessionStatus.passed,
      );
    });
  });

  group('Schedule - session complète (router + shell)', () {
    testWidgets('onglet Planning → emploi du temps issu de l\'API simulée',
        (tester) async {
      _setSurface(tester);
      await tester.pumpWidget(_buildFullApp(storedToken: 'fake.jwt.token'));
      await tester.pumpAndSettle();

      await tester.tap(_navLabel('Planning'));
      await tester.pumpAndSettle();

      // Le bandeau « Prochain cours » (séance de fin de journée à venir).
      expect(find.text('Prochain cours'), findsOneWidget);

      // Les deux cours fusionnent dans la timeline du jour sélectionné ;
      // « Réseaux I » apparaît aussi dans le bandeau « Prochain cours ».
      expect(find.text('Algorithmique et Programmation I'), findsOneWidget);
      expect(find.text('Réseaux I'), findsWidgets);
      expect(find.text('Awa Ndiaye'), findsOneWidget);

      // Squelette puis contenu : aucune donnée statique.
      expect(find.text('Aucun cours prévu'), findsNothing);
    });
  });
}

class _StaticRepository implements ScheduleRepository {
  _StaticRepository(this.data);

  final List<ScheduleSession> data;

  @override
  Future<List<ScheduleSession>> fetchSessions() async => data;
}