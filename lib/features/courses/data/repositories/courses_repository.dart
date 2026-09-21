import 'package:dio/dio.dart';

import '../../../../core/errors/api_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_mapper.dart';
import '../models/course_detail.dart';
import '../models/course_model.dart';
import '../courses_endpoints.dart';

/// Contrat d'accès aux cours de l'étudiant.
///
/// L'UI et le contrôleur ne dépendent que de cette abstraction (même
/// pattern que [DashboardRepository]) : les tests peuvent injecter une
/// fausse implémentation sans réseau.
abstract class CoursesRepository {
  /// Liste des cours de l'étudiant connecté.
  Future<List<Course>> getMyCourses();

  /// Détail d'un cours via son identifiant réel.
  Future<CourseDetail> getCourseById(int id);

  /// Séances d'un cours, avec la présence de l'étudiant.
  Future<List<CourseSeance>> getCourseSeances(int courseId);

  /// Documents pédagogiques déposés pour un cours.
  Future<List<CourseDocument>> getCourseDocuments(int courseId);

  /// Évaluations d'un cours, avec la note de l'étudiant.
  Future<List<CourseEvaluation>> getCourseEvaluations(int courseId);
}

/// Implémentation réseau (production).
///
/// Même convention que [AuthRepository] :
/// - utilise le [Dio] fourni par [ApiClient] (intercepteurs JWT, 401
///   et erreurs déjà en place) ;
/// - traduit toutes les erreurs [DioException] en [AppException] via
///   [mapDioError] — l'UI ne manipule jamais de `DioException`.
class ApiCoursesRepository implements CoursesRepository {
  const ApiCoursesRepository(this._dio);

  final Dio _dio;

  /// GET /cours/mes-cours — Cours de l'étudiant connecté.
  ///
  /// Le JWT est ajouté automatiquement par l'intercepteur
  /// `AuthInterceptor` du [ApiClient] (Bearer token). Retourne `[]`
  /// si l'étudiant n'a aucun cours.
  @override
  Future<List<Course>> getMyCourses() async {
    final Response<List<dynamic>> response;
    try {
      response = await _dio.get<List<dynamic>>(CoursesEndpoints.myCourses);
    } on DioException catch (e) {
      throw mapDioError(e);
    }
    final List<dynamic> data = response.data ?? const [];
    return data
        .map((item) => Course.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  /// GET /cours/:id — Détail d'un cours (JWT requis).
  ///
  /// Le JWT est ajouté automatiquement par l'intercepteur
  /// `AuthInterceptor`. Une réponse `404` est traduite en
  /// [ApiException] avec `statusCode == 404` (l'UI affiche alors
  /// « Cours introuvable »).
  @override
  Future<CourseDetail> getCourseById(int id) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.get<Map<String, dynamic>>(
        CoursesEndpoints.courseDetail(id),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }

    final Map<String, dynamic>? data = response.data;
    if (data == null) {
      throw const ApiException(
        'Impossible de charger les informations du cours.',
      );
    }
    return CourseDetail.fromJson(data);
  }

  /// GET /cours/:id/seances — Séances (JWT requis).
  ///
  /// Retourne `[]` si le cours n'a aucune séance.
  @override
  Future<List<CourseSeance>> getCourseSeances(int courseId) {
    return _getList(
      CoursesEndpoints.courseSeances(courseId),
      CourseSeance.fromJson,
    );
  }

  /// GET /cours/:id/documents — Documents pédagogiques (JWT requis).
  ///
  /// Retourne `[]` si aucun document n'a été déposé.
  @override
  Future<List<CourseDocument>> getCourseDocuments(int courseId) {
    return _getList(
      CoursesEndpoints.courseDocuments(courseId),
      CourseDocument.fromJson,
    );
  }

  /// GET /cours/:id/evaluations — Évaluations + note étudiant (JWT
  /// requis).
  ///
  /// Retourne `[]` si aucune évaluation n'existe pour ce cours.
  @override
  Future<List<CourseEvaluation>> getCourseEvaluations(int courseId) {
    return _getList(
      CoursesEndpoints.courseEvaluations(courseId),
      CourseEvaluation.fromJson,
    );
  }

  /// Charge une liste JSON du backend et la mappe vers [T].
  ///
  /// Convention identique à [getMyCourses] : traduit les erreurs
  /// [DioException] en [AppException] via [mapDioError].
  Future<List<T>> _getList<T>(
    String path,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    final Response<List<dynamic>> response;
    try {
      response = await _dio.get<List<dynamic>>(path);
    } on DioException catch (e) {
      throw mapDioError(e);
    }

    final List<dynamic> data = response.data ?? const [];
    return data
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }
}

/// Fabrique le repository par défaut : toujours l'API réelle — aucune
/// donnée statique pour la feature cours.
CoursesRepository buildCoursesRepository() =>
    ApiCoursesRepository(ApiClient.instance.dio);
