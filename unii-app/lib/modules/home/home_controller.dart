import 'dart:async';

import 'package:get/get.dart';

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/core/location/location_service.dart';
import 'package:unii_app/core/storage/token_storage.dart';
import 'package:unii_app/data/repositories/auth_repo.dart';
import 'package:unii_app/modules/profile/profile_controller.dart';

class HomeController extends GetxController {
  HomeController({
    required this.storage,
    required this.authRepo,
    required this.locationService,
  });

  final TokenStorage storage;
  final AuthRepo authRepo;
  final LocationService locationService;

  final tabIndex = 0.obs;

  Worker? _shareWatcher;

  @override
  void onInit() {
    super.onInit();
    if (!storage.hasAccess) {
      Future.microtask(() => Get.offAllNamed<void>(Routes.login));
      return;
    }
    _wireLocationService();
  }

  /// Start the background location reporter, gated by the user's privacy
  /// switch. Watches `ProfileController.user` so that flipping the toggle
  /// in Profile → Privacy stops/restarts uploads in real time.
  void _wireLocationService() {
    if (!Get.isRegistered<ProfileController>()) return;
    final profile = Get.find<ProfileController>();
    _shareWatcher = ever<dynamic>(profile.user, (_) {
      final shareOn = profile.user.value?.locationShareEnabled ?? true;
      if (shareOn) {
        unawaited(locationService.start());
      } else {
        unawaited(locationService.stop());
      }
    });
    // Kick the initial start once profile is loaded.
    unawaited(locationService.start());
  }

  @override
  void onClose() {
    _shareWatcher?.dispose();
    unawaited(locationService.stop());
    super.onClose();
  }

  Future<void> signOut() async {
    await locationService.stop();
    await authRepo.logout();
    await Get.offAllNamed<void>(Routes.login);
  }
}
