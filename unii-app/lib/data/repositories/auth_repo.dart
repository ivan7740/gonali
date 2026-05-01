import 'package:dio/dio.dart';

import 'package:unii_app/core/storage/token_storage.dart';
import 'package:unii_app/data/models/auth.dart';

/// Auth API client. Uses Dio with the [AuthInterceptor] already attached
/// (in `core/network/dio_client.dart`).
class AuthRepo {
  AuthRepo({required Dio dio, required TokenStorage storage})
    : _dio = dio,
      _storage = storage;

  final Dio _dio;
  final TokenStorage _storage;

  static const _path = '/api/v1/auth';

  Future<TokensDto> register({
    required String phone,
    required String password,
    required String username,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_path/register',
      data: {'phone': phone, 'password': password, 'username': username},
    );
    final tokens = TokensDto.fromJson(_unwrap(res.data));
    await _storage.save(tokens);
    return tokens;
  }

  Future<TokensDto> login({
    required String phone,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_path/login',
      data: {'phone': phone, 'password': password},
    );
    final tokens = TokensDto.fromJson(_unwrap(res.data));
    await _storage.save(tokens);
    return tokens;
  }

  /// Returns true when the access token was successfully refreshed.
  Future<bool> refresh() async {
    final refreshToken = _storage.refresh();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '$_path/refresh',
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );
      final access = AccessDto.fromJson(_unwrap(res.data));
      await _storage.saveAccess(access.accessToken);
      return true;
    } on DioException {
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('$_path/logout');
    } on DioException {
      // best effort — server stateless in W1.
    }
    await _storage.clear();
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic>? body) {
    if (body == null) {
      throw const FormatException('empty response body');
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw FormatException('unexpected response shape: $body');
    }
    return data;
  }
}
