import '../../courses/data/models/course_detail.dart';
import '../../courses/data/models/course_model.dart';
import '../../courses/data/repositories/courses_repository.dart';
import '../models/schedule_session.dart';

/// Contrat d'accès à l'emploi du temps de l'étudiant.
///
/// Même pattern que [CoursesRepository] et [DashboardRepository] : l'UI et
/// le contrôleur dépendent de cette abstraction, les tests injectent une
/// fausse implémentation sans réseau.
abstract class ScheduleRepository {
  /// Toutes les séances de tous les cours de l'étudiant, triées par date
  /// croissante. Aucune donnée fictive n'est ajoutée ; les séances
  /// manquantes du backend (ex. salle) n'apparaissent simplement pas.
  Future<List<ScheduleSession>> fetchSessions();
}

/// Implémentation réseau (production).
///
/// Réutilise [CoursesRepository] — lui-même branché sur le [Dio] de
/// [ApiClient] avec l'intercepteur JWT — et compose fiablement deux
/// endpoints réels :
/// - `GET /cours/mes-cours` (liste des cours) ;
/// - `GET /cours/:id/seances` (séances de chaque cours).
///
/// Les éventuelles erreurs `DioException` sont déjà traduites en
/// [ApiException] par le repository des cours.
class ApiScheduleRepository implements ScheduleRepository {
  const ApiScheduleRepository(this._coursesRepository);

  final CoursesRepository _coursesRepository;

  @override
  Future<List<ScheduleSession>> fetchSessions() async {
    final List<Course> courses = await _coursesRepository.getMyCourses();

    // Récupère les séances de chaque cours en parallèle.
    final List<List<CourseSeance>> seancesByCourse = await Future.wait(
      courses.map(
        (Course course) => _coursesRepository.getCourseSeances(course.id),
      ),
    );

    final List<ScheduleSession> sessions = <ScheduleSession>[];
    for (int i = 0; i < courses.length; i++) {
      final List<CourseSeance> seances = seancesByCourse[i];
      for (final CourseSeance seance in seances) {
        sessions.add(ScheduleSession(course: courses[i], seance: seance));
      }
    }

    // Tri chronologique — l'UI filtre ensuite localement par semaine/jour.
    sessions.sort((ScheduleSession a, ScheduleSession b) {
      return a.start.compareTo(b.start);
    });
    return sessions;
  }
}

/// Fabrique le repository par défaut : toujours l'API réelle — aucune
/// donnée statique pour le planning.
ScheduleRepository buildScheduleRepository() =>
    ApiScheduleRepository(buildCoursesRepository());
