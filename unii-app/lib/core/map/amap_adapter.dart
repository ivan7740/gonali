import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:latlong2/latlong.dart';

import 'package:unii_app/core/map/map_adapter.dart';
import 'package:unii_app/core/map/map_engine.dart';
import 'package:unii_app/data/models/activity.dart';

/// W4 placeholder for the AMap engine.
///
/// The native `amap_flutter_map` SDK requires per-platform key registration
/// (Android `<meta-data>`, iOS `Info.plist`) and a separate mobile SDK key
/// from the Web Service key. That setup is W4.1.
///
/// Until then we render the same OpenStreetMap tiles plus a banner so the
/// user knows the engine is selected but visuals are temporarily unified.
/// Coordinates remain WGS84 throughout — when the real SDK lands the only
/// thing that changes is this widget tree.
class AmapAdapter implements MapAdapter {
  const AmapAdapter();

  @override
  MapEngine get engine => MapEngine.amap;

  @override
  Widget buildMap({
    required LngLat center,
    required double zoom,
    List<MapMarker> markers = const [],
    MapPolyline? polyline,
    void Function(LngLat)? onTap,
  }) {
    return Stack(
      children: [
        FlutterMap(
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
                    color: polyline.color ?? Colors.orangeAccent,
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
                        child: Icon(
                          Icons.location_on,
                          color: m.color ?? Colors.orangeAccent,
                          size: 32,
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
          ],
        ),
        Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: Material(
            elevation: 2,
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'amap_placeholder_banner'.tr,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
