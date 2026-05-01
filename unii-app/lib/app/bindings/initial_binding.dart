import 'package:dio/dio.dart';
import 'package:get/get.dart';

import 'package:unii_app/core/i18n/locale_controller.dart';
import 'package:unii_app/core/network/dio_client.dart';
import 'package:unii_app/core/storage/token_storage.dart';
import 'package:unii_app/core/theme/theme_controller.dart';
import 'package:unii_app/data/repositories/auth_repo.dart';
import 'package:unii_app/data/repositories/user_repo.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<TokenStorage>(TokenStorage(), permanent: true);
    Get.put<Dio>(
      DioClient.build(storage: Get.find<TokenStorage>()),
      permanent: true,
    );
    Get.put<AuthRepo>(
      AuthRepo(dio: Get.find<Dio>(), storage: Get.find<TokenStorage>()),
      permanent: true,
    );
    Get.put<UserRepo>(UserRepo(dio: Get.find<Dio>()), permanent: true);
    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.put<LocaleController>(LocaleController(), permanent: true);
  }
}
