import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;

import 'package:unii_app/data/models/post.dart';
import 'package:unii_app/data/repositories/post_repo.dart';

class PostDetailView extends StatefulWidget {
  const PostDetailView({super.key});

  @override
  State<PostDetailView> createState() => _PostDetailViewState();
}

class _PostDetailViewState extends State<PostDetailView> {
  late final int postId;
  Post? _post;
  List<PostComment> _comments = const [];
  final _comment = TextEditingController();
  bool _loading = true;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    postId = Get.arguments as int;
    _refresh();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final repo = Get.find<PostRepo>();
      final p = await repo.detail(postId);
      final cs = await repo.listComments(postId);
      if (!mounted) return;
      setState(() {
        _post = p;
        _comments = cs;
        _loading = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleLike() async {
    final post = _post;
    if (post == null) return;
    try {
      final r = await Get.find<PostRepo>().toggleLike(post.id);
      setState(() {
        _post = post.copyWith(likedByMe: r.liked, likeCount: r.likeCount);
      });
    } on DioException {
      // ignore — UI keeps prior state
    }
  }

  Future<void> _sendComment() async {
    final text = _comment.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final added = await Get.find<PostRepo>().createComment(
        postId: postId,
        content: text,
      );
      setState(() {
        _comments = [..._comments, added];
        _post = _post?.copyWith(commentCount: (_post?.commentCount ?? 0) + 1);
        _comment.clear();
      });
    } on DioException catch (e) {
      final raw = e.response?.data;
      Get.snackbar(
        'discover_title'.tr,
        raw is Map<String, dynamic>
            ? (raw['msg']?.toString() ?? 'network_error'.tr)
            : 'network_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('discover_title'.tr)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_post == null) {
      return Scaffold(
        appBar: AppBar(title: Text('discover_title'.tr)),
        body: Center(child: Text(_error ?? 'network_error'.tr)),
      );
    }
    final p = _post!;
    return Scaffold(
      appBar: AppBar(title: Text('discover_title'.tr)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage:
                          (p.authorAvatarUrl != null &&
                              p.authorAvatarUrl!.isNotEmpty)
                          ? NetworkImage(p.authorAvatarUrl!)
                          : null,
                      child:
                          (p.authorAvatarUrl == null ||
                              p.authorAvatarUrl!.isEmpty)
                          ? Text(
                              p.authorDisplayName.characters.first
                                  .toUpperCase(),
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      p.authorDisplayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                if (p.title != null && p.title!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    p.title!,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
                if (p.content != null && p.content!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(p.content!),
                ],
                if (p.media.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  for (final m in p.media)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: m.isImage
                            ? Image.network(
                                m.url,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 160,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.broken_image),
                                ),
                              )
                            : Container(
                                height: 160,
                                color: Theme.of(
                                  context,
                                ).colorScheme.surfaceContainerHighest,
                                child: const Center(
                                  child: Icon(Icons.movie_outlined),
                                ),
                              ),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        p.likedByMe ? Icons.favorite : Icons.favorite_border,
                        color: p.likedByMe
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      onPressed: _toggleLike,
                    ),
                    Text('${p.likeCount}'),
                    const SizedBox(width: 16),
                    const Icon(Icons.chat_bubble_outline, size: 20),
                    const SizedBox(width: 4),
                    Text('${p.commentCount}'),
                  ],
                ),
                const Divider(),
                Text(
                  'comments_title'.tr,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (_comments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text('comments_empty'.tr)),
                  )
                else
                  for (final c in _comments)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        radius: 16,
                        child: Text(
                          c.displayName.characters.first.toUpperCase(),
                        ),
                      ),
                      title: Text(
                        c.displayName,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      subtitle: Text(c.content),
                    ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _comment,
                      decoration: InputDecoration(
                        hintText: 'comment_hint'.tr,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _sendComment,
                    icon: _sending
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
