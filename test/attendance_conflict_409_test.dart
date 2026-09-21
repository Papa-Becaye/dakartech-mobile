import 'dart:convert';

import 'package:dakartech_mobile/core/errors/api_exception.dart';
import 'package:dakartech_mobile/core/errors/attendance_exception.dart';
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
    await dio.post('/presences/50/emarger');
    fail('Une DioException devait être levée');
  } on DioException catch (e) {
    return mapDioError(e);
  }
}

void main() {
  group('mapping des 409 d\'émargement côté mobile', () {
    test(
        '409 ATTENDANCE_ALREADY_RECORDED → AttendanceException typée '
        '(kind + message serveur)', () async {
      final Object error = await _runDioError(409, {
        'statusCode': 409,
        'error': 'Conflict',
        'code': 'ATTENDANCE_ALREADY_RECORDED',
        'message':
            'Vous avez déjà émargé votre présence à la séance 50.',
      });

      expect(error, isA<AttendanceException>());
      final AttendanceException ex = error as AttendanceException;
      expect(ex.kind, AttendanceConflictCode.alreadyRecorded);
      expect(ex.statusCode, 409);
      expect(ex.code, 'ATTENDANCE_ALREADY_RECORDED');
      expect(ex.message, contains('déjà émargé'));
    });

    test(
        '409 ATTENDANCE_WINDOW_CLOSED → AttendanceException typée '
        '(fenêtre fermée)', () async {
      final Object error = await _runDioError(409, {
        'statusCode': 409,
        'error': 'Conflict',
        'code': 'ATTENDANCE_WINDOW_CLOSED',
        'message':
            "L'émargement est réservé au créneau de la séance (10h00 à 12h00).",
      });

      expect(error, isA<AttendanceException>());
      final AttendanceException ex = error as AttendanceException;
      expect(ex.kind, AttendanceConflictCode.windowClosed);
      expect(ex.statusCode, 409);
      expect(ex.message, contains('créneau'));
    });

    test('reste une ApiException générique pour un 409 sans code émargement',
        () async {
      final Object error = await _runDioError(409, {
        'statusCode': 409,
        'message': 'Conflit avec les données existantes.',
      });

      expect(error, isA<ApiException>());
      expect(error, isNot(isA<AttendanceException>()));
      expect((error as ApiException).message, 'Conflit avec les données existantes.');
    });

    test('message de repli clair si le corps 409 est incomplet', () async {
      final Object errorAlready = await _runDioError(409, {
        'statusCode': 409,
        'code': 'ATTENDANCE_ALREADY_RECORDED',
      });
      expect(errorAlready, isA<AttendanceException>());
      expect((errorAlready as AttendanceException).message,
          'Vous avez déjà émargé votre présence à cette séance.');

      final Object errorClosed = await _runDioError(409, {
        'statusCode': 409,
        'code': 'ATTENDANCE_WINDOW_CLOSED',
      });
      expect(errorClosed, isA<AttendanceException>());
      expect((errorClosed as AttendanceException).message,
          "L'émargement n'est pas disponible pour cette séance.");
    });

    test('les autres erreurs HTTP ne sont pas touchées', () async {
      final Object error = await _runDioError(500, {
        'statusCode': 500,
        'message': 'Erreur interne du serveur',
      });

      expect(error, isA<ApiException>());
      expect(error, isNot(isA<AttendanceException>()));
      expect((error as ApiException).statusCode, 500);
    });
  });
}