import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LocaleController extends GetxController {
  static const _storageKey = 'app_locale';

  final _box = GetStorage();
  final locale = const Locale('zh').obs;

  @override
  void onInit() {
    super.onInit();
    final stored = _box.read<String>(_storageKey);
    if (stored != null) {
      locale.value = Locale(stored);
    } else {
      final device = Get.deviceLocale;
      if (device != null && device.languageCode == 'en') {
        locale.value = const Locale('en');
      }
    }
  }

  /// [code] is `zh` / `en` (matches backend `language`).
  Future<void> setBackendValue(String code) async {
    locale.value = Locale(code);
    await _box.write(_storageKey, code);
    await Get.updateLocale(locale.value);
  }

  String get backendValue => locale.value.languageCode;
}
