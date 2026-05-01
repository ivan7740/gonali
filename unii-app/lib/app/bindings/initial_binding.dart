import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:unii_app/core/i18n/locale_controller.dart';
import 'package:unii_app/core/location/location_service.dart';
import 'package:unii_app/core/map/map_adapter.dart';
import 'package:unii_app/core/map/map_engine.dart';
import 'package:unii_app/core/map/map_factory.dart';
import 'package:unii_app/core/network/dio_client.dart';
import 'package:unii_app/core/storage/token_storage.dart';
import 'package:unii_app/core/theme/theme_controller.dart';
import 'package:unii_app/data/repositories/activity_repo.dart';
import 'package:unii_app/data/repositories/auth_repo.dart';
import 'package:unii_app/data/repositories/location_repo.dart';
import 'package:unii_app/data/repositories/team_repo.dart';
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
    Get.put<TeamRepo>(TeamRepo(dio: Get.find<Dio>()), permanent: true);
    Get.put<ActivityRepo>(ActivityRepo(dio: Get.find<Dio>()), permanent: true);
    Get.put<LocationRepo>(LocationRepo(dio: Get.find<Dio>()), permanent: true);
    Get.put<ThemeController>(ThemeController(), permanent: true);
    Get.put<LocaleController>(LocaleController(), permanent: true);

    // Hydrate the persisted MapEngine choice (null until the first-login
    // picker dialog runs). We register an OSM default so any code that calls
    // Get.find<MapAdapter>() before the picker still works; the picker
    // overwrites it via Get.replace once the user chooses.
    final box = GetStorage();
    final stored = box.read<String>('map_engine');
    final initial = MapEngine.fromBackend(stored) ?? MapEngine.osm;
    Get.put<MapAdapter>(MapFactory.create(initial), permanent: true);

    Get.put<LocationService>(
      LocationService(repo: Get.find<LocationRepo>()),
      permanent: true,
    );
  }
}
