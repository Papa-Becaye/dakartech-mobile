import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dakartech_mobile/core/errors/api_exception.dart';
import 'package:dakartech_mobile/core/network/api_client.dart';
import 'package:dakartech_mobile/core/routes/app_router.dart';
import 'package:dakartech_mobile/core/theme/app_theme.dart';
import 'package:dakartech_mobile/features/auth/controllers/auth_controller.dart';
import 'package:dakartech_mobile/features/auth/data/auth_repository.dart';
import 'package:dakartech_mobile/features/auth/data/auth_service.dart';
import 'package:dakartech_mobile/features/auth/data/token_storage.dart';
import 'package:dakartech_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:dakartech_mobile/features/dashboard/models/course_item.dart';
import 'package:dakartech_mobile/features/dashboard/models/dashboard_data.dart';
import 'package:dakartech_mobile/features/dashboard/models/dashboard_statistics.dart';
import 'package:dakartech_mobile/features/dashboard/screens/dashboard_screen.dart';
import 'package:dakartech_mobile/features/dashboard/widgets/courses_section.dart';
import 'package:dakartech_mobile/features/dashboard/widgets/quick_actions_section.dart';
import 'package:dakartech_mobile/main.dart';

/// Stockage de tokens en mémoire pour les tests.
class _InMemoryTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<String?> readAccessToken() async => token;
  @override
  Future<void> writeAccessToken(String value) async => token = value;
  @override
  Future<void> deleteAccessToken() async => token = null;
}

/// Profil étudiant utilisé par les tests full-app.
const Map<String, Object> _etudiantProfile = {
  'id': 1,
  'nom': 'Dupont',
  'prenom': 'Jean',
  'email': 'jean@exemple.com',
  'role': 'ETUDIANT',
  'createdAt': '2026-09-16T00:00:00.000Z',
};

/// Réponse simulée pour `GET /cours/mes-cours` (backend NestJS).
const List<Map<String, Object>> _coursesPayload = [
  {
    'id': 1,
    'titre': 'Bases de données',
    'volumeHoraire': 36,
    'matiere': {
      'id': 1,
      'nom': 'Base de données',
      'code': 'BD301',
      'coefficient': 3,
    },
    'enseignant': {'id': 1, 'nom': 'Diop', 'prenom': 'Awa'},
  },
];

DateTime _at(DateTime base, int dayOffset, int hour) =>
    DateTime(base.year, base.month, base.day + dayOffset, hour);

String _iso(DateTime date) => date.toIso8601String();

/// Adapter Dio qui simule le backend NestJS : profil utilisateur, cours
/// de l'étudiant, détail (classe + prochaine séance), séances et
/// évaluations — la chaîne complète utilisée par le dashboard réel.
class _FakeDioAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final DateTime base = DateTime.now();

    if (options.path.endsWith('/presences/mon-assiduite')) {
      return _json(_monAssiduitePayload());
    }
    if (options.path.endsWith('/cours/mes-cours')) {
      return _json(_coursesPayload);
    }
    if (options.path.endsWith('/cours/1/evaluations')) {
      return _json([
        {
          'id': 20,
          'titre': 'Devoir sur table',
          'date': _iso(_at(base, -30, 9)),
          'type': 'DEVOIR',
          'note': 14.5,
        },
      ]);
    }
    if (options.path.endsWith('/cours/1/seances')) {
      return _json([
        {
          'id': 9,
          'date': _iso(_at(base, -1, 8)),
          'duree': 2,
          'chapitre': 'Séance 5',
          'contenu': null,
          'presence': {'present': true, 'remarque': null},
        },
        {
          'id': 8,
          'date': _iso(_at(base, -14, 8)),
          'duree': 2,
          'chapitre': 'Séance 4',
          'contenu': null,
          'presence': {'present': false, 'remarque': 'Absent(e)'},
        },
      ]);
    }
    if (options.path.endsWith('/cours/1')) {
      return _json({
        'id': 1,
        'titre': 'Bases de données',
        'volumeHoraire': 36,
        'matiere': {
          'id': 1,
          'nom': 'Base de données',
          'code': 'BD301',
          'coefficient': 3,
        },
        'enseignant': {'id': 1, 'nom': 'Diop', 'prenom': 'Awa'},
        'classe': {
          'id': 1,
          'nom': 'IG1',
          'filiere': {'id': 1, 'nom': 'Informatique de Gestion'},
          'annee': {'id': 1, 'libelle': '2025-2026', 'active': true},
        },
        'prochaineSeance': {
          'id': 10,
          'date': _iso(_at(base, 1, 8)),
          'duree': 2,
          'chapitre': 'Séance 6',
          'contenu': null,
        },
      });
    }
    return _json(_etudiantProfile);
  }

  Map<String, Object> _monAssiduitePayload() {
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
            'titre': 'Bases de données',
            'classe': {'id': 1, 'nom': 'IG1'},
            'matiere': {'id': 1, 'nom': 'Base de données'},
            'enseignant': {'id': 1, 'nom': 'Diop', 'prenom': 'Awa'},
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
            'titre': 'Bases de données',
            'classe': {'id': 1, 'nom': 'IG1'},
            'matiere': {'id': 1, 'nom': 'Base de données'},
            'enseignant': {'id': 1, 'nom': 'Diop', 'prenom': 'Awa'},
          },
        },
        'autorise': true,
        'fait': false,
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

// ---------------------------------------------------------------------------
// Jeux de données du dashboard (agrégats conformes aux modèles réels)
// ---------------------------------------------------------------------------

enum _DashboardVariant { full, withoutNextCourse, emptySchedule }

/// Repository de substitution pour les tests d'interface : renvoie des
/// [DashboardData] construits à partir de données représentatives du
/// backend (même forme que l'agrégation réelle d'[ApiDashboardRepository]).
class _FakeDashboardRepository implements DashboardRepository {
  const _FakeDashboardRepository({this.variant = _DashboardVariant.full});

  final _DashboardVariant variant;

  @override
  Future<DashboardData> fetchDashboard() async {
    return switch (variant) {
      _DashboardVariant.full => _fullData(),
      _DashboardVariant.withoutNextCourse => _withoutNextCourseData(),
      _DashboardVariant.emptySchedule => _emptyData(),
    };
  }
}

/// Variante complète : identité, statistiques, prochain cours et cours.
DashboardData _fullData() {
  final DateTime tomorrow = _at(DateTime.now(), 1, 0);
  return DashboardData(
    classLevel: 'IG1',
    formation: 'Informatique de Gestion',
    academicYear: '2025-2026',
    statistics: const DashboardStatistics(
      todaySessions: 2,
      attendanceRate: 92,
      average: 15.4,
      unjustifiedAbsences: 1,
    ),
    nextCourse: CourseItem(
      id: 2,
      title: 'Mathématiques I',
      date: tomorrow,
      startTime: '08:00',
      endTime: '10:00',
      teacherName: 'Awa Ndiaye',
    ),
    courses: const [
      CourseItem(
        id: 1,
        title: 'Algorithmique et Programmation I',
        teacherName: 'Mamadou Diop',
        nextSessionLabel: 'Demain 08:00',
      ),
      CourseItem(
        id: 2,
        title: 'Mathématiques I',
        teacherName: 'Awa Ndiaye',
        nextSessionLabel: 'Demain 08:00',
      ),
      CourseItem(
        id: 3,
        title: 'Réseaux I',
        teacherName: 'Mamadou Diop',
        nextSessionLabel: 'Jeudi 14:00',
      ),
    ],
  );
}

/// Aucun prochain cours (le reste reste inchangé).
DashboardData _withoutNextCourseData() {
  final DashboardData base = _fullData();
  return DashboardData(
    classLevel: base.classLevel,
    formation: base.formation,
    academicYear: base.academicYear,
    statistics: base.statistics,
    nextCourse: null,
    courses: base.courses,
  );
}

/// Aucun cours programmé (ni prochain, ni liste).
DashboardData _emptyData() {
  return DashboardData(
    academicYear: '',
    statistics: DashboardStatistics.empty,
    nextCourse: null,
    courses: const [],
  );
}

/// Compteur d'appels (vérifie le nombre de fetch).
class _CountingRepository implements DashboardRepository {
  int calls = 0;

  @override
  Future<DashboardData> fetchDashboard() async {
    calls++;
    return _fullData();
  }
}

/// Lance une exception lors du premier appel, puis renvoie des données.
class _ThenSucceedRepository implements DashboardRepository {
  bool _failed = false;

  @override
  Future<DashboardData> fetchDashboard() async {
    if (!_failed) {
      _failed = true;
      throw const ApiException('Connexion impossible.');
    }
    return _fullData();
  }
}

/// Toujours en erreur (test de perte de connexion).
class _AlwaysFailRepository implements DashboardRepository {
  @override
  Future<DashboardData> fetchDashboard() async {
    throw const ApiException('Connexion impossible.');
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

AuthController _buildAuth() {
  return AuthController(
    AuthService(
      authRepository: AuthRepository(
        Dio()..httpClientAdapter = _FakeDioAdapter(),
      ),
      tokenStorage: _InMemoryTokenStorage(),
    ),
  );
}

Widget _wrapWithProvider(Widget child, {AuthController? auth}) {
  return ChangeNotifierProvider<AuthController>.value(
    value: auth ?? _buildAuth(),
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );
}

/// Construit l'application complète (router + shell + dashboard).
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

  // Client HTTP partagé utilisé par les features (`ApiClient`). Son
  // adapter simulé remplace le réseau réel pour tous les appels du
  // dashboard, y compris ceux issus de `buildCoursesRepository()`.
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

/// Défile jusqu'au bas du dashboard pour construire les sections
/// (ListView paresseuse), puis rend la cible visible et la tape.
Future<void> _revealAndTap(WidgetTester tester, Finder finder) async {
  await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
  await tester.pumpAndSettle();
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('Dashboard - données', () {
    testWidgets('cas 1 : données complètes → toutes les sections',
        (tester) async {
      _setSurface(tester);
      await tester.pumpWidget(
        _wrapWithProvider(
          const DashboardScreen(
            repository: _FakeDashboardRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Carte de bienvenue (fallback sans user injecté) : identité et
      // classe réelles portées par l'agrégat du dashboard.
      expect(find.text('Bonjour 👋'), findsOneWidget);
      expect(find.textContaining('IG1'), findsOneWidget);
      expect(find.textContaining('2025-2026'), findsOneWidget);

      // Le banner est absent : le backend ne fournit aucun contenu.
      expect(find.text("Semaine d'évaluations continues"), findsNothing);

      // Statistiques (valeurs dérivées des présences/notes réelles).
      expect(find.text('En un coup d\'œil'), findsOneWidget);
      expect(find.text('Séances de cours'), findsOneWidget);
      expect(find.text('Présence'), findsOneWidget);
      expect(find.text('Moyenne'), findsOneWidget);
      expect(find.text('Assiduité'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('92%'), findsOneWidget);
      expect(find.text('15,4 /20'), findsOneWidget);

      // Prochain cours (date/heure réelles du planning).
      expect(find.text('Prochain cours'), findsOneWidget);
      expect(find.text('08:00 — 10:00'), findsOneWidget);
      expect(find.text('Voir le cours'), findsOneWidget);
      expect(find.text('Mathématiques I'), findsNWidgets(2));

      // Mes cours (liste réelle, nombre d'UEs calculé).
      expect(find.text('Mes cours'), findsOneWidget);
      expect(find.text('3 UEs'), findsOneWidget);
      expect(find.text('Tout afficher'), findsOneWidget);
      expect(find.text('Algorithmique et Programmation I'), findsOneWidget);
      expect(find.text('Réseaux I'), findsOneWidget);

      // Actions rapides.
      expect(find.text('Actions rapides'), findsOneWidget);
      expect(find.text('Émarger'), findsOneWidget);
      expect(find.text('Ressources'), findsOneWidget);
      expect(find.text('Scolarité'), findsOneWidget);
    });

    testWidgets('cas 2 : aucun prochain cours', (tester) async {
      _setSurface(tester);
      await tester.pumpWidget(
        _wrapWithProvider(
          const DashboardScreen(
            repository: _FakeDashboardRepository(
              variant: _DashboardVariant.withoutNextCourse,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Un état vide explicite remplace la carte du prochain cours.
      expect(
        find.text('Aucun prochain cours programmé'),
        findsOneWidget,
      );

      // Les cours restent affichés.
      expect(find.text('Mes cours'), findsOneWidget);
      expect(find.text('Algorithmique et Programmation I'), findsOneWidget);
    });

    testWidgets('cas 3 : aucun cours → états vides neutres', (tester) async {
      _setSurface(tester);
      await tester.pumpWidget(
        _wrapWithProvider(
          const DashboardScreen(
            repository: _FakeDashboardRepository(
              variant: _DashboardVariant.emptySchedule,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Aucun prochain cours programmé'), findsOneWidget);
      expect(find.text('Aucun cours à afficher'), findsOneWidget);

      // Statistiques neutres : aucune valeur fictive.
      expect(find.text('—'), findsNWidgets(2));
    });

    testWidgets('cas 4 : erreur API → message + Réessayer', (tester) async {
      await tester.pumpWidget(
        _wrapWithProvider(
          DashboardScreen(repository: _AlwaysFailRepository()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Impossible de charger vos données.'), findsOneWidget);
      expect(find.text('Réessayer'), findsOneWidget);

      // Le message technique ne doit pas apparaître.
      expect(
        find.text('Connexion impossible.'),
        findsNothing,
      );
    });

    testWidgets(
        'cas 5 : erreur puis succès via Réessayer → affiche les données',
        (tester) async {
      final _ThenSucceedRepository repo = _ThenSucceedRepository();

      await tester.pumpWidget(
        _wrapWithProvider(DashboardScreen(repository: repo)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Impossible de charger vos données.'), findsOneWidget);

      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(find.text('En un coup d\'œil'), findsOneWidget);
    });

    testWidgets('cas 6 : pull-to-refresh recharge les données',
        (tester) async {
      final _CountingRepository repo = _CountingRepository();

      await tester.pumpWidget(
        _wrapWithProvider(DashboardScreen(repository: repo)),
      );
      await tester.pumpAndSettle();
      expect(repo.calls, 1);

      await tester.fling(
        find.byType(ListView),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();
      expect(repo.calls, 2);
      expect(find.text('En un coup d\'œil'), findsOneWidget);
    });
  });

  group('Dashboard - responsive', () {
    testWidgets('cas 7 : petit écran', (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrapWithProvider(
          const DashboardScreen(repository: _FakeDashboardRepository()),
        ),
      );
      await tester.pumpAndSettle();

      // Les sections sont rendues (scroll vers le bas).
      expect(find.text('En un coup d\'œil'), findsOneWidget);
    });

    testWidgets('cas 8 : grand écran', (tester) async {
      tester.view.physicalSize = const Size(700, 1500);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        _wrapWithProvider(
          const DashboardScreen(repository: _FakeDashboardRepository()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('En un coup d\'œil'), findsOneWidget);
    });
  });

  group('Dashboard - session', () {
    testWidgets('cas 9 : session expirée → retour au login', (tester) async {
      await tester.pumpWidget(_buildFullApp(storedToken: 'fake.jwt.token'));
      await tester.pumpAndSettle();

      expect(find.text('En un coup d\'œil'), findsOneWidget);

      // Simule un 401 via le mécanisme existant (logout + redirection).
      tester
          .element(find.text('En un coup d\'œil'))
          .read<AuthController>()
          .handleSessionExpired();
      await tester.pumpAndSettle();

      expect(find.text('Se connecter'), findsOneWidget);
    });
  });

  group('Dashboard - navigation (cas 10)', () {
    Finder navTab(String label) => find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        );

    Finder quickAction(String label) => find.descendant(
          of: find.byType(QuickActionsSection),
          matching: find.text(label),
        );

    testWidgets('action rapide : Émarger → route Présences', (tester) async {
      await tester.pumpWidget(_buildFullApp(storedToken: 'fake.jwt.token'));
      await tester.pumpAndSettle();

      await _revealAndTap(tester, quickAction('Émarger'));

      // L'écran réel s'affiche (émargement branché sur l'API).
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Présences'),
        ),
        findsOneWidget,
      );
      expect(find.text('Émarger ma présence'), findsOneWidget);
    });

    testWidgets('Mes cours : Tout afficher → onglet Cours', (tester) async {
      await tester.pumpWidget(_buildFullApp(storedToken: 'fake.jwt.token'));
      await tester.pumpAndSettle();

      final Finder toutAfficher = find.descendant(
        of: find.byType(CoursesSection),
        matching: find.text('Tout afficher'),
      );
      await _revealAndTap(tester, toutAfficher);

      // Le cours affiché vient de l'API simulée de la feature « Mes cours ».
      expect(find.text('Bases de données'), findsOneWidget);
      expect(find.text('BD301'), findsOneWidget);
    });

    testWidgets('cloche Notifications → route Notifications', (tester) async {
      await tester.pumpWidget(_buildFullApp(storedToken: 'fake.jwt.token'));
      await tester.pumpAndSettle();

      // Cloche dans le header (StudentAppBar).
      await tester.tap(find.byTooltip('Notifications').first);
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsWidgets);
    });

    testWidgets('onglet Profil → puis retour Accueil', (tester) async {
      await tester.pumpWidget(_buildFullApp(storedToken: 'fake.jwt.token'));
      await tester.pumpAndSettle();

      await tester.tap(navTab('Profil'));
      await tester.pumpAndSettle();
      expect(find.text('Mon profil'), findsOneWidget);

      await tester.tap(navTab('Accueil'));
      await tester.pumpAndSettle();
      expect(find.text('En un coup d\'œil'), findsOneWidget);
    });
  });
}