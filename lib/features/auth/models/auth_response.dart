import 'jwt_utils.dart';
import 'user_model.dart';

/// Réponse brute de l'API lors d'un login ou register.
///
/// Le backend renvoie :
/// ```json
/// { "accessToken": "...", "user": { ... } }
/// ```
/// Le backend actuel ne fournit pas de refresh token ni de date
/// d'expiration dans la réponse (le champ [refreshToken] est
/// nullable et prêt à être branché lorsqu'il sera ajouté).
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.user,
    this.refreshToken,
    this.accessTokenExpiry,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime? accessTokenExpiry;
  final UserModel user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final String token = json['accessToken'] as String;
    return AuthResponse(
      accessToken: token,
      refreshToken: json['refreshToken'] as String?,
      accessTokenExpiry: jwtExpiry(token),
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}
