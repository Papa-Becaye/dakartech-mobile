import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Notifie de toute réponse HTTP 401 (token expiré / invalide).
class UnauthorizedInterceptor extends Interceptor {
  UnauthorizedInterceptor({this.onUnauthorized});

  final VoidCallback? onUnauthorized;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      onUnauthorized?.call();
    }
    handler.next(err);
  }
}
