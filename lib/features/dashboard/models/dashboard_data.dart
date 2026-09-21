import '../../auth/models/user_model.dart';
import 'course_item.dart';
import 'dashboard_statistics.dart';

/// Agrégat du dashboard étudiant.
///
/// Modèle typé regroupant toutes les informations affichées :
/// ```json
/// {
///   "student": { ... },
///   "formation": "Master 2 — Informatique",
///   "classLevel": "Licence 3 Informatique",
///   "academicYear": "2026 — 2027",
///   "statistics": { ... },
///   "nextCourse": { ... },
///   "courses": [ ... ],
///   "bannerTitle": "Semaine d'évaluations continues",
///   "bannerSubtitle": "3 rendus programmés cette semaine. Bon courage !"
/// }
/// ```
class DashboardData {
  const DashboardData({
    this.student,
    this.formation,
    this.classLevel,
    required this.academicYear,
    required this.statistics,
    this.nextCourse,
    this.courses = const [],
    this.bannerTitle,
    this.bannerSubtitle,
  });

  /// Étudiant. Si présent, sert de repli lorsque la session n'est pas
  /// encore chargée côté API (l'identité de base vient d'[AuthController]).
  final UserModel? student;

  /// Formation / classe (ex. « Master 2 — Informatique »).
  final String? formation;

  /// Niveau de classe (ex. « Licence 3 Informatique »).
  final String? classLevel;

  /// Année académique (ex. « 2026 — 2027 »).
  final String academicYear;

  final DashboardStatistics statistics;

  /// Prochain cours, ou `null` si aucun cours n'est programmé.
  final CourseItem? nextCourse;

  /// Cours suivants avec progression.
  final List<CourseItem> courses;

  /// Titre du banner motivationnel.
  final String? bannerTitle;

  /// Sous-titre du banner motivationnel.
  final String? bannerSubtitle;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      student: json['student'] != null
          ? UserModel.fromJson(json['student'] as Map<String, dynamic>)
          : null,
      formation: json['formation'] as String?,
      classLevel: json['classLevel'] as String?,
      academicYear: json['academicYear'] as String? ?? '',
      statistics: DashboardStatistics.fromJson(
        json['statistics'] as Map<String, dynamic>? ?? const {},
      ),
      nextCourse: json['nextCourse'] != null
          ? CourseItem.fromJson(json['nextCourse'] as Map<String, dynamic>)
          : null,
      courses: (json['courses'] as List<dynamic>? ?? const [])
          .map(
            (dynamic item) => CourseItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      bannerTitle: json['bannerTitle'] as String?,
      bannerSubtitle: json['bannerSubtitle'] as String?,
    );
  }
}
