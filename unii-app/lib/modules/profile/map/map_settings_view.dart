import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:unii_app/modules/profile/profile_controller.dart';

/// W2 placeholder — lets the user record their preference (`amap`/`osm`) and
/// persist it via `PUT /me/settings`. The actual map renderer ships in W4.
class MapSettingsView extends StatelessWidget {
  const MapSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = Get.find<ProfileController>();
    return Scaffold(
      appBar: AppBar(title: Text('map_settings'.tr)),
      body: SafeArea(
        child: Obx(() {
          final engine = profile.user.value?.mapEngine;
          return ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'map_settings_help'.tr,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              RadioListTile<String>(
                value: 'amap',
                groupValue: engine,
                title: Text('map_amap'.tr),
                subtitle: Text('map_amap_help'.tr),
                onChanged: (v) {
                  if (v != null) profile.updateSettings(mapEngine: v);
                },
              ),
              RadioListTile<String>(
                value: 'osm',
                groupValue: engine,
                title: Text('map_osm'.tr),
                subtitle: Text('map_osm_help'.tr),
                onChanged: (v) {
                  if (v != null) profile.updateSettings(mapEngine: v);
                },
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'coming_soon'.trParams({'wave': '4'}),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}
