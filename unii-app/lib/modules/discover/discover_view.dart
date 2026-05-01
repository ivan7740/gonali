import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import 'package:unii_app/app/routes/app_routes.dart';
import 'package:unii_app/data/models/post.dart';
import 'package:unii_app/modules/discover/discover_controller.dart';

class DiscoverView extends GetView<DiscoverController> {
  const DiscoverView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('tab_discover'.tr)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed<void>(
          Routes.postCreate,
        )?.then((_) => controller.reload()),
        child: const Icon(Icons.edit),
      ),
      body: RefreshIndicator(
        onRefresh: controller.reload,
        child: Obx(() {
          if (controller.isLoading.value && controller.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.posts.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 80),
                Center(child: Text('discover_empty'.tr)),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: controller.posts.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final p = controller.posts[i];
              return _PostCard(post: p);
            },
          );
        }),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    final c = Get.find<DiscoverController>();
    return InkWell(
      onTap: () => Get.toNamed<void>(
        Routes.postDetail,
        arguments: post.id,
      )?.then((_) => c.reload()),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage:
                      (post.authorAvatarUrl != null &&
                          post.authorAvatarUrl!.isNotEmpty)
                      ? NetworkImage(post.authorAvatarUrl!)
                      : null,
                  child:
                      (post.authorAvatarUrl == null ||
                          post.authorAvatarUrl!.isEmpty)
                      ? Text(
                          post.authorDisplayName.characters.first.toUpperCase(),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    post.authorDisplayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (post.postType == 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'post_type_activity'.tr,
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
              ],
            ),
            if (post.title != null && post.title!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(post.title!, style: Theme.of(context).textTheme.titleMedium),
            ],
            if (post.content != null && post.content!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(post.content!, maxLines: 4, overflow: TextOverflow.ellipsis),
            ],
            if (post.media.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 96,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: post.media.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final m = post.media[i];
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: m.isImage
                          ? Image.network(
                              m.url,
                              width: 96,
                              height: 96,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 96,
                                height: 96,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                child: const Icon(Icons.broken_image),
                              ),
                            )
                          : Container(
                              width: 96,
                              height: 96,
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              child: const Center(
                                child: Icon(Icons.movie_outlined),
                              ),
                            ),
                    );
                  },
                ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    post.likedByMe ? Icons.favorite : Icons.favorite_border,
                    color: post.likedByMe
                        ? Theme.of(context).colorScheme.primary
                        : null,
                    size: 20,
                  ),
                  onPressed: () => c.toggleLike(post.id),
                ),
                Text('${post.likeCount}'),
                const SizedBox(width: 16),
                const Icon(Icons.chat_bubble_outline, size: 18),
                const SizedBox(width: 4),
                Text('${post.commentCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
