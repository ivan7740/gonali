import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/data/models/activity.dart';
import 'package:unii_app/data/repositories/activity_repo.dart';

class ActivityDetailView extends StatefulWidget {
  const ActivityDetailView({super.key});

  @override
  State<ActivityDetailView> createState() => _ActivityDetailViewState();
}

class _ActivityDetailViewState extends State<ActivityDetailView> {
  late final int activityId;
  Future<Activity>? _future;

  @override
  void initState() {
    super.initState();
    activityId = Get.arguments as int;
    _load();
  }

  void _load() {
    setState(() {
      _future = Get.find<ActivityRepo>().detail(activityId);
    });
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('activity_delete_title'.tr),
        content: Text('activity_delete_warning'.tr),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'confirm'.tr,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await Get.find<ActivityRepo>().delete(activityId);
      if (!mounted) return;
      Get.back<void>();
    } on DioException {
      Get.snackbar(
        'activities_title'.tr,
        'network_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('activity_detail'.tr),
        actions: [
          FutureBuilder<Activity>(
            future: _future,
            builder: (ctx, snap) {
              final a = snap.data;
              if (a == null) return const SizedBox.shrink();
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () async {
                      await Get.toNamed<void>(
                        Routes.activityForm,
                        arguments: {'activity': a},
                      );
                      _load();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: _delete,
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<Activity>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString()));
          }
          final a = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(a.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(
                      a.isPublic
                          ? 'visibility_public'.tr
                          : 'visibility_private'.tr,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _kv(context, 'activity_location_name'.tr, a.locationName ?? '-'),
              _kv(
                context,
                'coordinates'.tr,
                '${a.location.lng.toStringAsFixed(5)}, '
                '${a.location.lat.toStringAsFixed(5)}',
              ),
              _kv(context, 'start_time'.tr, a.startTime ?? '-'),
              _kv(context, 'end_time'.tr, a.endTime ?? '-'),
              const SizedBox(height: 16),
              if (a.content != null && a.content!.isNotEmpty) ...[
                Text(
                  'activity_content'.tr,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(a.content!),
                const SizedBox(height: 16),
              ],
              if (a.notice != null && a.notice!.isNotEmpty) ...[
                Text(
                  'activity_notice'.tr,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(a.notice!),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _kv(BuildContext context, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(k)),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
