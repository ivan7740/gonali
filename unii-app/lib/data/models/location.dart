import 'package:unii_app/data/models/activity.dart';

class MemberLocation {
  const MemberLocation({
    required this.userId,
    required this.username,
    required this.lng,
    required this.lat,
    required this.updatedAt,
    this.nickname,
    this.avatarUrl,
    this.accuracy,
    this.speed,
    this.bearing,
  });

  factory MemberLocation.fromJson(Map<String, dynamic> json) => MemberLocation(
    userId: (json['user_id'] as num).toInt(),
    username: json['username'] as String,
    lng: (json['lng'] as num).toDouble(),
    lat: (json['lat'] as num).toDouble(),
    updatedAt: json['updated_at'] as String,
    nickname: json['nickname'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    accuracy: (json['accuracy'] as num?)?.toDouble(),
    speed: (json['speed'] as num?)?.toDouble(),
    bearing: (json['bearing'] as num?)?.toDouble(),
  );

  final int userId;
  final String username;
  final String? nickname;
  final String? avatarUrl;
  final double lng;
  final double lat;
  final double? accuracy;
  final double? speed;
  final double? bearing;
  final String updatedAt;

  LngLat get position => LngLat(lng: lng, lat: lat);
  String get displayName =>
      (nickname?.isNotEmpty ?? false) ? nickname! : username;
}

class HeartbeatSnapshot {
  const HeartbeatSnapshot({
    required this.members,
    required this.activityChanges,
    required this.momentUnread,
    required this.serverTime,
  });

  factory HeartbeatSnapshot.fromJson(Map<String, dynamic> json) =>
      HeartbeatSnapshot(
        members: (json['members'] as List<dynamic>)
            .map((e) => MemberLocation.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        activityChanges: (json['activity_changes'] as List<dynamic>)
            .map((e) => Activity.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        momentUnread: (json['moment_unread'] as num).toInt(),
        serverTime: json['server_time'] as String,
      );

  final List<MemberLocation> members;
  final List<Activity> activityChanges;
  final int momentUnread;
  final String serverTime;
}

class RouteResult {
  const RouteResult({
    required this.distanceM,
    required this.durationS,
    required this.polyline,
    required this.source,
  });

  factory RouteResult.fromJson(Map<String, dynamic> json) => RouteResult(
    distanceM: (json['distance_m'] as num).toDouble(),
    durationS: (json['duration_s'] as num).toInt(),
    polyline: (json['polyline'] as List<dynamic>)
        .map((e) => LngLat.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
    source: json['source'] as String,
  );

  final double distanceM;
  final int durationS;
  final List<LngLat> polyline;
  final String source;
}
