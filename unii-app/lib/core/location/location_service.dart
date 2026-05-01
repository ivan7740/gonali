import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'package:unii_app/data/repositories/location_repo.dart';

/// Pluggable seam for tests — production code uses package:geolocator,
/// tests inject fakes.
typedef PermissionResolver = Future<bool> Function();
typedef PositionFetcher = Future<Position> Function();

Future<bool> _defaultEnsurePermission() async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) return false;
  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  return perm == LocationPermission.always ||
      perm == LocationPermission.whileInUse;
}

Future<Position> _defaultFetch() => Geolocator.getCurrentPosition(
  locationSettings: const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 0,
  ),
);

/// Periodically samples the device location and reports it to the backend.
///
/// Cadence is configurable; W4 default is 30s. Privacy-toggle compliance is
/// the caller's responsibility — call [stop] when the user disables sharing.
class LocationService {
  LocationService({
    required LocationRepo repo,
    PermissionResolver? ensurePermission,
    PositionFetcher? fetchPosition,
  }) : _repo = repo,
       _ensurePermission = ensurePermission ?? _defaultEnsurePermission,
       _fetchPosition = fetchPosition ?? _defaultFetch;

  final LocationRepo _repo;
  final PermissionResolver _ensurePermission;
  final PositionFetcher _fetchPosition;

  Timer? _timer;
  bool _running = false;
  Duration _interval = const Duration(seconds: 30);

  bool get isRunning => _running;
  Duration get interval => _interval;

  Future<bool> start({Duration? interval}) async {
    if (_running) {
      if (interval != null && interval != _interval) {
        _interval = interval;
        _restart();
      }
      return true;
    }
    final ok = await _ensurePermission();
    if (!ok) return false;

    _interval = interval ?? _interval;
    _running = true;
    unawaited(_tick());
    _timer = Timer.periodic(_interval, (_) => unawaited(_tick()));
    return true;
  }

  Future<void> stop() async {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  void setInterval(Duration v) {
    if (v == _interval) return;
    _interval = v;
    if (_running) _restart();
  }

  Future<void> _tick() async {
    try {
      final pos = await _fetchPosition();
      await _repo.report(
        lng: pos.longitude,
        lat: pos.latitude,
        accuracy: pos.accuracy,
        speed: pos.speed,
        bearing: pos.heading,
      );
    } on Object {
      // Swallow — next tick will retry. Errors during background reports
      // shouldn't bubble to the UI; the heartbeat just sees stale data.
    }
  }

  void _restart() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => unawaited(_tick()));
  }
}
