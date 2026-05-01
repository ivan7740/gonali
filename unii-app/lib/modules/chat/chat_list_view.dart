import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/data/models/chat.dart';
import 'package:unii_app/modules/chat/chat_list_controller.dart';

class ChatListView extends GetView<ChatListController> {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('tab_chat'.tr),
        actions: [
          IconButton(
            tooltip: 'chat_start_new'.tr,
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: () => Get.toNamed<void>(
              Routes.chatPicker,
            )?.then((_) => controller.reload()),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.reload,
        child: Obx(() {
          if (controller.isLoading.value && controller.conversations.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.conversations.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                Center(child: Text('chat_empty'.tr)),
              ],
            );
          }
          return ListView.separated(
            itemCount: controller.conversations.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = controller.conversations[i];
              return _ConversationTile(conv: c);
            },
          );
        }),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({required this.conv});

  final Conversation conv;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage:
            (conv.otherAvatarUrl != null && conv.otherAvatarUrl!.isNotEmpty)
            ? NetworkImage(conv.otherAvatarUrl!)
            : null,
        child: (conv.otherAvatarUrl == null || conv.otherAvatarUrl!.isEmpty)
            ? Text(conv.displayName.characters.first.toUpperCase())
            : null,
      ),
      title: Text(conv.displayName),
      subtitle: Text(
        conv.lastMessagePreview ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: conv.unreadCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${conv.unreadCount}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 12,
                ),
              ),
            )
          : const Icon(Icons.chevron_right),
      onTap: () => Get.toNamed<void>(
        Routes.conversation,
        arguments: {'conversationId': conv.id, 'displayName': conv.displayName},
      ),
    );
  }
}
