import 'package:dio/dio.dart';

import 'package:unii_app/data/models/user.dart';

class UserRepo {
  UserRepo({required Dio dio}) : _dio = dio;

  final Dio _dio;

  static const _path = '/api/v1/users';

  Future<User> getMe() async {
    final res = await _dio.get<Map<String, dynamic>>('$_path/me');
    return User.fromJson(_unwrap(res.data));
  }

  Future<User> updateProfile({
    String? username,
    String? nickname,
    String? email,
    String? city,
    String? occupation,
    int? gender,
    String? birthday,
  }) async {
    final body = <String, dynamic>{
      if (username != null) 'username': username,
      if (nickname != null) 'nickname': nickname,
      if (email != null) 'email': email,
      if (city != null) 'city': city,
      if (occupation != null) 'occupation': occupation,
      if (gender != null) 'gender': gender,
      if (birthday != null) 'birthday': birthday,
    };
    final res = await _dio.put<Map<String, dynamic>>('$_path/me', data: body);
    return User.fromJson(_unwrap(res.data));
  }

  Future<User> updateSettings({
    String? theme,
    String? language,
    String? mapEngine,
    bool? locationShareEnabled,
  }) async {
    final body = <String, dynamic>{
      if (theme != null) 'theme': theme,
      if (language != null) 'language': language,
      if (mapEngine != null) 'map_engine': mapEngine,
      if (locationShareEnabled != null)
        'location_share_enabled': locationShareEnabled,
    };
    final res = await _dio.put<Map<String, dynamic>>(
      '$_path/me/settings',
      data: body,
    );
    return User.fromJson(_unwrap(res.data));
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '$_path/me/password',
      data: {'old_password': oldPassword, 'new_password': newPassword},
    );
  }

  Future<void> deleteAccount() async {
    await _dio.delete<Map<String, dynamic>>('$_path/me');
  }

  Future<User> uploadAvatar({
    required List<int> bytes,
    required String filename,
  }) async {
    final form = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });
    final res = await _dio.post<Map<String, dynamic>>(
      '$_path/me/avatar',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return User.fromJson(_unwrap(res.data));
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
