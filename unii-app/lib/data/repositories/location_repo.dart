import 'package:dio/dio.dart';

import 'package:unii_app/data/models/location.dart';

class LocationRepo {
  LocationRepo({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<MemberLocation> report({
    required double lng,
    required double lat,
    double? accuracy,
    double? speed,
    double? bearing,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/locations/report',
      data: {
        'lng': lng,
        'lat': lat,
        if (accuracy != null) 'accuracy': accuracy,
        if (speed != null) 'speed': speed,
        if (bearing != null) 'bearing': bearing,
      },
    );
    return MemberLocation.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  }

  Future<double> distance({
    required double fromLng,
    required double fromLat,
    required double toLng,
    required double toLat,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/locations/distance',
      queryParameters: {'from': '$fromLng,$fromLat', 'to': '$toLng,$toLat'},
    );
    final m = (_unwrap(res.data) as Map<String, dynamic>)['meters'];
    return (m as num).toDouble();
  }

  Future<RouteResult> route({
    required double fromLng,
    required double fromLat,
    required double toLng,
    required double toLat,
    String mode = 'driving',
    String engine = 'osm',
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/locations/route',
      queryParameters: {
        'from': '$fromLng,$fromLat',
        'to': '$toLng,$toLat',
        'mode': mode,
        'engine': engine,
      },
    );
    return RouteResult.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  }

  Future<HeartbeatSnapshot> heartbeat({
    required int teamId,
    String? since,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/teams/$teamId/heartbeat',
      queryParameters: since == null ? null : {'since': since},
    );
    return HeartbeatSnapshot.fromJson(
      _unwrap(res.data) as Map<String, dynamic>,
    );
  }

  dynamic _unwrap(Map<String, dynamic>? body) {
    if (body == null) {
      throw const FormatException('empty response body');
    }
    return body['data'];
  }
}
