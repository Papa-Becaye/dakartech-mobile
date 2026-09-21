import 'package:dio/dio.dart';

import '../../errors/api_exception.dart';
import '../../errors/app_exception.dart';
import '../../errors/attendance_exception.dart';
import '../../errors/schedule_conflict_exception.dart';

/// Interceptor réseau traduisant les erreurs réseau/HTTP en
/// [ApiException] portées par la propriété `error` de la [DioException].
///
/// C'est le point unique de traduction des messages d'erreur : les
/// écrans ne gèrent jamais les raw [DioException], mais lisent
/// `e.error` (une [ApiException]) avec un message lisible.
class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.error is ApiException) {
      handler.next(err);
      return;
    }

    final AppException apiException = _map(err);
    handler.next(
      DioException(
        requestOptions: err.requestOptions,
        type: err.type,
        error: apiException,
        stackTrace: err.stackTrace,
      ),
    );
  }

  AppException _map(DioException err) {
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(
          'Le serveur met trop de temps à répondre. Veuillez réessayer.',
          code: 'timeout',
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return const ApiException(
          'Connexion au serveur impossible. Vérifiez votre connexion internet.',
          code: 'connection',
        );
      case DioExceptionType.badCertificate:
        return const ApiException(
          'La connexion est sécurisée de façon invalide.',
          code: 'bad_certificate',
        );
      case DioExceptionType.cancel:
        return const ApiException('Requête annulée.', code: 'cancel');
      case DioExceptionType.badResponse:
        return _mapResponse(err);
    }
  }

  AppException _mapResponse(DioException err) {
    // Conflit d'horaire métier (409 SCHEDULE_CONFLICT) : on renvoie une
    // exception typée portable pour que l'UI puisse afficher le créneau
    // en conflit, sans exposer le JSON brut du backend.
    final ScheduleConflictException? scheduleConflict = _mapScheduleConflict(
      err,
    );
    if (scheduleConflict != null) return scheduleConflict;

    final AttendanceException? attendanceConflict = _mapAttendanceConflict(err);
    if (attendanceConflict != null) return attendanceConflict;

    final int statusCode = err.response?.statusCode ?? 0;
    final String? serverMessage = _extractServerMessage(err.response?.data);

    final String message = switch (statusCode) {
      400 => serverMessage ?? 'La requête est invalide.',
      401 =>
        serverMessage ?? 'Votre session a expiré. Veuillez vous reconnecter.',
      403 => serverMessage ?? 'Vous n\'avez pas accès à cette ressource.',
      404 => serverMessage ?? 'Ressource introuvable.',
      409 => serverMessage ?? 'Conflit avec les données existantes.',
      422 => serverMessage ?? 'Les données envoyées sont invalides.',
      >= 500 =>
        serverMessage ??
            'Une erreur serveur est survenue. Réessayez plus tard.',
      _ => serverMessage ?? 'Une erreur inattendue est survenue.',
    };

    return ApiException(
      message,
      code: statusCode == 0 ? null : '$statusCode',
      statusCode: statusCode == 0 ? null : statusCode,
      cause: err,
    );
  }

  /// Reconnaît une réponse `409` portant le code métier
  /// `SCHEDULE_CONFLICT` et la traduit en [ScheduleConflictException].
  ScheduleConflictException? _mapScheduleConflict(DioException err) {
    if (err.response?.statusCode != 409) return null;
    final Object? data = err.response?.data;
    if (data is! Map || data['code'] != 'SCHEDULE_CONFLICT') return null;

    final Object? conflictingSessionId = data['conflictingSessionId'];
    final String? reason = data['reason'] is String
        ? data['reason'] as String
        : null;

    return ScheduleConflictException(
      reason ??
          (data['message'] is String && (data['message'] as String).isNotEmpty
              ? data['message'] as String
              : 'Ce créneau est déjà occupé par une autre séance.'),
      conflictType: data['conflictType'] is String
          ? data['conflictType'] as String
          : null,
      conflictingSessionId: conflictingSessionId is num
          ? conflictingSessionId.toInt()
          : null,
      reason: reason,
      code: 'SCHEDULE_CONFLICT',
      statusCode: 409,
      cause: err,
    );
  }

  /// Reconnaît une réponse `409` portant un code métier d'émargement
  /// (`ATTENDANCE_ALREADY_RECORDED` / `ATTENDANCE_WINDOW_CLOSED`) et la
  /// traduit en [AttendanceException].
  AttendanceException? _mapAttendanceConflict(DioException err) {
    if (err.response?.statusCode != 409) return null;
    final Object? data = err.response?.data;
    if (data is! Map) return null;

    final AttendanceConflictCode? kind = AttendanceConflictCode.fromApi(
      data['code'] as String?,
    );
    if (kind == null) return null;

    final String message =
        _extractServerMessage(data) ??
        (kind == AttendanceConflictCode.alreadyRecorded
            ? 'Vous avez déjà émargé votre présence à cette séance.'
            : "L'émargement n'est pas disponible pour cette séance.");

    return AttendanceException(
      message,
      kind: kind,
      statusCode: 409,
      code: kind.apiValue,
      cause: err,
    );
  }

  /// Tente d'extraire un message lisible renvoyé par le backend.
  ///
  /// Gère à la fois `message: "string"` et `message: ["err1", "err2"]`
  /// (tableau produit par la validation NestJS class-validator).
  String? _extractServerMessage(Object? data) {
    if (data is! Map) return null;
    final Object? message = data['message'];
    if (message is String && message.isNotEmpty) return message;
    if (message is List && message.isNotEmpty) {
      final Object? first = message.first;
      if (first is String && first.isNotEmpty) return first;
    }
    return null;
  }
}
