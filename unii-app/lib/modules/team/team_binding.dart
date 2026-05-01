import 'package:get/get.dart';

import 'package:unii_app/data/repositories/team_repo.dart';
import 'package:unii_app/modules/team/team_controller.dart';

class TeamBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TeamController>(
      () => TeamController(repo: Get.find<TeamRepo>()),
      fenix: true,
    );
  }
}
