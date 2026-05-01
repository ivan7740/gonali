import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:mocktail/mocktail.dart';

import 'package:unii_app/data/models/user.dart';
import 'package:unii_app/data/repositories/user_repo.dart';
import 'package:unii_app/modules/profile/profile_controller.dart';

class _MockUserRepo extends Mock implements UserRepo {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockUserRepo repo;

  User sampleUser({String? theme, bool? share, String? engine}) => User(
    id: 1,
    phone: '13800001234',
    username: 'alice',
    needsMapSetup: engine == null,
    theme: theme ?? 'system',
    language: 'zh',
    locationShareEnabled: share ?? true,
    mapEngine: engine,
  );

  setUp(() {
    Get.reset();
    Get.testMode = true;
    repo = _MockUserRepo();
  });

  test('refreshMe loads current user on init', () async {
    when(() => repo.getMe()).thenAnswer((_) async => sampleUser());
    final c = Get.put(ProfileController(repo: repo));

    // onInit() schedules the async refresh; let it complete.
    await Future<void>.delayed(Duration.zero);

    expect(c.user.value?.username, 'alice');
    expect(c.lastError.value, null);
    verify(() => repo.getMe()).called(1);
  });

  test('updateSettings replaces user on success', () async {
    when(() => repo.getMe()).thenAnswer((_) async => sampleUser());
    when(
      () => repo.updateSettings(
        theme: any(named: 'theme'),
        language: any(named: 'language'),
        mapEngine: any(named: 'mapEngine'),
        locationShareEnabled: any(named: 'locationShareEnabled'),
      ),
    ).thenAnswer((_) async => sampleUser(theme: 'dark', engine: 'amap'));

    final c = Get.put(ProfileController(repo: repo));
    await Future<void>.delayed(Duration.zero);

    final ok = await c.updateSettings(theme: 'dark', mapEngine: 'amap');
    expect(ok, true);
    expect(c.user.value?.theme, 'dark');
    expect(c.user.value?.mapEngine, 'amap');
  });

  test('updateSettings records error on failure', () async {
    when(() => repo.getMe()).thenAnswer((_) async => sampleUser());
    when(
      () => repo.updateSettings(
        theme: any(named: 'theme'),
        language: any(named: 'language'),
        mapEngine: any(named: 'mapEngine'),
        locationShareEnabled: any(named: 'locationShareEnabled'),
      ),
    ).thenThrow(Exception('boom'));

    final c = Get.put(ProfileController(repo: repo));
    await Future<void>.delayed(Duration.zero);

    final ok = await c.updateSettings(theme: 'light');
    expect(ok, false);
    expect(c.lastError.value, contains('boom'));
  });
}
