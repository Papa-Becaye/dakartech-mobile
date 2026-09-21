import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dakartech_mobile/core/network/api_client.dart';
import 'package:dakartech_mobile/core/routes/app_router.dart';
import 'package:dakartech_mobile/features/auth/controllers/auth_controller.dart';
import 'package:dakartech_mobile/features/auth/data/auth_repository.dart';
import 'package:dakartech_mobile/features/auth/data/auth_service.dart';
import 'package:dakartech_mobile/features/auth/data/token_storage.dart';
import 'package:dakartech_mobile/main.dart';

/// Stockage de tokens en mémoire (remplace le coffre-fort natif
/// dont le plugin n'est pas disponible en test).
class _InMemoryTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<String?> readAccessToken() async => token;

  @override
  Future<void> writeAccessToken(String value) async => token = value;

  @override
  Future<void> deleteAccessToken() async => token = null;
}

/// Réponse simulée de `GET /auth/profile` (backend NestJS) — rôle étudiant.
const Map<String, Object> _etudiantProfile = {
  'id': 1,
  'nom': 'Dupont',
  'prenom': 'Jean',
  'email': 'jean@exemple.com',
  'role': 'ETUDIANT',
  'createdAt': '2026-09-16T00:00:00.000Z',
};

/// Réponse simulée pour un compte ADMIN (contrôle d'accès par rôle).
const Map<String, Object> _adminProfile = {
  'id': 2,
  'nom': 'Ndiaye',
  'prenom': 'Awa',
  'email': 'awa@exemple.com',
  'role': 'ADMIN',
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

/// Adapter Dio qui répond selon l'endpoint demandé (profil, cours).
class _FakeDioAdapter implements HttpClientAdapter {
  _FakeDioAdapter(this._profilePayload);

  final Map<String, Object> _profilePayload;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String path = options.path;
    final DateTime base = DateTime.now();
    if (path.endsWith('/cours/mes-cours')) {
      return _json(_coursesPayload);
    }
    if (path.endsWith('/cours/1/evaluations')) {
      return _json([
        {
          'id': 20,
          'titre': 'Devoir sur table',
          'date': _iso(DateTime(base.year, base.month, base.day - 30, 9)),
          'type': 'DEVOIR',
          'note': 14.5,
        },
      ]);
    }
    if (path.endsWith('/cours/1/seances')) {
      return _json([
        {
          'id': 9,
          'date': _iso(DateTime(base.year, base.month, base.day - 1, 8)),
          'duree': 2,
          'chapitre': 'Séance 5',
          'contenu': null,
          'presence': {'present': true, 'remarque': null},
        },
      ]);
    }
    if (path.endsWith('/cours/1')) {
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
          'date': _iso(DateTime(base.year, base.month, base.day + 1, 8)),
          'duree': 2,
          'chapitre': 'Séance 6',
          'contenu': null,
        },
      });
    }
    if (path.endsWith('/notes/mes-notes')) {
      return _json({
        'etudiant': {
          'id': 1,
          'matricule': 'DT2025001',
          'prenom': 'Jean',
          'nom': 'Dupont',
          'classe': {
            'id': 1,
            'nom': 'IG1',
            'annee': {'id': 1, 'libelle': '2025-2026'},
          },
        },
        'moyenneGenerale': 13.7,
        'mention': 'Assez bien',
        'matieres': [
          {
            'matiereId': 1,
            'matiere': 'Bases de données',
            'code': 'BD301',
            'coefficient': 3,
            'moyenne': 13.7,
            'evaluationsNotees': 1,
            'evaluations': [
              {
                'id': 20,
                'titre': 'Devoir sur table',
                'date': _iso(
                  DateTime(base.year, base.month, base.day - 30, 9),
                ),
                'type': 'DEVOIR',
                'coursId': 1,
                'cours': 'Bases de données',
                'note': 13.7,
              },
            ],
          },
        ],
      });
    }
    return _json(_profilePayload);
  }

  static ResponseBody _json(Object payload) => ResponseBody.fromString(
        jsonEncode(payload),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  static String _iso(DateTime date) => date.toIso8601String();

  @override
  void close({bool force = false}) {}
}

/// Recherche un libellé dans la barre de navigation inférieure
/// uniquement (les mêmes libellés peuvent exister ailleurs à l'écran).
Finder _navLabel(String label) => find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text(label),
    );

Widget _buildTestApp({
  String? storedToken,
  Map<String, Object>? profilePayload,
}) {
  final _FakeDioAdapter adapter =
      _FakeDioAdapter(profilePayload ?? _etudiantProfile);
  final Dio dio = Dio()..httpClientAdapter = adapter;
  final AuthController authController = AuthController(
    AuthService(
      authRepository: AuthRepository(dio),
      tokenStorage: _InMemoryTokenStorage()
        ..token = (storedToken?.isNotEmpty ?? false) ? storedToken : null,
    ),
  );

  // Initialise le client HTTP partagé (utilisé par les features qui
  // chargent des données réelles, ex. « Mes cours »). Idempotent : une
  // seule fois par fichier. On remplace ensuite son adapter réseau par
  // l'adapter simulé (les tests ne font aucun appel réel).
  if (!ApiClient.instance.isInitialized) {
    ApiClient.instance.init(
      tokenProvider: () => storedToken,
      onUnauthorized: () => authController.handleSessionExpired(),
    );
  }
  ApiClient.instance.dio.httpClientAdapter = adapter;

  return ChangeNotifierProvider<AuthController>.value(
    value: authController,
    child: DakarTechApp(routerConfig: createAppRouter(authController)),
  );
}

void main() {
  testWidgets('sans session → redirection vers le login', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Bienvenue sur DakarTech'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('champs vides → erreurs de validation locales', (tester) async {
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Se connecter'));
    await tester.pumpAndSettle();

    expect(find.text('Veuillez saisir votre email.'), findsOneWidget);
    expect(find.text('Veuillez saisir votre mot de passe.'), findsOneWidget);
  });

  testWidgets('session étudiant valide → shell + tableau de bord',
      (tester) async {
    await tester.pumpWidget(_buildTestApp(storedToken: 'fake.jwt.token'));
    await tester.pumpAndSettle();

    // Dashboard affiché (identité venue de la session).
    expect(find.text('Bonjour, Jean 👋'), findsOneWidget);
    expect(find.text('En un coup d\'œil'), findsOneWidget);

    // Les 5 onglets de la bottom navigation sont présents.
    for (final String label in ['Accueil', 'Cours', 'Planning', 'Notes', 'Profil']) {
      expect(_navLabel(label), findsOneWidget);
    }
  });

  testWidgets('navigation par onglets → retour sur Accueil', (tester) async {
    await tester.pumpWidget(_buildTestApp(storedToken: 'fake.jwt.token'));
    await tester.pumpAndSettle();

    await tester.tap(_navLabel('Cours'));
    await tester.pumpAndSettle();
    // Les cours viennent bien de l'API simulée (aucune donnée statique).
    expect(find.text('Bases de données'), findsOneWidget);
    expect(find.text('Awa Diop'), findsOneWidget);
    expect(find.text('36 h'), findsOneWidget);

    await tester.tap(_navLabel('Planning'));
    await tester.pumpAndSettle();
    // La séance simulée est hier : aujourd'hui n'a aucun cours prévu.
    expect(find.text('Aucun cours prévu'), findsOneWidget);

    await tester.tap(_navLabel('Notes'));
    await tester.pumpAndSettle();
    // Le relevé vient bien de l'API simulée (`/notes/mes-notes`).
    expect(find.text('Notes & évaluations'), findsOneWidget);
    expect(find.text('13,7'), findsOneWidget);
    expect(find.text('Assez bien'), findsOneWidget);

    await tester.tap(_navLabel('Profil'));
    await tester.pumpAndSettle();
    expect(find.text('Vos informations et préférences seront gérées ici.'),
        findsOneWidget);

    await tester.tap(_navLabel('Accueil'));
    await tester.pumpAndSettle();
    expect(find.text('En un coup d\'œil'), findsOneWidget);
  });

  testWidgets('déconnexion depuis le profil → retour au login',
      (tester) async {
    await tester.pumpWidget(_buildTestApp(storedToken: 'fake.jwt.token'));
    await tester.pumpAndSettle();

    await tester.tap(_navLabel('Profil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Se déconnecter'));
    await tester.pumpAndSettle();

    expect(find.text('Se connecter'), findsOneWidget);
  });

  testWidgets('session ADMIN → espace en attente (pas de navigation étudiante)',
      (tester) async {
    await tester.pumpWidget(
      _buildTestApp(
        storedToken: 'fake.admin.token',
        profilePayload: _adminProfile,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Votre espace'), findsWidgets);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('retour système sur l’accueil → confirmation avant de quitter',
      (tester) async {
    await tester.pumpWidget(_buildTestApp(storedToken: 'fake.jwt.token'));
    await tester.pumpAndSettle();

    // Premier appui retour : rien ne quitte, une confirmation est affichée.
    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Appuyer à nouveau pour quitter'), findsOneWidget);
    expect(find.text('En un coup d\'œil'), findsOneWidget);

    // La snackbar se referme d'elle-même après 4 s (nettoie le timer).
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Appuyer à nouveau pour quitter'), findsNothing);
  });
}