import 'package:get/get.dart' hide Response;

import 'package:unii_app/data/models/user.dart';
import 'package:unii_app/data/repositories/user_repo.dart';

class ProfileController extends GetxController {
  ProfileController({required this.repo});

  final UserRepo repo;

  final user = Rxn<User>();
  final isLoading = false.obs;
  final lastError = RxnString();

  @override
  void onInit() {
    super.onInit();
    refreshMe();
  }

  Future<void> refreshMe() async {
    isLoading.value = true;
    lastError.value = null;
    try {
      user.value = await repo.getMe();
    } on Object catch (e) {
      lastError.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateSettings({
    String? theme,
    String? language,
    String? mapEngine,
    bool? locationShareEnabled,
  }) async {
    try {
      user.value = await repo.updateSettings(
        theme: theme,
        language: language,
        mapEngine: mapEngine,
        locationShareEnabled: locationShareEnabled,
      );
      return true;
    } on Object catch (e) {
      lastError.value = e.toString();
      return false;
    }
  }
}
