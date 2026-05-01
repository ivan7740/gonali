import 'package:get/get.dart';

import 'package:unii_app/data/repositories/auth_repo.dart';
import 'package:unii_app/modules/auth/auth_controller.dart';

class AuthBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthController>(
      () => AuthController(repo: Get.find<AuthRepo>()),
    );
  }
}
