/// Un cours (prochain cours ou cours à venir) affiché sur le dashboard.
///
/// Modèle typé, conforme à la future réponse de l'API :
/// ```json
/// {
///   "id": 1,
///   "title": "Base de données relationnelles",
///   "icon": "database",
///   "date": "2026-09-16T00:00:00.000Z",
///   "startTime": "10:00",
///   "endTime": "12:00",
///   "room": "B12",
///   "campus": "Campus Fann",
///   "teacherName": "M. Diop",
///   "progress": 75,
///   "nextSessionLabel": "Demain 08h"
/// }
/// ```
class CourseItem {
  const CourseItem({
    required this.id,
    required this.title,
    this.date,
    this.startTime,
    this.endTime,
    this.room,
    this.campus,
    this.teacherName,
    this.progress,
    this.nextSessionLabel,
    this.iconName,
  });

  final int id;
  final String title;

  /// Jour du cours (permet de grouper « Aujourd'hui » / « Demain »).
  final DateTime? date;

  /// Heures au format « HH:mm » (formatées par l'API).
  final String? startTime;
  final String? endTime;

  final String? room;
  final String? campus;
  final String? teacherName;

  /// Progression du cours (0.0 à 100.0), ou `null` tant que le backend
  /// ne fournit aucune progression. L'UI affiche alors un état neutre.
  final double? progress;

  /// Libellé de la prochaine séance (ex. « Demain 08h », « Mercredi »).
  final String? nextSessionLabel;

  /// Nom de l'icône Material (ex. « database », « devices »).
  final String? iconName;

  /// « 10:00 — 12:00 »
  String get timeRange =>
      (startTime?.isNotEmpty ?? false) && (endTime?.isNotEmpty ?? false)
      ? '$startTime — $endTime'
      : '';

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    return CourseItem(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String)
          : null,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      room: json['room'] as String?,
      campus: json['campus'] as String?,
      teacherName: json['teacherName'] as String?,
      progress: (json['progress'] as num?)?.toDouble(),
      nextSessionLabel: json['nextSessionLabel'] as String?,
      iconName: json['iconName'] as String?,
    );
  }
}
