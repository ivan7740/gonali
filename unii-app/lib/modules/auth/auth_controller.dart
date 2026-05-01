import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/data/repositories/auth_repo.dart';

enum AuthMode { login, register }

typedef Notify = void Function(String title, String message);

void _defaultNotify(String title, String message) {
  if (Get.context == null) return;
  Get.snackbar(
    title,
    message,
    snackPosition: SnackPosition.BOTTOM,
    margin: const EdgeInsets.all(16),
  );
}

class AuthController extends GetxController {
  AuthController({required this.repo, Notify? notify})
    : notify = notify ?? _defaultNotify;

  final AuthRepo repo;
  final Notify notify;

  final mode = AuthMode.login.obs;
  final isLoading = false.obs;

  final phone = ''.obs;
  final password = ''.obs;
  final confirmPassword = ''.obs;
  final username = ''.obs;

  /// Last toast emitted — exposed for tests; mirrors what was passed to [notify].
  final lastToast = Rxn<({String title, String message})>();

  void setMode(AuthMode m) {
    mode.value = m;
  }

  bool _validatePhone() {
    final re = RegExp(r'^1[3-9]\d{9}$');
    return re.hasMatch(phone.value);
  }

  bool _validatePassword() {
    final p = password.value;
    if (p.length < 8 || p.length > 64) return false;
    final hasLetter = p.contains(RegExp(r'[A-Za-z]'));
    final hasDigit = p.contains(RegExp(r'\d'));
    return hasLetter && hasDigit;
  }

  Future<void> submit() async {
    if (!_validatePhone()) {
      _toast('invalid_phone'.tr);
      return;
    }
    if (!_validatePassword()) {
      _toast('invalid_password'.tr);
      return;
    }
    if (mode.value == AuthMode.register &&
        password.value != confirmPassword.value) {
      _toast('passwords_dont_match'.tr);
      return;
    }

    isLoading.value = true;
    try {
      if (mode.value == AuthMode.register) {
        await repo.register(
          phone: phone.value,
          password: password.value,
          username: username.value.isEmpty
              ? 'u${phone.value.substring(7)}'
              : username.value,
        );
      } else {
        await repo.login(phone: phone.value, password: password.value);
      }
      unawaited(Get.offAllNamed<void>(Routes.home));
    } on DioException catch (e) {
      final raw = e.response?.data;
      final msg = raw is Map<String, dynamic> ? raw['msg']?.toString() : null;
      _toast(msg ?? 'network_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }

  void _toast(String message) {
    final title = 'login_failed'.tr;
    lastToast.value = (title: title, message: message);
    notify(title, message);
  }
}
