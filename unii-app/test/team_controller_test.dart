import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:mocktail/mocktail.dart';

import 'package:unii_app/data/models/team.dart';
import 'package:unii_app/data/repositories/team_repo.dart';
import 'package:unii_app/modules/team/team_controller.dart';

class _MockTeamRepo extends Mock implements TeamRepo {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockTeamRepo repo;

  Team team({required int id, String name = 'Hikers', int role = 1}) => Team(
    id: id,
    name: name,
    inviteCode: 'AB23XY',
    ownerId: 1,
    memberLimit: 30,
    memberCount: 1,
    myRole: role,
  );

  setUp(() {
    Get.reset();
    Get.testMode = true;
    repo = _MockTeamRepo();
  });

  test('refresh loads teams from repo', () async {
    when(
      () => repo.listMine(),
    ).thenAnswer((_) async => [team(id: 1), team(id: 2, name: 'Climbers')]);
    final c = Get.put(TeamController(repo: repo));
    await Future<void>.delayed(Duration.zero);

    expect(c.teams, hasLength(2));
    expect(c.teams.first.name, 'Hikers');
    expect(c.error.value, isNull);
  });

  test('refresh records error on repo failure', () async {
    when(() => repo.listMine()).thenThrow(Exception('boom'));
    final c = Get.put(TeamController(repo: repo));
    await Future<void>.delayed(Duration.zero);

    expect(c.teams, isEmpty);
    expect(c.error.value, contains('boom'));
  });
}
