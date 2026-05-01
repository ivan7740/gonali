import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('about_title'.tr)),
      body: SafeArea(
        child: ListView(
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text('app_version'.tr),
              subtitle: const Text('0.1.0+1'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text('user_agreement'.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _toast('user_agreement'.tr),
            ),
            ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text('privacy_policy'.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _toast('privacy_policy'.tr),
            ),
            ListTile(
              leading: const Icon(Icons.feedback_outlined),
              title: Text('feedback'.tr),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _toast('feedback'.tr),
            ),
          ],
        ),
      ),
    );
  }

  void _toast(String label) {
    Get.snackbar(
      label,
      'coming_soon'.trParams({'wave': '8'}),
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }
}
