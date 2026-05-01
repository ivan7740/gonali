import 'package:dio/dio.dart';

import 'package:unii_app/data/models/activity.dart';

class ActivityRepo {
  ActivityRepo({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Activity>> listByTeam(int teamId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/teams/$teamId/activities/',
    );
    final list = _unwrap(res.data) as List<dynamic>;
    return list
        .map((e) => Activity.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Activity> detail(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/v1/activities/$id');
    return Activity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  }

  Future<Activity> create({
    required int teamId,
    required String title,
    required LngLat location,
    required String visibility,
    String? locationName,
    String? startTime,
    String? endTime,
    String? content,
    String? notice,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/teams/$teamId/activities/',
      data: {
        'title': title,
        'location': location.toJson(),
        'visibility': visibility,
        if (locationName != null) 'location_name': locationName,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (content != null) 'content': content,
        if (notice != null) 'notice': notice,
      },
    );
    return Activity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  }

  Future<Activity> update({
    required int id,
    String? title,
    LngLat? location,
    String? locationName,
    String? startTime,
    String? endTime,
    String? content,
    String? notice,
    String? visibility,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/v1/activities/$id',
      data: {
        if (title != null) 'title': title,
        if (location != null) 'location': location.toJson(),
        if (locationName != null) 'location_name': locationName,
        if (startTime != null) 'start_time': startTime,
        if (endTime != null) 'end_time': endTime,
        if (content != null) 'content': content,
        if (notice != null) 'notice': notice,
        if (visibility != null) 'visibility': visibility,
      },
    );
    return Activity.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  }

  Future<void> delete(int id) async {
    await _dio.delete<Map<String, dynamic>>('/api/v1/activities/$id');
  }

  dynamic _unwrap(Map<String, dynamic>? body) {
    if (body == null) {
      throw const FormatException('empty response body');
    }
    return body['data'];
  }
}
