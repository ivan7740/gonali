import 'package:get/get.dart' hide Response;

import 'package:unii_app/data/models/team.dart';
import 'package:unii_app/data/repositories/team_repo.dart';

class TeamController extends GetxController {
  TeamController({required this.repo});

  final TeamRepo repo;

  final teams = <Team>[].obs;
  final isLoading = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    isLoading.value = true;
    error.value = null;
    try {
      teams.value = await repo.listMine();
    } on Object catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
