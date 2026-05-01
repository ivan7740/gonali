import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:unii_app/modules/auth/auth_controller.dart';

class LoginView extends GetView<AuthController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SingleChildScrollView(
              child: Obx(() {
                final isRegister = controller.mode.value == AuthMode.register;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      (isRegister ? 'register_title' : 'login_title').tr,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(labelText: 'phone'.tr),
                      onChanged: (v) => controller.phone.value = v.trim(),
                    ),
                    const SizedBox(height: 16),
                    if (isRegister) ...[
                      TextField(
                        decoration: InputDecoration(labelText: 'username'.tr),
                        onChanged: (v) => controller.username.value = v.trim(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(labelText: 'password'.tr),
                      onChanged: (v) => controller.password.value = v,
                    ),
                    if (isRegister) ...[
                      const SizedBox(height: 16),
                      TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'confirm_password'.tr,
                        ),
                        onChanged: (v) => controller.confirmPassword.value = v,
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: controller.isLoading.value
                          ? null
                          : controller.submit,
                      child: controller.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text('submit'.tr),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => controller.setMode(
                        isRegister ? AuthMode.login : AuthMode.register,
                      ),
                      child: Text(
                        (isRegister ? 'switch_to_login' : 'switch_to_register')
                            .tr,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
