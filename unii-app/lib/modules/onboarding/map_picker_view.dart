import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:get_storage/get_storage.dart';

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/core/map/map_adapter.dart';
import 'package:unii_app/core/map/map_engine.dart';
import 'package:unii_app/core/map/map_factory.dart';
import 'package:unii_app/data/repositories/user_repo.dart';
import 'package:unii_app/modules/profile/profile_controller.dart';

/// Mandatory first-login engine picker. Must not be dismissable until the
/// user picks (plan §4.2.1).
class MapPickerView extends StatefulWidget {
  const MapPickerView({super.key});

  @override
  State<MapPickerView> createState() => _MapPickerViewState();
}

class _MapPickerViewState extends State<MapPickerView> {
  bool _saving = false;
  String? _error;

  Future<void> _pick(MapEngine engine) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Persist the choice both client-side (so subsequent app launches
      // can hydrate without a backend round-trip) and on the server.
      await GetStorage().write('map_engine', engine.backendValue);
      Get.replace<MapAdapter>(MapFactory.create(engine));
      await Get.find<UserRepo>().updateSettings(mapEngine: engine.backendValue);
      if (Get.isRegistered<ProfileController>()) {
        await Get.find<ProfileController>().refreshMe();
      }
      if (!mounted) return;
      unawaited(Get.offAllNamed<void>(Routes.home));
    } on DioException catch (e) {
      final raw = e.response?.data;
      setState(() {
        _error = raw is Map<String, dynamic>
            ? (raw['msg']?.toString() ?? 'network_error'.tr)
            : 'network_error'.tr;
      });
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Text(
                  'map_picker_title'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  'map_picker_subtitle'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),
                _EngineCard(
                  flag: '🇨🇳',
                  title: 'map_amap'.tr,
                  description: 'map_picker_amap_help'.tr,
                  onTap: _saving ? null : () => _pick(MapEngine.amap),
                ),
                const SizedBox(height: 16),
                _EngineCard(
                  flag: '🌍',
                  title: 'map_osm'.tr,
                  description: 'map_picker_osm_help'.tr,
                  onTap: _saving ? null : () => _pick(MapEngine.osm),
                ),
                const SizedBox(height: 24),
                Text(
                  'map_picker_footer'.tr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                if (_saving) ...[
                  const SizedBox(height: 16),
                  const Center(child: CircularProgressIndicator()),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EngineCard extends StatelessWidget {
  const _EngineCard({
    required this.flag,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String flag;
  final String title;
  final String description;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(flag, style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
