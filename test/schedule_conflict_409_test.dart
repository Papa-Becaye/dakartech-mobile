import 'dart:convert';

import 'package:dakartech_mobile/core/errors/api_exception.dart';
import 'package:dakartech_mobile/core/errors/schedule_conflict_exception.dart';
import 'package:dakartech_mobile/core/network/api_error_mapper.dart';
import 'package:dakartech_mobile/core/network/interceptors/error_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// Adapter simulé renvoyant une réponse HTTP donnée (corps + statut).
class _FakeDioAdapter implements HttpClientAdapter {
  _FakeDioAdapter(this._statusCode, this._payload);

  final int _statusCode;
  final Object _payload;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(_payload),
      _statusCode,
      headers: const {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Renvoie l'exception consommée par les repositories pour une query Dio.
Future<Object> _runDioError(int statusCode, Object payload) async {
  final Dio dio = Dio()..httpClientAdapter = _FakeDioAdapter(statusCode, payload);
  dio.interceptors.add(ErrorInterceptor());

  try {
    await dio.get('/seances');
    fail('Une DioException devait être levée');
  } on DioException catch (e) {
    return mapDioError(e);
  }
}

const Map<String, Object> _conflictPayload = {
  'statusCode': 409,
  'error': 'Conflict',
  'code': 'SCHEDULE_CONFLICT',
  'message':
      'La classe « IG1 » est déjà occupée à ce créneau (séance « Séance 6 » de « Mathématiques I », le 21/09/2026 17:10 à 19:10).',
  'conflictType': 'CLASSE',
  'conflictingSessionId': 6,
  'reason':
      'La classe « IG1 » est déjà occupée à ce créneau (séance « Séance 6 » de « Mathématiques I », le 21/09/2026 17:10 à 19:10).',
  'conflicts': <Object>[],
};

void main() {
  group('mapping du 409 SCHEDULE_CONFLICT côté mobile', () {
    test('traduit le 409 SCHEDULE_CONFLICT en exception typée', () async {
      final Object error = await _runDioError(409, _conflictPayload);

      expect(error, isA<ScheduleConflictException>());
      final ScheduleConflictException conflict =
          error as ScheduleConflictException;
      expect(conflict.conflictType, 'CLASSE');
      expect(conflict.conflictingSessionId, 6);
      expect(conflict.statusCode, 409);
      expect(conflict.code, 'SCHEDULE_CONFLICT');
      // Message lisible pour l'utilisateur (pas de JSON brut).
      expect(conflict.message, contains('IG1'));
      expect(conflict.message, contains('17:10'));
    });

    test('reste une ApiException générique pour un 409 sans SCHEDULE_CONFLICT',
        () async {
      final Object error = await _runDioError(409, {
        'statusCode': 409,
        'message': 'Conflit avec les données existantes.',
      });

      expect(error, isA<ApiException>());
      expect(error, isNot(isA<ScheduleConflictException>()));
      expect((error as ApiException).message, 'Conflit avec les données existantes.');
    });

    test('message de repli clair si le corps 409 est incomplet', () async {
      final Object error = await _runDioError(409, {
        'statusCode': 409,
        'code': 'SCHEDULE_CONFLICT',
      });

      expect(error, isA<ScheduleConflictException>());
      expect((error as ScheduleConflictException).message,
          'Ce créneau est déjà occupé par une autre séance.');
      expect(error.conflictType, isNull);
      expect(error.conflictingSessionId, isNull);
    });

    test('les autres erreurs HTTP ne sont pas touchées', () async {
      final Object error = await _runDioError(500, {
        'statusCode': 500,
        'message': 'Erreur interne du serveur',
      });

      expect(error, isA<ApiException>());
      expect(error, isNot(isA<ScheduleConflictException>()));
      expect((error as ApiException).statusCode, 500);
    });
  });
}