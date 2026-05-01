import 'package:get/get.dart';

import 'package:unii_app/data/repositories/user_repo.dart';
import 'package:unii_app/modules/profile/profile_controller.dart';

class ProfileBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileController>(
      () => ProfileController(repo: Get.find<UserRepo>()),
      fenix: true,
    );
  }
}
