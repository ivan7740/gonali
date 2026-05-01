import 'package:dio/dio.dart';

import 'package:unii_app/data/models/chat.dart';

class ChatRepo {
  ChatRepo({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<List<Conversation>> listConversations() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/chats/conversations',
    );
    return (_unwrap(res.data) as List<dynamic>)
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<int> startWith(int otherUserId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/chats/$otherUserId/start',
    );
    final data = _unwrap(res.data) as Map<String, dynamic>;
    return (data['id'] as num).toInt();
  }

  /// One-shot or long-poll fetch of messages newer than [sinceId].
  ///
  /// When [wait] is true the backend holds the request up to ~25s waiting for
  /// a new message, so callers should keep their HTTP receive timeout above
  /// 30s for these calls.
  Future<List<ChatMessage>> messages({
    required int conversationId,
    int? sinceId,
    bool wait = false,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/v1/chats/conversations/$conversationId/messages',
      queryParameters: {
        if (sinceId != null) 'since_id': sinceId,
        if (wait) 'wait': true,
      },
      options: wait
          ? Options(receiveTimeout: const Duration(seconds: 35))
          : null,
    );
    return (_unwrap(res.data) as List<dynamic>)
        .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<ChatMessage> send({
    required int conversationId,
    required String msgType,
    String? content,
    String? mediaUrl,
    int? duration,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/chats/conversations/$conversationId/messages',
      data: {
        'msg_type': msgType,
        if (content != null) 'content': content,
        if (mediaUrl != null) 'media_url': mediaUrl,
        if (duration != null) 'duration': duration,
      },
    );
    return ChatMessage.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  }

  Future<ChatMessage> recall(int messageId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/v1/chats/messages/$messageId/recall',
    );
    return ChatMessage.fromJson(_unwrap(res.data) as Map<String, dynamic>);
  }

  Future<void> markRead(int conversationId) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/v1/chats/conversations/$conversationId/read',
    );
  }

  dynamic _unwrap(Map<String, dynamic>? body) {
    if (body == null) {
      throw const FormatException('empty response body');
    }
    return body['data'];
  }
}
