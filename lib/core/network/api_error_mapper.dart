import 'package:dio/dio.dart';

import '../errors/api_exception.dart';
import '../errors/app_exception.dart';

/// Traduit une erreur réseau en [AppException] lisible.
///
/// L'`ErrorInterceptor` enveloppe l'[ApiException] dans la propriété
/// `error` de la [DioException]. Les repositories utilisent cette
/// fonction pour la ré-extraire et propager une [AppException] vers
/// la couche UI — qui ne doit jamais manipuler de [DioException].
AppException mapDioError(Object thrown) {
  if (thrown is DioException) {
    final Object? mapped = thrown.error;
    if (mapped is AppException) return mapped;
    return ApiException(
      'Connexion au serveur impossible. Vérifiez votre connexion internet.',
      cause: thrown,
    );
  }
  if (thrown is AppException) return thrown;
  return ApiException(
    'Une erreur est survenue. Veuillez réessayer.',
    cause: thrown,
  );
}
