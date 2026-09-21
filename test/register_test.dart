import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:dakartech_mobile/core/errors/app_exception.dart';
import 'package:dakartech_mobile/core/network/api_client.dart';
import 'package:dakartech_mobile/core/routes/app_router.dart';
import 'package:dakartech_mobile/features/auth/controllers/auth_controller.dart';
import 'package:dakartech_mobile/features/auth/data/auth_repository.dart';
import 'package:dakartech_mobile/features/auth/data/auth_service.dart';
import 'package:dakartech_mobile/features/auth/data/token_storage.dart';
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

/// Profil renvoyé par le backend après inscription (rôle ETUDIANT).
const Map<String, Object> _etudiantProfile = {
  'id': 42,
  'nom': 'Dupont',
  'prenom': 'Jean',
  'email': 'jean@exemple.com',
  'role': 'ETUDIANT',
  'createdAt': '2026-09-16T00:00:00.000Z',
};

/// Réponse complète de `POST /auth/register`.
const Map<String, Object> _registerResponse = {
  'accessToken': 'register.jwt.token',
  'refreshToken': 'register.refresh.token',
  'user': _etudiantProfile,
};

/// Comportement du registre simulé pour chaque test.
enum _RegisterScenario {
  /// Succès : 201 + jetons.
  success,

  /// Conflit : compte déjà existant (message backend exposé).
  conflict,

  /// Réseau indisponible.
  networkError,
}

/// Adapter Dio qui répond selon le scénario demandé.
class _FakeDioAdapter implements HttpClientAdapter {
  _FakeDioAdapter(this._scenario);

  final _RegisterScenario _scenario;

  /// Dernière charge utile envoyée à `/auth/register`.
  Map<String, dynamic>? lastRegisterBody;

  static ResponseBody _json(Object payload) {
    return ResponseBody.fromString(
      jsonEncode(payload),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final String path = options.path;

    if (path.endsWith('/auth/register')) {
      if (_scenario == _RegisterScenario.networkError) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'Réseau indisponible',
        );
      }
      if (_scenario == _RegisterScenario.conflict) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          error: const AppException('Un compte existe déjà avec cet email'),
        );
      }
      lastRegisterBody = (options.data as Map).cast<String, dynamic>();
      return _json(_registerResponse);
    }

    if (path.endsWith('/cours/mes-cours')) {
      // Aucun cours pour un étudiant fraîchement inscrit.
      return _json(const <Object>[]);
    }

    if (path.endsWith('/auth/profile')) {
      return _json(_etudiantProfile);
    }

    throw DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      error: const AppException('Route inconnue'),
    );
  }

  @override
  void close({bool force = false}) {}
}

Widget _buildApp(_RegisterScenario scenario) {
  final _FakeDioAdapter adapter = _FakeDioAdapter(scenario);
  final AuthController controller = AuthController(
    AuthService(
      authRepository: AuthRepository(Dio()..httpClientAdapter = adapter),
      tokenStorage: _InMemoryTokenStorage(),
    ),
  );

  // Client HTTP partagé utilisé par la feature « Mes cours » une fois
  // la session démarrée (shell étudiant) — idempotent au sein du fichier.
  if (!ApiClient.instance.isInitialized) {
    ApiClient.instance.init(
      tokenProvider: () => null,
      onUnauthorized: () => controller.handleSessionExpired(),
    );
    ApiClient.instance.dio.httpClientAdapter = adapter;
  }

  return ChangeNotifierProvider<AuthController>.value(
    value: controller,
    child: DakarTechApp(routerConfig: createAppRouter(controller)),
  );
}

/// Remplit le formulaire d'inscription (laisser [confirmText] à null
/// pour reprendre la valeur du mot de passe).
Future<void> _fillForm(
  WidgetTester tester, {
  String nom = 'Dupont',
  String prenom = 'Jean',
  String email = 'jean@exemple.com',
  String password = 'MotDePasse123!',
  String? confirmText,
}) async {
  final Finder fields = find.byType(TextField);
  await tester.enterText(fields.at(0), nom);
  await tester.enterText(fields.at(1), prenom);
  await tester.enterText(fields.at(2), email);
  await tester.enterText(fields.at(3), password);
  await tester.enterText(fields.at(4), confirmText ?? password);
}

Future<void> _openRegisterScreen(WidgetTester tester) async {
  await tester.pumpWidget(_buildApp(_RegisterScenario.success));
  await tester.pumpAndSettle();

  // Navigation automatique : splash → login.
  expect(find.text('Se connecter'), findsOneWidget);

  // Le lien « Créer un compte » est plus bas dans le SingleChildScrollView.
  await tester.ensureVisible(find.text('Créer un compte'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Créer un compte'));
  await tester.pumpAndSettle();
  expect(find.text('Veuillez saisir votre nom.'), findsNothing);
  // L'écran d'inscription est bien affiché.
  expect(find.text('Créer mon compte'), findsOneWidget);
}

/// Rend le bouton de soumission visible puis le tape (le formulaire
/// dépasse le viewport en test).
Future<void> _submitForm(WidgetTester tester) async {
  await tester.ensureVisible(find.text('Créer mon compte'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Créer mon compte'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('champs vides → erreurs de validation locales', (tester) async {
    await _openRegisterScreen(tester);

    await _submitForm(tester);

    expect(find.text('Veuillez saisir votre nom.'), findsOneWidget);
    expect(find.text('Veuillez saisir votre prénom.'), findsOneWidget);
    expect(find.text('Veuillez saisir votre email.'), findsOneWidget);
    expect(find.text('Veuillez saisir un mot de passe.'), findsOneWidget);
    expect(find.text('Veuillez confirmer votre mot de passe.'),
        findsOneWidget);
  });

  testWidgets('email invalide → erreur', (tester) async {
    await _openRegisterScreen(tester);

    await _fillForm(tester, email: 'adresse-invalide');
    await _submitForm(tester);

    expect(find.text("Cet email n'est pas valide."), findsOneWidget);
  });

  testWidgets('mot de passe trop court → erreur', (tester) async {
    await _openRegisterScreen(tester);

    await _fillForm(tester, password: '123');
    await _submitForm(tester);

    expect(
      find.text('Le mot de passe doit contenir au moins 8 caractères.'),
      findsOneWidget,
    );
  });

  testWidgets('confirmation différente → erreur', (tester) async {
    await _openRegisterScreen(tester);

    await _fillForm(tester, password: 'MotDePasse123!', confirmText: 'Autre');
    await _submitForm(tester);

    expect(find.text('Les mots de passe ne correspondent pas.'), findsOneWidget);
  });

  testWidgets(
      'inscription valide → session démarrée + tableau de bord', (tester) async {
    final _FakeDioAdapter adapter =
        _FakeDioAdapter(_RegisterScenario.success);
    final AuthController controller = AuthController(
      AuthService(
        authRepository: AuthRepository(Dio()..httpClientAdapter = adapter),
        tokenStorage: _InMemoryTokenStorage(),
      ),
    );

    if (!ApiClient.instance.isInitialized) {
      ApiClient.instance.init(
        tokenProvider: () => null,
        onUnauthorized: () => controller.handleSessionExpired(),
      );
      ApiClient.instance.dio.httpClientAdapter = adapter;
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthController>.value(
        value: controller,
        child: DakarTechApp(routerConfig: createAppRouter(controller)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    await _fillForm(tester);
    await _submitForm(tester);

    // L'appel réseau a envoyé les bons champs.
    expect(adapter.lastRegisterBody, isNotNull);
    expect(adapter.lastRegisterBody!['nom'], 'Dupont');
    expect(adapter.lastRegisterBody!['prenom'], 'Jean');
    expect(adapter.lastRegisterBody!['email'], 'jean@exemple.com');

    // Session active + redirection vers le dashboard étudiant.
    expect(controller.status.name, 'authenticated');
    expect(find.text('En un coup d\'œil'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('email déjà utilisé → message backend affiché', (tester) async {
    await tester.pumpWidget(_buildApp(_RegisterScenario.conflict));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    await _fillForm(tester);
    await _submitForm(tester);

    expect(find.text('Un compte existe déjà avec cet email'), findsOneWidget);
    // Toujours sur le formulaire, pas de navigation.
    expect(find.text('Créer mon compte'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('réseau indisponible → message générique', (tester) async {
    await tester.pumpWidget(_buildApp(_RegisterScenario.networkError));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Créer un compte'));
    await tester.pumpAndSettle();
    await _fillForm(tester);
    await _submitForm(tester);

    expect(
      find.text(
        'Connexion au serveur impossible. Vérifiez votre connexion internet.',
      ),
      findsOneWidget,
    );
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('retour vers la connexion', (tester) async {
    await _openRegisterScreen(tester);

    await tester.ensureVisible(find.text('J\'ai déjà un compte'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('J\'ai déjà un compte'));
    await tester.pumpAndSettle();

    expect(find.text('Se connecter'), findsOneWidget);
  });
}
