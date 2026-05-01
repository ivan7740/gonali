import 'package:get/get.dart' hide Response;

import 'package:unii_app/data/models/activity.dart';
import 'package:unii_app/data/models/team.dart';
import 'package:unii_app/data/repositories/activity_repo.dart';
import 'package:unii_app/data/repositories/team_repo.dart';

class TeamDetailController extends GetxController {
  TeamDetailController({
    required this.teamId,
    required this.teamRepo,
    required this.activityRepo,
  });

  final int teamId;
  final TeamRepo teamRepo;
  final ActivityRepo activityRepo;

  final team = Rxn<Team>();
  final activities = <Activity>[].obs;
  final isLoading = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    refreshAll();
  }

  Future<void> refreshAll() async {
    isLoading.value = true;
    error.value = null;
    try {
      team.value = await teamRepo.detail(teamId);
      activities.value = await activityRepo.listByTeam(teamId);
    } on Object catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
