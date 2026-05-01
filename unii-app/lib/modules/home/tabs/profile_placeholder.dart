import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:unii_app/modules/home/home_controller.dart';

class ProfilePlaceholder extends StatelessWidget {
  const ProfilePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('tab_profile'.tr),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Get.find<HomeController>().signOut(),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'coming_soon'.trParams({'wave': '2'}),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
