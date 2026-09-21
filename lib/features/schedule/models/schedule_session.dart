import '../../courses/data/models/course_detail.dart';
import '../../courses/data/models/course_model.dart';

/// Statut d'une séance par rapport à l'heure actuelle.
enum ScheduleSessionStatus {
  /// Séance passée (fin < maintenant).
  passed,

  /// Séance en cours (début ≤ maintenant ≤ fin).
  ongoing,

  /// Séance à venir (début > maintenant).
  upcoming,
}

/// Une séance de l'emploi du temps, fusion d'un [Course] et d'une
/// [CourseSeance] issus de l'API réelle (`GET /cours/mes-cours` puis
/// `GET /cours/:id/seances`).
///
/// L'heure de début est la date de la séance en heure locale ; l'heure de
/// fin est déduite de la durée (en heures) stockée par le backend.
/// Aucune donnée fictive n'est ajoutée (pas de salle, pas de campus).
class ScheduleSession {
  const ScheduleSession({required this.course, required this.seance});

  final Course course;
  final CourseSeance seance;

  /// Dates sans la partie horaire, pour comparer des jours précisément.
  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Heure de début réelle (locale) de la séance.
  DateTime get start => seance.date.toLocal();

  /// Heure de fin déduite de la durée.
  DateTime get end => start.add(Duration(hours: seance.duree));

  /// « 09h00 » / « 09h00 — 11h00 » selon la durée disponible.
  String get timeRangeLabel {
    final String startHour =
        '${start.hour.toString().padLeft(2, '0')}'
        'h${start.minute.toString().padLeft(2, '0')}';
    if (seance.duree <= 0) return startHour;
    final String endHour =
        '${end.hour.toString().padLeft(2, '0')}'
        'h${end.minute.toString().padLeft(2, '0')}';
    return '$startHour — $endHour';
  }

  /// Nom de l'enseignant (« Awa Diop »), si présent.
  String? get teacherName => course.enseignant?.fullName;

  /// Statut de la séance au moment [now].
  ScheduleSessionStatus statusAt(DateTime now) {
    if (now.isBefore(start)) return ScheduleSessionStatus.upcoming;
    if (now.isAfter(end)) return ScheduleSessionStatus.passed;
    return ScheduleSessionStatus.ongoing;
  }
}
