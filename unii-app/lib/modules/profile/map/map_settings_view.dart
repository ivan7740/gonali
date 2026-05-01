import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:unii_app/core/map/map_adapter.dart';
import 'package:unii_app/core/map/map_engine.dart';
import 'package:unii_app/core/map/map_factory.dart';
import 'package:unii_app/modules/profile/profile_controller.dart';

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
                onChanged: (v) => _switch(profile, v),
              ),
              RadioListTile<String>(
                value: 'osm',
                groupValue: engine,
                title: Text('map_osm'.tr),
                subtitle: Text('map_osm_help'.tr),
                onChanged: (v) => _switch(profile, v),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'amap_native_note'.tr,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _switch(ProfileController profile, String? v) async {
    if (v == null) return;
    final engine = MapEngine.fromBackend(v);
    if (engine == null) return;
    await GetStorage().write('map_engine', v);
    Get.replace<MapAdapter>(MapFactory.create(engine));
    await profile.updateSettings(mapEngine: v);
  }
}
