import 'package:dio/dio.dart';

/// Fournit le jeton JWT courant, ou `null` s'il n'y en a pas encore.
///
/// C'est le point d'extension logique pour le gestionnaire de session :
/// il suffira de brancher la lecture du token stocké côté localStorage
/// / secure storage et l'en-tête `Authorization` sera ajouté à chaque
/// requête automatiquement.
typedef TokenProvider = String? Function();

/// Interceptor réseau ajoutant l'en-tête `Authorization: Bearer <jwt>`
/// à chaque requête sortante.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({TokenProvider? tokenProvider})
    : _tokenProvider = tokenProvider;

  final TokenProvider? _tokenProvider;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
