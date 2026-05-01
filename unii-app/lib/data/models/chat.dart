class Conversation {
  const Conversation({
    required this.id,
    required this.otherUserId,
    required this.otherUsername,
    required this.unreadCount,
    this.otherNickname,
    this.otherAvatarUrl,
    this.lastMessageId,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
    id: (json['id'] as num).toInt(),
    otherUserId: (json['other_user_id'] as num).toInt(),
    otherUsername: json['other_username'] as String,
    unreadCount: (json['unread_count'] as num).toInt(),
    otherNickname: json['other_nickname'] as String?,
    otherAvatarUrl: json['other_avatar_url'] as String?,
    lastMessageId: (json['last_message_id'] as num?)?.toInt(),
    lastMessagePreview: json['last_message_preview'] as String?,
    lastMessageAt: json['last_message_at'] as String?,
    updatedAt: json['updated_at'] as String?,
  );

  final int id;
  final int otherUserId;
  final String otherUsername;
  final String? otherNickname;
  final String? otherAvatarUrl;
  final int? lastMessageId;
  final String? lastMessagePreview;
  final String? lastMessageAt;
  final int unreadCount;
  final String? updatedAt;

  String get displayName =>
      (otherNickname?.isNotEmpty ?? false) ? otherNickname! : otherUsername;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.msgType,
    required this.isRecalled,
    this.content,
    this.mediaUrl,
    this.duration,
    this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: (json['id'] as num).toInt(),
    conversationId: (json['conversation_id'] as num).toInt(),
    senderId: (json['sender_id'] as num).toInt(),
    msgType: json['msg_type'] as String,
    isRecalled: (json['is_recalled'] as bool?) ?? false,
    content: json['content'] as String?,
    mediaUrl: json['media_url'] as String?,
    duration: (json['duration'] as num?)?.toInt(),
    createdAt: json['created_at'] as String?,
  );

  final int id;
  final int conversationId;
  final int senderId;
  final String msgType;
  final String? content;
  final String? mediaUrl;
  final int? duration;
  final bool isRecalled;
  final String? createdAt;

  bool get isText => msgType == 'text';
  bool get isImage => msgType == 'image';

  ChatMessage copyWith({bool? isRecalled}) => ChatMessage(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    msgType: msgType,
    isRecalled: isRecalled ?? this.isRecalled,
    content: content,
    mediaUrl: mediaUrl,
    duration: duration,
    createdAt: createdAt,
  );
}
