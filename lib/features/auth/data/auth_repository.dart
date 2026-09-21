import 'package:dio/dio.dart';

import '../../../core/network/api_error_mapper.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';
import 'auth_endpoints.dart';

/// Couche accès réseau pour l'authentification.
///
/// Ne contient aucune logique métier, ne gère pas les tokens.
/// Traduit toutes les erreurs réseau en [AppException] via
/// [mapDioError] afin que l'UI ne manipule jamais de [DioException].
class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  /// POST /auth/login
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        AuthEndpoints.login,
        data: <String, Object?>{'email': email, 'password': password},
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
    return AuthResponse.fromJson(response.data!);
  }

  /// POST /auth/register
  ///
  /// Réponse de même forme que le login : l'utilisateur créé (rôle
  /// ETUDIANT côté backend) + les jetons de session.
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
  }) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        AuthEndpoints.register,
        data: <String, Object?>{
          'email': email,
          'password': password,
          'nom': nom,
          'prenom': prenom,
        },
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
    return AuthResponse.fromJson(response.data!);
  }

  /// GET /auth/profile  (requiert Bearer token)
  Future<UserModel> fetchProfile() async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.get<Map<String, dynamic>>(AuthEndpoints.profile);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
    return UserModel.fromJson(response.data!);
  }

  /// POST /auth/forgot-password
  ///
  /// Endpoint pas encore exposé par le backend. L'appel sera réel
  /// dès qu'il sera implémenté côté NestJS.
  Future<void> sendPasswordResetLink(String email) async {
    try {
      await _dio.post(
        AuthEndpoints.forgotPassword,
        data: <String, Object?>{'email': email},
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}
