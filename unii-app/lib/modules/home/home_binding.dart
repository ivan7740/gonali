import 'package:get/get.dart';

import 'package:unii_app/core/storage/token_storage.dart';
import 'package:unii_app/data/repositories/auth_repo.dart';
import 'package:unii_app/modules/home/home_controller.dart';

class HomeBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(
        storage: Get.find<TokenStorage>(),
        authRepo: Get.find<AuthRepo>(),
      ),
    );
  }
}
