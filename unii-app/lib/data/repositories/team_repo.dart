import 'package:dio/dio.dart';

import 'package:unii_app/data/models/team.dart';

class TeamRepo {
  TeamRepo({required Dio dio}) : _dio = dio;

  final Dio _dio;
  static const _path = '/api/v1/teams';

  Future<List<Team>> listMine() async {
    final res = await _dio.get<Map<String, dynamic>>('$_path/mine');
    final list = _unwrap(res.data) as List<dynamic>;
    return list
        .map((e) => Team.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Team> create({
    required String name,
    String? description,
    int? memberLimit,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_path/',
      data: {
        'name': name,
        if (description != null) 'description': description,
        if (memberLimit != null) 'member_limit': memberLimit,
      },
    );
    return Team.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  }

  Future<Team> joinByCode(String code) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_path/join',
      data: {'invite_code': code},
    );
    return Team.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  }

  Future<Team> detail(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('$_path/$id');
    return Team.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  }

  Future<List<TeamMember>> members(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('$_path/$id/members');
    final list = _unwrap(res.data) as List<dynamic>;
    return list
        .map((e) => TeamMember.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> leave(int id) async {
    await _dio.delete<Map<String, dynamic>>('$_path/$id/members/me');
  }

  Future<void> kick(int id, int userId) async {
    await _dio.delete<Map<String, dynamic>>('$_path/$id/members/$userId');
  }

  Future<void> transfer(int id, int newOwnerId) async {
    await _dio.post<Map<String, dynamic>>(
      '$_path/$id/transfer',
      data: {'new_owner_id': newOwnerId},
    );
  }

  Future<void> disband(int id) async {
    await _dio.delete<Map<String, dynamic>>('$_path/$id');
  }

  dynamic _unwrap(Map<String, dynamic>? body) {
    if (body == null) {
      throw const FormatException('empty response body');
    }
    return body['data'];
  }
}
