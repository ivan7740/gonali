import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;

import 'package:unii_app/data/repositories/user_repo.dart';
import 'package:unii_app/modules/profile/profile_controller.dart';

class ProfileEditController extends GetxController {
  ProfileEditController({required this.repo, required this.profile});

  final UserRepo repo;
  final ProfileController profile;

  final username = ''.obs;
  final nickname = ''.obs;
  final email = ''.obs;
  final city = ''.obs;
  final occupation = ''.obs;
  final gender = RxnInt();
  final birthday = ''.obs;
  final isSaving = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    final u = profile.user.value;
    if (u != null) {
      username.value = u.username;
      nickname.value = u.nickname ?? '';
      email.value = u.email ?? '';
      city.value = u.city ?? '';
      occupation.value = u.occupation ?? '';
      gender.value = u.gender;
      birthday.value = u.birthday ?? '';
    }
  }

  Future<bool> save() async {
    isSaving.value = true;
    error.value = null;
    try {
      final updated = await repo.updateProfile(
        username: username.value.trim().isEmpty ? null : username.value.trim(),
        nickname: nickname.value,
        email: email.value,
        city: city.value,
        occupation: occupation.value,
        gender: gender.value,
        birthday: birthday.value.isEmpty ? null : birthday.value,
      );
      profile.user.value = updated;
      return true;
    } on DioException catch (e) {
      final raw = e.response?.data;
      error.value = raw is Map<String, dynamic>
          ? (raw['msg']?.toString() ?? 'network_error'.tr)
          : 'network_error'.tr;
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}
