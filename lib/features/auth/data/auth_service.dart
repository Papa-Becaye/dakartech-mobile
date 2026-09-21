import '../data/auth_repository.dart';
import '../data/token_storage.dart';
import '../models/auth_response.dart';
import '../models/user_model.dart';

/// Couche service pour l'authentification.
///
/// Orchestre le repository réseau + le stockage sécurisé des tokens.
/// Expose un token provider utilisable par l'intercepteur JWT.
class AuthService {
  AuthService({
    required AuthRepository authRepository,
    required TokenStorage tokenStorage,
  }) : _repository = authRepository,
       _tokenStorage = tokenStorage;

  final AuthRepository _repository;
  final TokenStorage _tokenStorage;

  String? _accessToken;
  UserModel? _currentUser;

  /// Token actuel en mémoire, utilisé par l'intercepteur JWT.
  /// Renvoie `null` si aucun token n'est chargé.
  String? get currentAccessToken => _accessToken;

  /// Utilisateur actuellement en session.
  UserModel? get currentUser => _currentUser;

  /// Tente de restaurer une session à partir du token stocké.
  ///
  /// 1. Lit le token dans le coffre-fort sécurisé.
  /// 2. Appelle `GET /auth/profile` pour valider le token.
  /// 3. Renvoie l'utilisateur si tout est OK, sinon `null`.
  Future<UserModel?> restoreSession() async {
    final String? token = await _tokenStorage.readAccessToken();
    if (token == null) return null;

    _accessToken = token;
    try {
      final UserModel user = await _repository.fetchProfile();
      _currentUser = user;
      return user;
    } catch (_) {
      // Token invalide, expiré ou réseau indisponible : la session
      // est considérée comme expirée.
      await clearSession();
      return null;
    }
  }

  /// Authentifie l'utilisateur via email/mot de passe.
  ///
  /// Stocke le token et met à jour l'utilisateur courant.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final AuthResponse response = await _repository.login(
      email: email,
      password: password,
    );
    return _persistResponse(response);
  }

  /// Crée un compte étudiant via l'API puis démarre la session.
  Future<AuthResponse> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
  }) async {
    final AuthResponse response = await _repository.register(
      email: email,
      password: password,
      nom: nom,
      prenom: prenom,
    );
    return _persistResponse(response);
  }

  /// Sauvegarde la session (token + utilisateur) après un login/register.
  Future<AuthResponse> _persistResponse(AuthResponse response) async {
    _accessToken = response.accessToken;
    _currentUser = response.user;
    await _tokenStorage.writeAccessToken(response.accessToken);
    return response;
  }

  /// Détruit la session locale (token + utilisateur).
  Future<void> clearSession() async {
    _accessToken = null;
    _currentUser = null;
    await _tokenStorage.deleteAccessToken();
  }

  /// Envoie un lien de réinitialisation de mot de passe.
  Future<void> sendPasswordResetLink(String email) {
    return _repository.sendPasswordResetLink(email);
  }
}
