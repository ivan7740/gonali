import 'package:dio/dio.dart';

import 'package:unii_app/data/models/post.dart';

class PostRepo {
  PostRepo({required Dio dio}) : _dio = dio;

  final Dio _dio;
  static const _path = '/api/v1/posts';

  Future<List<Post>> feed({int? beforeId, int limit = 20}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '$_path/',
      queryParameters: {
        'limit': limit,
        if (beforeId != null) 'before_id': beforeId,
      },
    );
    return (_unwrap(res.data) as List<dynamic>)
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<Post> create({
    String? title,
    String? content,
    String visibility = 'public',
    int? teamId,
    List<int> mediaIds = const [],
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_path/',
      data: {
        if (title != null && title.isNotEmpty) 'title': title,
        if (content != null && content.isNotEmpty) 'content': content,
        'visibility': visibility,
        if (teamId != null) 'team_id': teamId,
        if (mediaIds.isNotEmpty) 'media_ids': mediaIds,
      },
    );
    return Post.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  }

  Future<Post> detail(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('$_path/$id');
    return Post.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  }

  Future<LikeToggleResult> toggleLike(int id) async {
    final res = await _dio.post<Map<String, dynamic>>('$_path/$id/like');
    return LikeToggleResult.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  }

  Future<List<PostComment>> listComments(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('$_path/$id/comments');
    return (_unwrap(res.data) as List<dynamic>)
        .map((e) => PostComment.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<PostComment> createComment({
    required int postId,
    required String content,
    int? parentId,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '$_path/$postId/comments',
      data: {'content': content, if (parentId != null) 'parent_id': parentId},
    );
    return PostComment.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  }

  dynamic _unwrap(Map<String, dynamic>? body) {
    if (body == null) {
      throw const FormatException('empty response body');
    }
    return body['data'];
  }
}
