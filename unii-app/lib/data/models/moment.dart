import 'package:unii_app/data/models/post.dart';

class Moment {
  const Moment({
    required this.id,
    required this.teamId,
    required this.authorId,
    required this.authorUsername,
    required this.media,
    this.authorNickname,
    this.authorAvatarUrl,
    this.content,
    this.createdAt,
  });

  factory Moment.fromJson(Map<String, dynamic> json) => Moment(
    id: (json['id'] as num).toInt(),
    teamId: (json['team_id'] as num).toInt(),
    authorId: (json['author_id'] as num).toInt(),
    authorUsername: json['author_username'] as String,
    media: ((json['media'] as List<dynamic>?) ?? const [])
        .map((e) => MediaAsset.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    authorNickname: json['author_nickname'] as String?,
    authorAvatarUrl: json['author_avatar_url'] as String?,
    content: json['content'] as String?,
    createdAt: json['created_at'] as String?,
  );

  final int id;
  final int teamId;
  final int authorId;
  final String authorUsername;
  final String? authorNickname;
  final String? authorAvatarUrl;
  final String? content;
  final List<MediaAsset> media;
  final String? createdAt;

  String get displayName =>
      (authorNickname?.isNotEmpty ?? false) ? authorNickname! : authorUsername;
}
