import 'package:dio/dio.dart';

import '../../../core/errors/api_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error_mapper.dart';
import '../models/grades_releve.dart';
import 'grades_endpoints.dart';

/// Contrat d'accès aux notes de l'étudiant connecté.
///
/// Même pattern que [AttendanceRepository] et [CoursesRepository] : l'UI
/// et le contrôleur dépendent de cette abstraction, et les tests injectent
/// une fausse implémentation sans réseau. Aucune donnée fictive : tout
/// provient du backend réel (`GET /notes/mes-notes`).
abstract class GradesRepository {
  /// Relevé de notes de l'étudiant connecté (moyennes et mention
  /// calculées par le backend).
  Future<GradesReleve> fetchMonReleve();
}

/// Implémentation réseau (production).
///
/// Utilise le [Dio] fourni par [ApiClient] (intercepteurs JWT, 401 et
/// erreurs déjà en place) et traduit toutes les erreurs [DioException] en
/// [AppException] via [mapDioError].
class ApiGradesRepository implements GradesRepository {
  const ApiGradesRepository(this._dio);

  final Dio _dio;

  @override
  Future<GradesReleve> fetchMonReleve() async {
    final Response<Map<String, dynamic>> response;
    try {
      response = await _dio.get<Map<String, dynamic>>(GradesEndpoints.mesNotes);
    } on DioException catch (e) {
      throw mapDioError(e);
    }

    final Map<String, dynamic>? data = response.data;
    if (data == null) {
      throw const ApiException('Impossible de charger votre relevé de notes.');
    }
    return GradesReleve.fromJson(data);
  }
}

/// Fabrique le repository par défaut : toujours l'API réelle — aucune
/// donnée statique pour les notes.
GradesRepository buildGradesRepository() =>
    ApiGradesRepository(ApiClient.instance.dio);
