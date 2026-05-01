import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/core/config/env.dart';
import 'package:unii_app/core/storage/token_storage.dart';
import 'package:unii_app/data/repositories/auth_repo.dart';

abstract class DioClient {
  DioClient._();

  static Dio build({required TokenStorage storage}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: Env.connectTimeout,
        receiveTimeout: Env.receiveTimeout,
        headers: {'content-type': 'application/json'},
      ),
    );
    dio.interceptors.add(_AuthInterceptor(storage));
    return dio;
  }
}

class _AuthInterceptor extends QueuedInterceptorsWrapper {
  _AuthInterceptor(this._storage);

  final TokenStorage _storage;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!options.headers.containsKey('Authorization')) {
      final token = _storage.access();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } else if (options.headers['Authorization'] == null) {
      options.headers.remove('Authorization');
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode != 401) {
      handler.next(err);
      return;
    }

    final retried = await _attemptRefreshAndRetry(err.requestOptions);
    if (retried != null) {
      handler.resolve(retried);
      return;
    }
    await _storage.clear();
    if (Get.currentRoute != Routes.login) {
      unawaited(Get.offAllNamed<void>(Routes.login));
    }
    handler.next(err);
  }

  Future<Response<dynamic>?> _attemptRefreshAndRetry(
    RequestOptions original,
  ) async {
    if (original.extra['__retried__'] == true) return null;
    final repo = Get.find<AuthRepo>();
    final ok = await repo.refresh();
    if (!ok) return null;

    final retryDio = Dio(BaseOptions(baseUrl: Env.apiBaseUrl));
    final newToken = _storage.access();
    final retryOptions = Options(
      method: original.method,
      headers: <String, dynamic>{
        ...original.headers,
        if (newToken != null) 'Authorization': 'Bearer $newToken',
      },
      contentType: original.contentType,
      responseType: original.responseType,
    );
    final response = await retryDio.request<dynamic>(
      original.path,
      data: original.data,
      queryParameters: original.queryParameters,
      options: retryOptions,
    );
    response.requestOptions.extra['__retried__'] = true;
    return response;
  }
}
