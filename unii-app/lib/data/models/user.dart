/// Full user/profile model returned by `/api/v1/users/me` and the various
/// PUT endpoints.
class User {
  const User({
    required this.id,
    required this.phone,
    required this.username,
    required this.needsMapSetup,
    this.nickname,
    this.avatarUrl,
    this.email,
    this.city,
    this.occupation,
    this.gender,
    this.birthday,
    this.theme,
    this.language,
    this.mapEngine,
    this.locationShareEnabled,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
    id: (json['id'] as num).toInt(),
    phone: json['phone'] as String,
    username: json['username'] as String,
    needsMapSetup: (json['needs_map_setup'] as bool?) ?? false,
    nickname: json['nickname'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    email: json['email'] as String?,
    city: json['city'] as String?,
    occupation: json['occupation'] as String?,
    gender: (json['gender'] as num?)?.toInt(),
    birthday: json['birthday'] as String?,
    theme: json['theme'] as String?,
    language: json['language'] as String?,
    mapEngine: json['map_engine'] as String?,
    locationShareEnabled: json['location_share_enabled'] as bool?,
  );

  final int id;
  final String phone;
  final String username;
  final String? nickname;
  final String? avatarUrl;
  final String? email;
  final String? city;
  final String? occupation;
  final int? gender;
  final String? birthday; // ISO yyyy-MM-dd
  final String? theme;
  final String? language;
  final String? mapEngine;
  final bool? locationShareEnabled;
  final bool needsMapSetup;
}
