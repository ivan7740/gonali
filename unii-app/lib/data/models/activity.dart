class LngLat {
  const LngLat({required this.lng, required this.lat});

  factory LngLat.fromJson(Map<String, dynamic> json) => LngLat(
    lng: (json['lng'] as num).toDouble(),
    lat: (json['lat'] as num).toDouble(),
  );

  final double lng;
  final double lat;

  Map<String, dynamic> toJson() => {'lng': lng, 'lat': lat};
}

class Activity {
  const Activity({
    required this.id,
    required this.teamId,
    required this.creatorId,
    required this.title,
    required this.location,
    required this.visibility,
    this.locationName,
    this.startTime,
    this.endTime,
    this.content,
    this.notice,
    this.createdAt,
  });

  factory Activity.fromJson(Map<String, dynamic> json) => Activity(
    id: (json['id'] as num).toInt(),
    teamId: (json['team_id'] as num).toInt(),
    creatorId: (json['creator_id'] as num).toInt(),
    title: json['title'] as String,
    location: LngLat.fromJson(json['location'] as Map<String, dynamic>),
    visibility: json['visibility'] as String,
    locationName: json['location_name'] as String?,
    startTime: json['start_time'] as String?,
    endTime: json['end_time'] as String?,
    content: json['content'] as String?,
    notice: json['notice'] as String?,
    createdAt: json['created_at'] as String?,
  );

  final int id;
  final int teamId;
  final int creatorId;
  final String title;
  final LngLat location;
  final String? locationName;
  final String? startTime;
  final String? endTime;
  final String? content;
  final String? notice;
  final String visibility;
  final String? createdAt;

  bool get isPublic => visibility == 'public';
}
