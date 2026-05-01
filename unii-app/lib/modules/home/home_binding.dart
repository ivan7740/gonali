import 'package:get/get.dart';

import 'package:unii_app/core/location/location_service.dart';
import 'package:unii_app/core/storage/token_storage.dart';
import 'package:unii_app/data/repositories/auth_repo.dart';
import 'package:unii_app/data/repositories/team_repo.dart';
import 'package:unii_app/data/repositories/user_repo.dart';
import 'package:unii_app/modules/home/home_controller.dart';
import 'package:unii_app/modules/profile/profile_controller.dart';
import 'package:unii_app/modules/team/team_controller.dart';

class HomeBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(
      () => HomeController(
        storage: Get.find<TokenStorage>(),
        authRepo: Get.find<AuthRepo>(),
        locationService: Get.find<LocationService>(),
      ),
      fenix: true,
    );
    Get.lazyPut<ProfileController>(
      () => ProfileController(repo: Get.find<UserRepo>()),
      fenix: true,
    );
    Get.lazyPut<TeamController>(
      () => TeamController(repo: Get.find<TeamRepo>()),
      fenix: true,
    );
  }
}
