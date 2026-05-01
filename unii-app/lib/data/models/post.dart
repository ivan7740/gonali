class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.mediaType,
    required this.url,
    this.thumbnailUrl,
    this.duration,
    this.sortOrder = 0,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) => MediaAsset(
    id: (json['id'] as num).toInt(),
    mediaType: json['media_type'] as String,
    url: json['url'] as String,
    thumbnailUrl: json['thumbnail_url'] as String?,
    duration: (json['duration'] as num?)?.toInt(),
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
  );

  final int id;
  final String mediaType;
  final String url;
  final String? thumbnailUrl;
  final int? duration;
  final int sortOrder;

  bool get isImage => mediaType == 'image';
}

class Post {
  const Post({
    required this.id,
    required this.authorId,
    required this.authorUsername,
    required this.visibility,
    required this.likeCount,
    required this.commentCount,
    required this.likedByMe,
    required this.media,
    this.authorNickname,
    this.authorAvatarUrl,
    this.title,
    this.content,
    this.teamId,
    this.activityId,
    this.postType = 0,
    this.createdAt,
  });

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    id: (json['id'] as num).toInt(),
    authorId: (json['author_id'] as num).toInt(),
    authorUsername: json['author_username'] as String,
    authorNickname: json['author_nickname'] as String?,
    authorAvatarUrl: json['author_avatar_url'] as String?,
    visibility: json['visibility'] as String,
    likeCount: (json['like_count'] as num).toInt(),
    commentCount: (json['comment_count'] as num).toInt(),
    likedByMe: (json['liked_by_me'] as bool?) ?? false,
    media: ((json['media'] as List<dynamic>?) ?? const [])
        .map((e) => MediaAsset.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    title: json['title'] as String?,
    content: json['content'] as String?,
    teamId: (json['team_id'] as num?)?.toInt(),
    activityId: (json['activity_id'] as num?)?.toInt(),
    postType: (json['post_type'] as num?)?.toInt() ?? 0,
    createdAt: json['created_at'] as String?,
  );

  final int id;
  final int authorId;
  final String authorUsername;
  final String? authorNickname;
  final String? authorAvatarUrl;
  final int? teamId;
  final int? activityId;
  final int postType;
  final String? title;
  final String? content;
  final String visibility;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final List<MediaAsset> media;
  final String? createdAt;

  String get authorDisplayName =>
      (authorNickname?.isNotEmpty ?? false) ? authorNickname! : authorUsername;

  Post copyWith({bool? likedByMe, int? likeCount, int? commentCount}) => Post(
    id: id,
    authorId: authorId,
    authorUsername: authorUsername,
    authorNickname: authorNickname,
    authorAvatarUrl: authorAvatarUrl,
    teamId: teamId,
    activityId: activityId,
    postType: postType,
    title: title,
    content: content,
    visibility: visibility,
    likeCount: likeCount ?? this.likeCount,
    commentCount: commentCount ?? this.commentCount,
    likedByMe: likedByMe ?? this.likedByMe,
    media: media,
    createdAt: createdAt,
  );
}

class PostComment {
  const PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.content,
    this.nickname,
    this.avatarUrl,
    this.parentId,
    this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
    id: (json['id'] as num).toInt(),
    postId: (json['post_id'] as num).toInt(),
    userId: (json['user_id'] as num).toInt(),
    username: json['username'] as String,
    content: json['content'] as String,
    nickname: json['nickname'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    parentId: (json['parent_id'] as num?)?.toInt(),
    createdAt: json['created_at'] as String?,
  );

  final int id;
  final int postId;
  final int userId;
  final String username;
  final String? nickname;
  final String? avatarUrl;
  final int? parentId;
  final String content;
  final String? createdAt;

  String get displayName =>
      (nickname?.isNotEmpty ?? false) ? nickname! : username;
}

class LikeToggleResult {
  const LikeToggleResult({required this.liked, required this.likeCount});

  factory LikeToggleResult.fromJson(Map<String, dynamic> json) =>
      LikeToggleResult(
        liked: json['liked'] as bool,
        likeCount: (json['like_count'] as num).toInt(),
      );

  final bool liked;
  final int likeCount;
}
