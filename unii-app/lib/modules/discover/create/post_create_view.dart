import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:image_picker/image_picker.dart';

import 'package:unii_app/data/repositories/media_repo.dart';
import 'package:unii_app/data/repositories/post_repo.dart';

class PostCreateView extends StatefulWidget {
  const PostCreateView({super.key});

  @override
  State<PostCreateView> createState() => _PostCreateViewState();
}

class _PostCreateViewState extends State<PostCreateView> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  final _picked = <_PickedImage>[];
  String _visibility = 'public';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;
    final picked = await Future.wait(
      images.map(
        (x) async => _PickedImage(name: x.name, bytes: await x.readAsBytes()),
      ),
    );
    setState(() => _picked.addAll(picked));
  }

  Future<void> _submit() async {
    final hasText =
        _title.text.trim().isNotEmpty || _content.text.trim().isNotEmpty;
    if (!hasText && _picked.isEmpty) {
      setState(() => _error = 'post_empty'.tr);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final mediaIds = <int>[];
      for (final img in _picked) {
        final uploaded = await Get.find<MediaRepo>().uploadBytes(
          bytes: img.bytes,
          filename: img.name,
        );
        mediaIds.add(uploaded.id);
      }
      await Get.find<PostRepo>().create(
        title: _title.text.trim().isEmpty ? null : _title.text.trim(),
        content: _content.text.trim().isEmpty ? null : _content.text.trim(),
        visibility: _visibility,
        mediaIds: mediaIds,
      );
      if (!mounted) return;
      Get.back<void>();
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
    return Scaffold(
      appBar: AppBar(title: Text('post_create'.tr)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              TextField(
                controller: _title,
                decoration: InputDecoration(labelText: 'post_title'.tr),
                maxLength: 200,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _content,
                maxLines: 6,
                decoration: InputDecoration(labelText: 'post_content'.tr),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _visibility,
                decoration: InputDecoration(labelText: 'visibility'.tr),
                items: [
                  DropdownMenuItem(
                    value: 'public',
                    child: Text('visibility_public'.tr),
                  ),
                  DropdownMenuItem(
                    value: 'private',
                    child: Text('visibility_private'.tr),
                  ),
                ],
                onChanged: (v) => setState(() => _visibility = v ?? 'public'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _saving ? null : _pickImages,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text('post_add_images'.tr),
                  ),
                  const SizedBox(width: 12),
                  Text('${_picked.length}'),
                ],
              ),
              if (_picked.isNotEmpty) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _picked.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final img = _picked[i];
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.memory(
                              img.bytes,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: -8,
                            right: -8,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, size: 18),
                              onPressed: () =>
                                  setState(() => _picked.removeAt(i)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('submit'.tr),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PickedImage {
  const _PickedImage({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}
