import 'dart:async';

import 'package:flutter/foundation.dart';

import '../data/auth_service.dart';
import '../data/auth_status.dart';
import '../models/user_model.dart';

/// Gestionnaire d'état de la session utilisateur.
///
/// Machine à états : unknown → checking → authenticated | unauthenticated.
///
/// Conçu pour être passé à [GoRouter.refreshListenable] afin que la
/// navigation se réévalue automatiquement à chaque changement d'état.
/// Aucune variable globale : l'état est entièrement porté par
/// cette instance, fournie par [ChangeNotifierProvider].
class AuthController extends ChangeNotifier {
  AuthController(this._service);

  final AuthService _service;

  AuthStatus _status = AuthStatus.unknown;
  bool _initialized = false;

  AuthStatus get status => _status;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isInitialized => _initialized;
  UserModel? get currentUser => _service.currentUser;

  /// Vérifie la session au démarrage de l'application.
  ///
  /// Appelée une seule fois depuis l'écran splash.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    _status = AuthStatus.checking;
    notifyListeners();

    final UserModel? user = await _service.restoreSession();
    _status = user != null
        ? AuthStatus.authenticated
        : AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Authentifie l'utilisateur et passe en session.
  ///
  /// Propage les exceptions réseau vers l'appelant (l'écran UI)
  /// afin d'afficher un message utilisateur adapté.
  Future<void> login(String email, String password) async {
    await _service.login(email: email, password: password);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Crée un compte étudiant et démarre la session.
  Future<void> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
  }) async {
    await _service.register(
      nom: nom,
      prenom: prenom,
      email: email,
      password: password,
    );
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Détruit la session et redirige vers la connexion.
  Future<void> logout() async {
    await _service.clearSession();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Appelé par l'interceptor réseau en cas de 401 (token expiré).
  void handleSessionExpired() {
    if (_status != AuthStatus.authenticated) return;
    unawaited(logout());
  }

  /// Appelé par le forgot-password screen (délègue au service).
  Future<void> sendPasswordResetLink(String email) {
    return _service.sendPasswordResetLink(email);
  }
}
