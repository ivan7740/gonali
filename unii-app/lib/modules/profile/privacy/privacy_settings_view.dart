import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:unii_app/modules/profile/profile_controller.dart';

class PrivacySettingsView extends StatelessWidget {
  const PrivacySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileController>();
    return Scaffold(
      appBar: AppBar(title: Text('privacy_title'.tr)),
      body: SafeArea(
        child: Obx(() {
          final u = profile.user.value;
          final shareEnabled = u?.locationShareEnabled ?? true;
          return ListView(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.location_on_outlined),
                title: Text('location_share'.tr),
                subtitle: Text('location_share_help'.tr),
                value: shareEnabled,
                onChanged: (v) async {
                  await profile.updateSettings(locationShareEnabled: v);
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_add_outlined),
                title: Text('friend_request_visibility'.tr),
                trailing: Text('coming_soon'.trParams({'wave': '7'})),
                enabled: false,
              ),
            ],
          );
        }),
      ),
    );
  }
}
