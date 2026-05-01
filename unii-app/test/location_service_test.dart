import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mocktail/mocktail.dart';

import 'package:unii_app/core/location/location_service.dart';
import 'package:unii_app/data/models/location.dart';
import 'package:unii_app/data/repositories/location_repo.dart';

class _MockRepo extends Mock implements LocationRepo {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockRepo repo;

  Position position({double lng = 121.0, double lat = 31.0}) => Position(
    latitude: lat,
    longitude: lng,
    timestamp: DateTime.utc(2026, 5, 1),
    accuracy: 5.0,
    altitude: 0,
    heading: 0,
    speed: 0,
    speedAccuracy: 0,
    altitudeAccuracy: 0,
    headingAccuracy: 0,
  );

  MemberLocation echo() => const MemberLocation(
    userId: 1,
    username: 'alice',
    lng: 121.0,
    lat: 31.0,
    updatedAt: '2026-05-01T00:00:00Z',
  );

  setUp(() {
    repo = _MockRepo();
    when(
      () => repo.report(
        lng: any(named: 'lng'),
        lat: any(named: 'lat'),
        accuracy: any(named: 'accuracy'),
        speed: any(named: 'speed'),
        bearing: any(named: 'bearing'),
      ),
    ).thenAnswer((_) async => echo());
  });

  test('start fires an immediate report', () async {
    final svc = LocationService(
      repo: repo,
      ensurePermission: () async => true,
      fetchPosition: () async => position(),
    );
    final ok = await svc.start(interval: const Duration(seconds: 30));
    expect(ok, isTrue);
    expect(svc.isRunning, isTrue);
    await Future<void>.delayed(Duration.zero);
    verify(
      () => repo.report(
        lng: any(named: 'lng'),
        lat: any(named: 'lat'),
        accuracy: any(named: 'accuracy'),
        speed: any(named: 'speed'),
        bearing: any(named: 'bearing'),
      ),
    ).called(1);
    await svc.stop();
  });

  test('start returns false when permission denied', () async {
    final svc = LocationService(
      repo: repo,
      ensurePermission: () async => false,
      fetchPosition: () async => position(),
    );
    expect(await svc.start(), isFalse);
    expect(svc.isRunning, isFalse);
    verifyNever(
      () => repo.report(
        lng: any(named: 'lng'),
        lat: any(named: 'lat'),
        accuracy: any(named: 'accuracy'),
        speed: any(named: 'speed'),
        bearing: any(named: 'bearing'),
      ),
    );
  });

  test('stop halts the running flag', () async {
    final svc = LocationService(
      repo: repo,
      ensurePermission: () async => true,
      fetchPosition: () async => position(),
    );
    await svc.start(interval: const Duration(seconds: 30));
    await svc.stop();
    expect(svc.isRunning, isFalse);
  });
}
