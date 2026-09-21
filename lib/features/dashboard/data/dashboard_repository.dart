import '../../../core/utils/date_format.dart';
import '../../courses/data/models/course_detail.dart';
import '../../courses/data/models/course_model.dart';
import '../../courses/data/repositories/courses_repository.dart';
import '../models/course_item.dart';
import '../models/dashboard_data.dart';
import '../models/dashboard_statistics.dart';

/// Contrat d'accès aux données du dashboard.
///
/// L'UI et le contrôleur ne dépendent que de cette abstraction : les
/// tests peuvent injecter une implémentation de substitution sans
/// réseau, la production utilise [ApiDashboardRepository].
abstract class DashboardRepository {
  Future<DashboardData> fetchDashboard();
}

/// Implémentation réseau (production).
///
/// Le backend NestJS ne possède aucun endpoint « dashboard » combiné :
/// les données sont donc **composées** à partir des vraies routes
/// étudiantes existantes, via le [CoursesRepository] réutilisé (aucune
/// logique dupliquée) :
///
/// 1. `GET /cours/mes-cours` → la liste réelle des cours de l'étudiant ;
/// 2. `GET /cours/:id` → classe (filière + année) et prochaine séance ;
/// 3. `GET /cours/:id/seances` → séances + présences (statistiques) ;
/// 4. `GET /cours/:id/evaluations` → évaluations + notes (moyenne).
///
/// Tous les appels passent par le [ApiClient] (intercepteur JWT, 401,
/// erreurs déjà en place). Les statistiques sont de simples agrégations
/// de ces données réelles, calculées ici (couche data), jamais dans les
/// widgets.
class ApiDashboardRepository implements DashboardRepository {
  const ApiDashboardRepository(this._coursesRepository);

  final CoursesRepository _coursesRepository;

  @override
  Future<DashboardData> fetchDashboard() async {
    final List<Course> courses = await _coursesRepository.getMyCourses();
    if (courses.isEmpty) {
      return DashboardData(
        academicYear: '',
        statistics: DashboardStatistics.empty,
        nextCourse: null,
        courses: const [],
      );
    }

    // Chargements parallèles : un appel par cours pour le détail
    // (prochaine séance + classe), les séances (présence) et les
    // évaluations (notes).
    final List<CourseDetail> details = await Future.wait(
      courses.map(
        (Course course) => _coursesRepository.getCourseById(course.id),
      ),
    );
    final List<List<CourseSeance>> seancesByCourse = await Future.wait(
      courses.map(
        (Course course) => _coursesRepository.getCourseSeances(course.id),
      ),
    );
    final List<List<CourseEvaluation>> evaluationsByCourse = await Future.wait(
      courses.map(
        (Course course) => _coursesRepository.getCourseEvaluations(course.id),
      ),
    );

    return _compose(courses, details, seancesByCourse, evaluationsByCourse);
  }

  /// Assemble le [DashboardData] à partir des seules données réelles.
  DashboardData _compose(
    List<Course> courses,
    List<CourseDetail> details,
    List<List<CourseSeance>> seancesByCourse,
    List<List<CourseEvaluation>> evaluationsByCourse,
  ) {
    final CourseDetail? classSource = _firstDetailWithClasse(details);

    final List<CourseSeance> allSeances = <CourseSeance>[
      for (final List<CourseSeance> seances in seancesByCourse) ...seances,
    ];
    final List<CourseEvaluation> allEvaluations = <CourseEvaluation>[
      for (final List<CourseEvaluation> evaluations in evaluationsByCourse)
        ...evaluations,
    ];

    return DashboardData(
      formation: classSource?.classe?.filiere?.nom,
      classLevel: classSource?.classe?.nom,
      academicYear: classSource?.classe?.annee?.libelle ?? '',
      statistics: _buildStatistics(allSeances, allEvaluations),
      nextCourse: _buildNextCourse(courses, details),
      courses: _buildCourseItems(courses, details),
      // Le backend ne fournit aucun contenu motivationnel : sans source
      // réelle, le banner ne s'affiche pas (aucun texte inventé).
    );
  }

  /// Statistiques dérivées des séances (présences) et évaluations
  /// (notes) réellement chargées.
  DashboardStatistics _buildStatistics(
    List<CourseSeance> seances,
    List<CourseEvaluation> evaluations,
  ) {
    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime todayEnd = todayStart.add(const Duration(days: 1));

    final int todaySessions = seances.where((CourseSeance seance) {
      final DateTime date = seance.date.toLocal();
      return !date.isBefore(todayStart) && date.isBefore(todayEnd);
    }).length;

    final List<CourseSeance> emarges = seances
        .where((CourseSeance seance) => seance.presence != null)
        .toList(growable: false);
    final int presents = emarges
        .where((CourseSeance s) => s.presence!.present)
        .length;

    final double? attendanceRate = emarges.isEmpty
        ? null
        : presents / emarges.length * 100;

    final List<double> notes = <double>[
      for (final CourseEvaluation evaluation in evaluations)
        if (evaluation.note != null) evaluation.note!,
    ];
    final double? average = notes.isEmpty
        ? null
        : notes.reduce((double a, double b) => a + b) / notes.length;

    return DashboardStatistics(
      todaySessions: todaySessions,
      attendanceRate: attendanceRate,
      unjustifiedAbsences: emarges.length - presents,
      average: average,
    );
  }

  /// Prochain cours : la séance à venir la plus proche, toutes matières
  /// confondues. Chaque [CourseDetail] embarque sa prochaine séance
  /// (première séance non passée côté backend) ; on retient la plus
  /// proche. Sans séance à venir → `null`.
  CourseItem? _buildNextCourse(
    List<Course> courses,
    List<CourseDetail> details,
  ) {
    CourseDetail? best;
    for (final CourseDetail detail in details) {
      final CourseSeance? seance = detail.prochaineSeance;
      if (seance == null) continue;
      if (best == null || seance.date.isBefore(best.prochaineSeance!.date)) {
        best = detail;
      }
    }
    if (best == null) return null;

    final Course course = courses.firstWhere((Course c) => c.id == best!.id);
    return _toCourseItem(course, best.prochaineSeance!);
  }

  /// Cours « Mes cours » : titre, enseignant et prochaine séance réels.
  /// Aucune progression n'est affichée (non fournie par le backend).
  List<CourseItem> _buildCourseItems(
    List<Course> courses,
    List<CourseDetail> details,
  ) {
    final Map<int, CourseDetail> detailById = <int, CourseDetail>{
      for (final CourseDetail detail in details) detail.id: detail,
    };

    return <CourseItem>[
      for (final Course course in courses)
        _toCourseItem(course, detailById[course.id]?.prochaineSeance),
    ];
  }

  /// Convertit un cours + sa prochaine séance en [CourseItem] du
  /// dashboard (heures dérivées de la date réelle et de la durée).
  CourseItem _toCourseItem(Course course, CourseSeance? seance) {
    final DateTime? date = seance?.date.toLocal();

    String? startTime;
    String? endTime;
    if (date != null) {
      startTime = _hhmm(date);
      final DateTime end = date.add(Duration(hours: seance!.duree));
      endTime = _hhmm(end);
    }

    return CourseItem(
      id: course.id,
      title: course.titre,
      date: date,
      startTime: startTime,
      endTime: endTime,
      teacherName: course.enseignant?.fullName,
      progress: null,
      nextSessionLabel: date == null
          ? null
          : '${courseDayLabel(date)} ${_hhmm(date)}',
    );
  }

  /// Premier détail embarquant une classe (filière + année) réelle.
  static CourseDetail? _firstDetailWithClasse(List<CourseDetail> details) {
    for (final CourseDetail detail in details) {
      if (detail.classe != null) return detail;
    }
    return null;
  }

  /// « 08:30 » depuis une date locale.
  static String _hhmm(DateTime date) {
    final String h = date.hour.toString().padLeft(2, '0');
    final String m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

/// Fabrique le repository par défaut : toujours l'API réelle. La couche
/// data répète exactement les mêmes appels que les autres features
/// (réutilisation de [buildCoursesRepository]) — aucune donnée
/// statique ou mockée pour le dashboard.
DashboardRepository buildDashboardRepository() =>
    ApiDashboardRepository(buildCoursesRepository());
