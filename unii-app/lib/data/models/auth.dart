/// JSON DTOs that match the backend response envelope `{code, msg, data}`.
class TokensDto {
  const TokensDto({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.user,
  });

  factory TokensDto.fromJson(Map<String, dynamic> json) => TokensDto(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    expiresIn: json['expires_in'] as int,
    user: json['user'] is Map<String, dynamic>
        ? UserDto.fromJson(json['user'] as Map<String, dynamic>)
        : null,
  );

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final UserDto? user;
}

class AccessDto {
  const AccessDto({required this.accessToken, required this.expiresIn});

  factory AccessDto.fromJson(Map<String, dynamic> json) => AccessDto(
    accessToken: json['access_token'] as String,
    expiresIn: json['expires_in'] as int,
  );

  final String accessToken;
  final int expiresIn;
}

class UserDto {
  const UserDto({
    required this.id,
    required this.phone,
    required this.username,
    required this.needsMapSetup,
    this.nickname,
    this.avatarUrl,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) => UserDto(
    id: (json['id'] as num).toInt(),
    phone: json['phone'] as String,
    username: json['username'] as String,
    needsMapSetup: (json['needs_map_setup'] as bool?) ?? false,
    nickname: json['nickname'] as String?,
    avatarUrl: json['avatar_url'] as String?,
  );

  final int id;
  final String phone;
  final String username;
  final String? nickname;
  final String? avatarUrl;
  final bool needsMapSetup;
}
