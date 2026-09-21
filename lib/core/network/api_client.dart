import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_config.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/unauthorized_interceptor.dart';

/// Point d'accès centralisé au client HTTP (Dio).
///
/// Fournit un singleton déjà configuré et prêt à l'emploi :
/// base URL, timeouts, intercepteur JWT, gestion des 401 et
/// traduction des erreurs.
class ApiClient {
  ApiClient._();

  static final ApiClient instance = ApiClient._();

  bool _isInitialized = false;

  /// `true` après un appel réussi à [init] (utile aux tests qui
  /// construisent plusieurs applications dans le même process).
  bool get isInitialized => _isInitialized;

  late final Dio dio;

  /// Initialise le client HTTP. À appeler une seule fois au démarrage
  /// de l'application (voir `main.dart`).
  ///
  /// [tokenProvider] renvoie le jeton JWT courant (ou `null`) : branché
  /// sur le [AuthService] qui charge le token depuis le stockage
  /// sécurisé.
  ///
  /// [onUnauthorized] est appelé dès qu'une réponse 401 est reçue
  /// (déconnexion de session). Branché sur [AuthController].
  ///
  /// Idempotent : un second appel est ignoré (protection contre les
  /// doubles initialisations en environnement de test).
  void init({TokenProvider? tokenProvider, VoidCallback? onUnauthorized}) {
    if (_isInitialized) return;
    _isInitialized = true;

    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: ApiConfig.connectTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        contentType: Headers.jsonContentType,
      ),
    );

    dio.interceptors
      ..add(AuthInterceptor(tokenProvider: tokenProvider))
      ..add(ErrorInterceptor())
      ..add(UnauthorizedInterceptor(onUnauthorized: onUnauthorized));
  }
}
