import 'package:flutter/material.dart';

import 'package:unii_app/core/map/map_engine.dart';
import 'package:unii_app/data/models/activity.dart';

/// Marker rendered on the map for a single member or POI.
class MapMarker {
  const MapMarker({
    required this.id,
    required this.position,
    required this.label,
    this.color,
  });

  final String id;
  final LngLat position;
  final String label;
  final Color? color;
}

/// Polyline drawn on the map (e.g. a planned route).
class MapPolyline {
  const MapPolyline({required this.points, this.strokeWidth = 4, this.color});

  final List<LngLat> points;
  final double strokeWidth;
  final Color? color;
}

/// Stable interface every map engine must implement.
///
/// W4 ships full [MapEngine.osm] via flutter_map. The [MapEngine.amap]
/// adapter is a placeholder until the native SDK config (W4.1) lands.
abstract class MapAdapter {
  MapEngine get engine;

  /// Build the rendered map widget. All inputs are WGS84.
  Widget buildMap({
    required LngLat center,
    required double zoom,
    List<MapMarker> markers = const [],
    MapPolyline? polyline,
    void Function(LngLat)? onTap,
  });
}
