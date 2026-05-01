import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:image_picker/image_picker.dart';

import 'package:unii_app/data/models/moment.dart';
import 'package:unii_app/data/repositories/media_repo.dart';
import 'package:unii_app/data/repositories/moment_repo.dart';

class MomentsView extends StatefulWidget {
  const MomentsView({super.key});

  @override
  State<MomentsView> createState() => _MomentsViewState();
}

class _MomentsViewState extends State<MomentsView> {
  late final int _teamId;
  Future<List<Moment>>? _future;

  @override
  void initState() {
    super.initState();
    _teamId = Get.arguments as int;
    _refresh();
  }

  void _refresh() {
    setState(() {
      _future = Get.find<MomentRepo>().list(teamId: _teamId);
    });
  }

  Future<void> _create() async {
    final result = await Get.dialog<_NewMomentInput>(
      const _NewMomentDialog(),
      barrierDismissible: true,
    );
    if (result == null) return;
    if (result.content.isEmpty && result.images.isEmpty) return;

    try {
      final mediaIds = <int>[];
      for (final img in result.images) {
        final uploaded = await Get.find<MediaRepo>().uploadBytes(
          bytes: img.bytes,
          filename: img.name,
        );
        mediaIds.add(uploaded.id);
      }
      await Get.find<MomentRepo>().create(
        teamId: _teamId,
        content: result.content.isEmpty ? null : result.content,
        mediaIds: mediaIds,
      );
      _refresh();
    } on DioException catch (e) {
      final raw = e.response?.data;
      Get.snackbar(
        'team_moments_title'.tr,
        raw is Map<String, dynamic>
            ? (raw['msg']?.toString() ?? 'network_error'.tr)
            : 'network_error'.tr,
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('team_moments_title'.tr)),
      floatingActionButton: FloatingActionButton(
        onPressed: _create,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<Moment>>(
          future: _future,
          builder: (ctx, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(child: Text(snap.error.toString()));
            }
            final ms = snap.data ?? const [];
            if (ms.isEmpty) {
              return ListView(
                children: [
                  const SizedBox(height: 80),
                  Center(child: Text('team_moments_empty'.tr)),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: ms.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _MomentTile(moment: ms[i]),
            );
          },
        ),
      ),
    );
  }
}

class _MomentTile extends StatelessWidget {
  const _MomentTile({required this.moment});

  final Moment moment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage:
                    (moment.authorAvatarUrl != null &&
                        moment.authorAvatarUrl!.isNotEmpty)
                    ? NetworkImage(moment.authorAvatarUrl!)
                    : null,
                child:
                    (moment.authorAvatarUrl == null ||
                        moment.authorAvatarUrl!.isEmpty)
                    ? Text(moment.displayName.characters.first.toUpperCase())
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                moment.displayName,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const Spacer(),
              if (moment.createdAt != null)
                Text(
                  moment.createdAt!.split('T').first,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
          if (moment.content != null && moment.content!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(moment.content!),
          ],
          if (moment.media.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: moment.media.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final m = moment.media[i];
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
        ],
      ),
    );
  }
}

class _NewMomentInput {
  const _NewMomentInput({required this.content, required this.images});
  final String content;
  final List<_PickedImage> images;
}

class _PickedImage {
  const _PickedImage({required this.name, required this.bytes});
  final String name;
  final Uint8List bytes;
}

class _NewMomentDialog extends StatefulWidget {
  const _NewMomentDialog();

  @override
  State<_NewMomentDialog> createState() => _NewMomentDialogState();
}

class _NewMomentDialogState extends State<_NewMomentDialog> {
  final _content = TextEditingController();
  final _images = <_PickedImage>[];

  @override
  void dispose() {
    _content.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final picker = ImagePicker();
    final imgs = await picker.pickMultiImage(imageQuality: 85);
    if (imgs.isEmpty) return;
    final picked = await Future.wait(
      imgs.map(
        (x) async => _PickedImage(name: x.name, bytes: await x.readAsBytes()),
      ),
    );
    setState(() => _images.addAll(picked));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('team_moments_create'.tr),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _content,
              maxLines: 4,
              decoration: InputDecoration(hintText: 'post_content'.tr),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pick,
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text('post_add_images'.tr),
                ),
                const SizedBox(width: 8),
                Text('${_images.length}'),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back<void>(), child: Text('cancel'.tr)),
        FilledButton(
          onPressed: () => Get.back<_NewMomentInput>(
            result: _NewMomentInput(
              content: _content.text.trim(),
              images: _images,
            ),
          ),
          child: Text('submit'.tr),
        ),
      ],
    );
  }
}
