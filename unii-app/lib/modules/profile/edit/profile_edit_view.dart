import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:unii_app/data/repositories/user_repo.dart';
import 'package:unii_app/modules/profile/edit/profile_edit_controller.dart';
import 'package:unii_app/modules/profile/profile_controller.dart';

class ProfileEditView extends StatelessWidget {
  const ProfileEditView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(
      ProfileEditController(
        repo: Get.find<UserRepo>(),
        profile: Get.find<ProfileController>(),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text('profile_edit'.tr)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              _field('username', c.username),
              _field('nickname', c.nickname),
              _field('email', c.email, keyboard: TextInputType.emailAddress),
              _field('city', c.city),
              _field('occupation', c.occupation),
              const SizedBox(height: 8),
              Obx(
                () => DropdownButtonFormField<int?>(
                  value: c.gender.value,
                  decoration: InputDecoration(labelText: 'gender'.tr),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text('unspecified'.tr),
                    ),
                    DropdownMenuItem(
                      value: 0,
                      child: Text('gender_unknown'.tr),
                    ),
                    DropdownMenuItem(value: 1, child: Text('gender_male'.tr)),
                    DropdownMenuItem(value: 2, child: Text('gender_female'.tr)),
                  ],
                  onChanged: (v) => c.gender.value = v,
                ),
              ),
              const SizedBox(height: 16),
              _field('birthday', c.birthday, hint: 'YYYY-MM-DD'),
              const SizedBox(height: 24),
              Obx(
                () => FilledButton(
                  onPressed: c.isSaving.value
                      ? null
                      : () async {
                          final ok = await c.save();
                          if (ok) Get.back<void>();
                        },
                  child: c.isSaving.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('save'.tr),
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => c.error.value == null
                    ? const SizedBox.shrink()
                    : Text(
                        c.error.value!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    String labelKey,
    RxString rx, {
    TextInputType? keyboard,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        initialValue: rx.value,
        keyboardType: keyboard,
        decoration: InputDecoration(labelText: labelKey.tr, hintText: hint),
        onChanged: (v) => rx.value = v,
      ),
    );
  }
}
