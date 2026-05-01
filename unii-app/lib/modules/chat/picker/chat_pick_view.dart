import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/core/storage/token_storage.dart';
import 'package:unii_app/data/models/team.dart';
import 'package:unii_app/data/repositories/chat_repo.dart';
import 'package:unii_app/data/repositories/team_repo.dart';
import 'package:unii_app/modules/team/team_controller.dart';

/// Lets the user pick a teammate to start a 1:1 chat with. Pulls from
/// teams the user has joined and unions their members.
class ChatPickView extends StatefulWidget {
  const ChatPickView({super.key});

  @override
  State<ChatPickView> createState() => _ChatPickViewState();
}

class _ChatPickViewState extends State<ChatPickView> {
  Future<List<TeamMember>>? _future;

  @override
  void initState() {
    super.initState();
    _future = _loadCandidates();
  }

  Future<List<TeamMember>> _loadCandidates() async {
    final teamRepo = Get.find<TeamRepo>();
    final myId = Get.find<TokenStorage>().userId();

    var teams = Get.isRegistered<TeamController>()
        ? Get.find<TeamController>().teams.toList(growable: false)
        : <Team>[];
    if (teams.isEmpty) {
      teams = await teamRepo.listMine();
    }

    final seen = <int>{};
    final out = <TeamMember>[];
    for (final t in teams) {
      final members = await teamRepo.members(t.id);
      for (final m in members) {
        if (m.userId == myId) continue;
        if (seen.add(m.userId)) out.add(m);
      }
    }
    return out;
  }

  Future<void> _open(TeamMember m) async {
    try {
      final id = await Get.find<ChatRepo>().startWith(m.userId);
      if (!mounted) return;
      Get.back<void>();
      unawaited(
        Get.toNamed<void>(
          Routes.conversation,
          arguments: {'conversationId': id, 'displayName': _label(m)},
        ),
      );
    } on DioException {
      Get.snackbar(
        'tab_chat'.tr,
        'network_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  String _label(TeamMember m) =>
      (m.nickname?.isNotEmpty ?? false) ? m.nickname! : m.username;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('chat_start_new'.tr)),
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
          if (members.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text('chat_no_candidates'.tr)),
            );
          }
          return ListView.separated(
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
                      ? Text(_label(m).characters.first.toUpperCase())
                      : null,
                ),
                title: Text(_label(m)),
                subtitle: Text(m.username),
                onTap: () => _open(m),
              );
            },
          );
        },
      ),
    );
  }
}
