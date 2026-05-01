import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Response;

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/data/models/activity.dart';
import 'package:unii_app/data/repositories/activity_repo.dart';
import 'package:unii_app/data/repositories/team_repo.dart';
import 'package:unii_app/modules/team/detail/team_detail_controller.dart';
import 'package:unii_app/modules/team/detail/team_map_widget.dart';
import 'package:unii_app/modules/team/team_controller.dart';

class TeamDetailView extends StatelessWidget {
  const TeamDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final teamId = Get.arguments as int;
    final tag = 'team_$teamId';
    final c = Get.put(
      TeamDetailController(
        teamId: teamId,
        teamRepo: Get.find<TeamRepo>(),
        activityRepo: Get.find<ActivityRepo>(),
      ),
      tag: tag,
    );

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(c.team.value?.name ?? 'team_detail'.tr)),
        actions: [
          Obx(() {
            final t = c.team.value;
            if (t == null) return const SizedBox.shrink();
            return PopupMenuButton<String>(
              onSelected: (v) async {
                if (v == 'leave') {
                  final ok = await _confirm(
                    context,
                    title: 'team_leave_title'.tr,
                    body: 'team_leave_warning'.tr,
                  );
                  if (ok != true) return;
                  await Get.find<TeamRepo>().leave(t.id);
                  if (Get.isRegistered<TeamController>()) {
                    await Get.find<TeamController>().reload();
                  }
                  Get.back<void>();
                } else if (v == 'disband') {
                  final ok = await _confirm(
                    context,
                    title: 'team_disband_title'.tr,
                    body: 'team_disband_warning'.tr,
                  );
                  if (ok != true) return;
                  await Get.find<TeamRepo>().disband(t.id);
                  if (Get.isRegistered<TeamController>()) {
                    await Get.find<TeamController>().reload();
                  }
                  Get.back<void>();
                }
              },
              itemBuilder: (ctx) => [
                if (!t.isOwner)
                  PopupMenuItem<String>(
                    value: 'leave',
                    child: Text('team_leave'.tr),
                  ),
                if (t.isOwner)
                  PopupMenuItem<String>(
                    value: 'disband',
                    child: Text('team_disband'.tr),
                  ),
              ],
            );
          }),
        ],
      ),
      floatingActionButton: Obx(() {
        if (c.team.value == null) return const SizedBox.shrink();
        return FloatingActionButton(
          onPressed: () => Get.toNamed<void>(
            Routes.activityForm,
            arguments: {'teamId': teamId},
          )?.then((_) => c.refreshAll()),
          child: const Icon(Icons.add),
        );
      }),
      body: RefreshIndicator(
        onRefresh: c.refreshAll,
        child: Obx(() {
          final t = c.team.value;
          if (c.isLoading.value && t == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (t == null) {
            return Center(child: Text(c.error.value ?? 'network_error'.tr));
          }
          return ListView(
            children: [
              SizedBox(height: 220, child: TeamMapWidget(teamId: teamId)),
              const Divider(height: 1),
              _Header(controller: c),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: Text('team_members'.tr),
                trailing: Text('${t.memberCount}'),
                onTap: () =>
                    Get.toNamed<void>(Routes.teamMembers, arguments: teamId),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'activities_title'.tr,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              if (c.activities.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text('activities_empty'.tr)),
                )
              else
                ...c.activities.map(
                  (a) => _ActivityTile(activity: a, onChanged: c.refreshAll),
                ),
            ],
          );
        }),
      ),
    );
  }

  Future<bool?> _confirm(
    BuildContext context, {
    required String title,
    required String body,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
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
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.controller});

  final TeamDetailController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final t = controller.team.value;
      if (t == null) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (t.description != null && t.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  t.description!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            Row(
              children: [
                const Icon(Icons.tag, size: 18),
                const SizedBox(width: 4),
                Text(
                  '${'invite_code'.tr}: ${t.inviteCode}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(width: 8),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: t.inviteCode));
                    Get.snackbar(
                      'invite_code'.tr,
                      'copied'.tr,
                      snackPosition: SnackPosition.BOTTOM,
                      margin: const EdgeInsets.all(16),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.activity, required this.onChanged});

  final Activity activity;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[];
    if (activity.locationName != null && activity.locationName!.isNotEmpty) {
      subtitleParts.add(activity.locationName!);
    }
    if (activity.startTime != null) {
      subtitleParts.add(activity.startTime!.split('T').first);
    }
    return ListTile(
      leading: Icon(
        activity.isPublic ? Icons.public : Icons.lock_outline,
        color: activity.isPublic ? null : Theme.of(context).colorScheme.primary,
      ),
      title: Text(activity.title),
      subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Get.toNamed<void>(
        Routes.activityDetail,
        arguments: activity.id,
      )?.then((_) => onChanged()),
    );
  }
}
