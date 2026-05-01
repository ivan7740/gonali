import 'package:get/get.dart';

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/core/storage/token_storage.dart';
import 'package:unii_app/data/repositories/auth_repo.dart';

class HomeController extends GetxController {
  HomeController({required this.storage, required this.authRepo});

  final TokenStorage storage;
  final AuthRepo authRepo;

  final tabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    if (!storage.hasAccess) {
      Future.microtask(() => Get.offAllNamed<void>(Routes.login));
    }
  }

  Future<void> signOut() async {
    await authRepo.logout();
    await Get.offAllNamed<void>(Routes.login);
  }
}
