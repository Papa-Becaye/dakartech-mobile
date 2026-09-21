import 'app_exception.dart';

/// Code métier d'un refus d'émargement remonté par le backend (`409`).
enum AttendanceConflictCode {
  /// Déjà émargé à cette séance (contrainte unique).
  alreadyRecorded('ATTENDANCE_ALREADY_RECORDED'),

  /// Fenêtre `[date, date + duree)` non ouverte (future ou terminée).
  windowClosed('ATTENDANCE_WINDOW_CLOSED');

  const AttendanceConflictCode(this.apiValue);

  /// Valeur envoyée par l'API.
  final String apiValue;

  static AttendanceConflictCode? fromApi(String? value) {
    if (value == null) return null;
    for (final AttendanceConflictCode code in values) {
      if (code.apiValue == value) return code;
    }
    return null;
  }
}

/// Refus d'émargement de présence (`409 Conflict`, code métier
/// `ATTENDANCE_ALREADY_RECORDED` ou `ATTENDANCE_WINDOW_CLOSED`).
///
/// Permet à l'UI d'adapter le message — elle garde l'état « déjà émargé »
/// au lieu de proposer un bouton inutile, ou indique que la séance n'est
/// pas émargeable à cet instant.
class AttendanceException extends AppException {
  const AttendanceException(
    super.message, {
    this.kind,
    this.statusCode,
    super.code,
    super.cause,
  });

  /// Raison métier précise du refus (jamais `null` sur ce type).
  final AttendanceConflictCode? kind;

  /// Code HTTP (toujours 409 dans ce cas).
  final int? statusCode;
}
