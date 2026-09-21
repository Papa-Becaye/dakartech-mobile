import 'app_exception.dart';

/// Conflit d'horaire de séance remonté par le backend (`409 Conflict`,
/// code métier `SCHEDULE_CONFLICT`).
///
/// Deux séances (même classe, étudiants de la classe ou même enseignant,
/// dans la même année académique) se chevauchent : l'utilisateur doit
/// choisir un autre créneau.
class ScheduleConflictException extends AppException {
  const ScheduleConflictException(
    super.message, {
    this.conflictType,
    this.conflictingSessionId,
    this.reason,
    this.statusCode,
    super.code,
    super.cause,
  });

  /// Type métier du conflit : `CLASSE`, `ETUDIANT` ou `ENSEIGNANT`.
  final String? conflictType;

  /// Identifiant de la séance déjà planifiée sur le créneau.
  final int? conflictingSessionId;

  /// Détail lisible renvoyé par le backend (classe, séance, créneau).
  final String? reason;

  /// Code HTTP (toujours 409 dans ce cas).
  final int? statusCode;
}
