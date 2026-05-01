import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:unii_app/core/map/map_adapter.dart';
import 'package:unii_app/core/map/map_engine.dart';
import 'package:unii_app/data/models/activity.dart';

/// flutter_map-backed adapter using the public OpenStreetMap tile server.
///
/// All inputs/outputs are WGS84 — no coordinate translation needed.
class OsmAdapter implements MapAdapter {
  const OsmAdapter();

  @override
  MapEngine get engine => MapEngine.osm;

  @override
  Widget buildMap({
    required LngLat center,
    required double zoom,
    List<MapMarker> markers = const [],
    MapPolyline? polyline,
    void Function(LngLat)? onTap,
  }) {
    return FlutterMap(
      options: MapOptions(
        initialCenter: LatLng(center.lat, center.lng),
        initialZoom: zoom,
        onTap: onTap == null
            ? null
            : (tap, point) =>
                  onTap(LngLat(lng: point.longitude, lat: point.latitude)),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.unii.unii_app',
        ),
        if (polyline != null && polyline.points.length >= 2)
          PolylineLayer(
            polylines: [
              Polyline(
                points: polyline.points
                    .map((p) => LatLng(p.lat, p.lng))
                    .toList(growable: false),
                strokeWidth: polyline.strokeWidth,
                color: polyline.color ?? Colors.blueAccent,
              ),
            ],
          ),
        if (markers.isNotEmpty)
          MarkerLayer(
            markers: markers
                .map(
                  (m) => Marker(
                    point: LatLng(m.position.lat, m.position.lng),
                    width: 80,
                    height: 60,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on,
                          color: m.color ?? Colors.redAccent,
                          size: 32,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(160),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            m.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(growable: false),
          ),
      ],
    );
  }
}
