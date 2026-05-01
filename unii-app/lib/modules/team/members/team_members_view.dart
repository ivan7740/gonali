import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import 'package:unii_app/data/models/team.dart';
import 'package:unii_app/data/repositories/team_repo.dart';

class TeamMembersView extends StatefulWidget {
  const TeamMembersView({super.key});

  @override
  State<TeamMembersView> createState() => _TeamMembersViewState();
}

class _TeamMembersViewState extends State<TeamMembersView> {
  late final int teamId;
  Future<List<TeamMember>>? _future;
  Team? _team;

  @override
  void initState() {
    super.initState();
    teamId = Get.arguments as int;
    _load();
  }

  void _load() {
    final repo = Get.find<TeamRepo>();
    setState(() {
      _future = () async {
        _team = await repo.detail(teamId);
        return repo.members(teamId);
      }();
    });
  }

  Future<void> _kick(int userId) async {
    try {
      await Get.find<TeamRepo>().kick(teamId, userId);
      _load();
    } on DioException catch (e) {
      Get.snackbar(
        'team_members'.tr,
        e.response?.data is Map<String, dynamic>
            ? (e.response!.data as Map<String, dynamic>)['msg']?.toString() ??
                  'network_error'.tr
            : 'network_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> _transfer(int userId) async {
    try {
      await Get.find<TeamRepo>().transfer(teamId, userId);
      _load();
      Get.snackbar(
        'team_members'.tr,
        'team_transfer_done'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } on DioException {
      Get.snackbar(
        'team_members'.tr,
        'network_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('team_members'.tr)),
      body: FutureBuilder<List<TeamMember>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text(snap.error.toString()));
          }
          final members = snap.data ?? const [];
          final amOwner = _team?.isOwner ?? false;
          return RefreshIndicator(
            onRefresh: () async => _load(),
            child: ListView.separated(
              itemCount: members.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final m = members[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage:
                        (m.avatarUrl != null && m.avatarUrl!.isNotEmpty)
                        ? NetworkImage(m.avatarUrl!)
                        : null,
                    child: (m.avatarUrl == null || m.avatarUrl!.isEmpty)
                        ? Text(m.username.characters.first.toUpperCase())
                        : null,
                  ),
                  title: Text(
                    (m.nickname?.isNotEmpty ?? false)
                        ? m.nickname!
                        : m.username,
                  ),
                  subtitle: Text(
                    m.isOwner ? 'team_role_owner'.tr : 'team_role_member'.tr,
                  ),
                  trailing: amOwner && !m.isOwner
                      ? PopupMenuButton<String>(
                          onSelected: (v) {
                            if (v == 'kick') _kick(m.userId);
                            if (v == 'transfer') _transfer(m.userId);
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem<String>(
                              value: 'kick',
                              child: Text('team_member_kick'.tr),
                            ),
                            PopupMenuItem<String>(
                              value: 'transfer',
                              child: Text('team_transfer_owner'.tr),
                            ),
                          ],
                        )
                      : null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
