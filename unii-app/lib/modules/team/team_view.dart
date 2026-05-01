import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/data/models/team.dart';
import 'package:unii_app/modules/team/team_controller.dart';

class TeamView extends GetView<TeamController> {
  const TeamView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('tab_team'.tr),
        actions: [
          IconButton(
            tooltip: 'team_join'.tr,
            icon: const Icon(Icons.qr_code_2),
            onPressed: () => Get.toNamed<void>(Routes.teamJoin),
          ),
          IconButton(
            tooltip: 'team_create'.tr,
            icon: const Icon(Icons.add),
            onPressed: () => Get.toNamed<void>(Routes.teamCreate),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.reload,
        child: Obx(() {
          if (controller.isLoading.value && controller.teams.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.teams.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                Center(child: Text('teams_empty'.tr)),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton(
                    onPressed: () => Get.toNamed<void>(Routes.teamCreate),
                    child: Text('team_create'.tr),
                  ),
                ),
              ],
            );
          }
          return ListView.separated(
            itemCount: controller.teams.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final t = controller.teams[i];
              return _TeamTile(team: t);
            },
          );
        }),
      ),
    );
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({required this.team});

  final Team team;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: (team.avatarUrl != null && team.avatarUrl!.isNotEmpty)
            ? NetworkImage(team.avatarUrl!)
            : null,
        child: (team.avatarUrl == null || team.avatarUrl!.isEmpty)
            ? Text(
                team.name.isEmpty ? '?' : team.name.characters.first,
                style: const TextStyle(fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(team.name),
      subtitle: Text(
        '${'team_members_count'.trParams({'n': '${team.memberCount}', 'limit': '${team.memberLimit}'})}'
        '${team.isOwner ? "  ·  ${'team_role_owner'.tr}" : ""}',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Get.toNamed<void>(Routes.teamDetail, arguments: team.id),
    );
  }
}
