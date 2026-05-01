import 'package:dio/dio.dart';

import 'package:unii_app/data/models/moment.dart';

class MomentRepo {
  MomentRepo({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Moment>> list({required int teamId, String? since}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/teams/$teamId/moments/',
      queryParameters: since == null ? null : {'since': since},
    );
    return (_unwrap(res.data) as List<dynamic>)
        .map((e) => Moment.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Moment> create({
    required int teamId,
    String? content,
    List<int> mediaIds = const [],
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/teams/$teamId/moments/',
      data: {
        if (content != null && content.isNotEmpty) 'content': content,
        if (mediaIds.isNotEmpty) 'media_ids': mediaIds,
      },
    );
    return Moment.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  }

  dynamic _unwrap(Map<String, dynamic>? body) {
    if (body == null) {
      throw const FormatException('empty response body');
    }
    return body['data'];
  }
}
