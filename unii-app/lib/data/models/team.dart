class Team {
  const Team({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.ownerId,
    required this.memberLimit,
    required this.memberCount,
    this.avatarUrl,
    this.description,
    this.myRole,
  });

  factory Team.fromJson(Map<String, dynamic> json) => Team(
    id: (json['id'] as num).toInt(),
    name: json['name'] as String,
    inviteCode: json['invite_code'] as String,
    ownerId: (json['owner_id'] as num).toInt(),
    memberLimit: (json['member_limit'] as num).toInt(),
    memberCount: (json['member_count'] as num).toInt(),
    avatarUrl: json['avatar_url'] as String?,
    description: json['description'] as String?,
    myRole: (json['my_role'] as num?)?.toInt(),
  );

  final int id;
  final String name;
  final String? avatarUrl;
  final String? description;
  final String inviteCode;
  final int ownerId;
  final int memberLimit;
  final int memberCount;

  /// 0 = member, 1 = owner, null = not a member.
  final int? myRole;

  bool get isOwner => myRole == 1;
}

class TeamMember {
  const TeamMember({
    required this.userId,
    required this.role,
    required this.username,
    this.nickname,
    this.avatarUrl,
    this.joinedAt,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
    userId: (json['user_id'] as num).toInt(),
    role: (json['role'] as num).toInt(),
    username: json['username'] as String,
    nickname: json['nickname'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    joinedAt: json['joined_at'] as String?,
  );

  final int userId;
  final int role;
  final String username;
  final String? nickname;
  final String? avatarUrl;
  final String? joinedAt;

  bool get isOwner => role == 1;
}
