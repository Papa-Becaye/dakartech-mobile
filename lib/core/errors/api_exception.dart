import 'app_exception.dart';

/// Exception liée aux appels réseau (API).
///
/// Convertie par l'interceptor réseau à partir des [DioException]s
/// pour fournir un message cohérent et un code HTTP exploitable.
class ApiException extends AppException {
  const ApiException(super.message, {super.code, super.cause, this.statusCode});

  /// Code HTTP renvoyé par le serveur, si disponible.
  final int? statusCode;
}
