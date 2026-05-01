import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:unii_app/core/map/map_adapter.dart';
import 'package:unii_app/data/models/activity.dart';
import 'package:unii_app/data/models/location.dart';
import 'package:unii_app/data/repositories/location_repo.dart';

/// Pulls the team heartbeat on a fixed cadence and renders members on the
/// active [MapAdapter]. Centred on the first member or a sensible default
/// when nobody has reported yet.
class TeamMapWidget extends StatefulWidget {
  const TeamMapWidget({required this.teamId, super.key});

  final int teamId;

  @override
  State<TeamMapWidget> createState() => _TeamMapWidgetState();
}

class _TeamMapWidgetState extends State<TeamMapWidget> {
  static const _refreshInterval = Duration(seconds: 10);

  Timer? _timer;
  HeartbeatSnapshot? _snapshot;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    _timer = Timer.periodic(_refreshInterval, (_) => unawaited(_refresh()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final snap = await Get.find<LocationRepo>().heartbeat(
        teamId: widget.teamId,
      );
      if (!mounted) return;
      setState(() {
        _snapshot = snap;
        _loading = false;
      });
    } on Object {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final adapter = Get.find<MapAdapter>();
    final members = _snapshot?.members ?? const <MemberLocation>[];
    final center = members.isNotEmpty
        ? members.first.position
        : const LngLat(lng: 121.4737, lat: 31.2304); // Bund as fallback
    final markers = members
        .map(
          (m) => MapMarker(
            id: 'u-${m.userId}',
            position: m.position,
            label: m.displayName,
          ),
        )
        .toList(growable: false);

    return Stack(
      children: [
        adapter.buildMap(center: center, zoom: 13, markers: markers),
        if (_loading && _snapshot == null)
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_snapshot != null && members.isEmpty)
          Positioned(
            bottom: 8,
            left: 8,
            right: 8,
            child: Material(
              color: Colors.black.withAlpha(160),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Text(
                  'team_no_members_reporting'.tr,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
