import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstraction du stockage sécurisé du jeton d'accès.
///
/// L'implémentation par défaut utilise [FlutterSecureStorage] qui
/// s'appuie sur le coffre-fort natif (Android Keystore / iOS
/// Keychain). Un mock est disponible pour les tests via
/// [_InMemoryTokenStorage].
abstract class TokenStorage {
  Future<String?> readAccessToken();
  Future<void> writeAccessToken(String token);
  Future<void> deleteAccessToken();
}

/// Stockage sécurisé basé sur la clé publique native.
class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'dakartech_access_token';

  @override
  Future<String?> readAccessToken() {
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<void> writeAccessToken(String token) {
    return _storage.write(key: _accessTokenKey, value: token);
  }

  @override
  Future<void> deleteAccessToken() {
    return _storage.delete(key: _accessTokenKey);
  }
}
