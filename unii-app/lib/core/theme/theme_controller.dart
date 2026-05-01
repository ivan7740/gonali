import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ThemeController extends GetxController {
  static const _storageKey = 'theme_mode';

  final _box = GetStorage();
  final mode = ThemeMode.system.obs;

  @override
  void onInit() {
    super.onInit();
    final stored = _box.read<String>(_storageKey);
    if (stored != null) {
      mode.value = _parse(stored);
    }
  }

  /// [value] is one of `system` / `light` / `dark` (matches backend).
  Future<void> setBackendValue(String value) async {
    mode.value = _parse(value);
    await _box.write(_storageKey, value);
    Get.changeThemeMode(mode.value);
  }

  String get backendValue => switch (mode.value) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  ThemeMode _parse(String s) => switch (s) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
