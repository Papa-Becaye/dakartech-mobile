import 'package:dio/dio.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error_mapper.dart';
import '../models/attendance_overview.dart';
import 'attendance_endpoints.dart';

/// Contrat d'accès à l'assiduité de l'étudiant connecté.
///
/// Même pattern que [CoursesRepository] et [ScheduleRepository] : l'UI et
/// le contrôleur dépendent de cette abstraction, les tests injectent une
/// fausse implémentation sans réseau. Aucune donnée fictive : tout provient
/// du backend réel.
abstract class AttendanceRepository {
  /// Bilan + historique + état d'émargement de l'étudiant connecté
  /// (`GET /presences/mon-assiduite`, JWT requis).
  Future<AttendanceOverview> fetchMonAssiduite();

  /// Émarge la présence à la séance [seanceId] (`POST
  /// /presences/:seanceId/emarger`, JWT requis). Lève une
  /// [AppException] (typée [AttendanceException] sur 409 métier).
  Future<AttendanceEmargementResult> emarger(int seanceId);
}

/// Implémentation réseau (production).
///
/// Utilise le [Dio] fourni par [ApiClient] (intercepteurs JWT, 401 et
/// erreurs déjà en place) et traduit toutes les erreurs [DioException] en
/// [AppException] via [mapDioError].
class ApiAttendanceRepository implements AttendanceRepository {
  const ApiAttendanceRepository(this._dio);

  final Dio _dio;

  @override
  Future<AttendanceOverview> fetchMonAssiduite() async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.get<Map<String, dynamic>>(
        AttendanceEndpoints.monAssiduite,
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }

    final Map<String, dynamic>? data = response.data;
    if (data == null) {
      throw const ApiException('Impossible de charger votre assiduité.');
    }
    return AttendanceOverview.fromJson(data);
  }

  @override
  Future<AttendanceEmargementResult> emarger(int seanceId) async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.post<Map<String, dynamic>>(
        AttendanceEndpoints.emarger(seanceId),
      );
    } on DioException catch (e) {
      throw mapDioError(e);
    }

    final Map<String, dynamic>? data = response.data;
    if (data == null) {
      throw const ApiException(
        'Un problème est survenu lors de l\'émargement.',
      );
    }
    return AttendanceEmargementResult.fromJson(data);
  }
}

/// Fabrique le repository par défaut : toujours l'API réelle — aucune
/// donnée statique pour l'assiduité.
AttendanceRepository buildAttendanceRepository() =>
    ApiAttendanceRepository(ApiClient.instance.dio);
