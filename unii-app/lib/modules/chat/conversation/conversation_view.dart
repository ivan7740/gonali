import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Response;
import 'package:image_picker/image_picker.dart';

import 'package:unii_app/core/storage/token_storage.dart';
import 'package:unii_app/data/models/chat.dart';
import 'package:unii_app/data/repositories/chat_repo.dart';
import 'package:unii_app/data/repositories/media_repo.dart';

class ConversationView extends StatefulWidget {
  const ConversationView({super.key});

  @override
  State<ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<ConversationView> {
  late final int _conversationId;
  late final String _displayName;

  final _messages = <ChatMessage>[];
  int? _lastSeenId;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  bool _polling = false;
  bool _sending = false;
  late final int? _myUserId;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>;
    _conversationId = args['conversationId'] as int;
    _displayName = args['displayName'] as String? ?? 'chat_title'.tr;
    _myUserId = Get.find<TokenStorage>().userId();
    _bootstrap();
  }

  @override
  void dispose() {
    _polling = false;
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final repo = Get.find<ChatRepo>();
    final initial = await repo.messages(conversationId: _conversationId);
    if (!mounted) return;
    setState(() {
      _messages
        ..clear()
        ..addAll(initial);
      if (_messages.isNotEmpty) _lastSeenId = _messages.last.id;
    });
    unawaited(repo.markRead(_conversationId));
    _polling = true;
    unawaited(_pollLoop());
    _scrollToBottom();
  }

  Future<void> _pollLoop() async {
    final repo = Get.find<ChatRepo>();
    while (_polling && mounted) {
      try {
        final next = await repo.messages(
          conversationId: _conversationId,
          sinceId: _lastSeenId,
          wait: true,
        );
        if (!mounted) return;
        if (next.isNotEmpty) {
          setState(() {
            _messages.addAll(next);
            _lastSeenId = next.last.id;
          });
          unawaited(repo.markRead(_conversationId));
          _scrollToBottom();
        }
      } on DioException {
        await Future<void>.delayed(const Duration(seconds: 2));
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText() async {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    try {
      final msg = await Get.find<ChatRepo>().send(
        conversationId: _conversationId,
        msgType: 'text',
        content: text,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
        _lastSeenId = msg.id;
        _input.clear();
      });
      _scrollToBottom();
    } on DioException catch (e) {
      _toastError(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final pick = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pick == null) return;
    setState(() => _sending = true);
    try {
      final bytes = await pick.readAsBytes();
      final uploaded = await Get.find<MediaRepo>().uploadBytes(
        bytes: bytes,
        filename: pick.name,
      );
      final msg = await Get.find<ChatRepo>().send(
        conversationId: _conversationId,
        msgType: 'image',
        mediaUrl: uploaded.url,
      );
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
        _lastSeenId = msg.id;
      });
      _scrollToBottom();
    } on DioException catch (e) {
      _toastError(e);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _recall(ChatMessage m) async {
    try {
      final updated = await Get.find<ChatRepo>().recall(m.id);
      if (!mounted) return;
      setState(() {
        final idx = _messages.indexWhere((x) => x.id == m.id);
        if (idx >= 0) _messages[idx] = updated;
      });
    } on DioException catch (e) {
      _toastError(e);
    }
  }

  void _toastError(DioException e) {
    final raw = e.response?.data;
    final msg = raw is Map<String, dynamic>
        ? (raw['msg']?.toString() ?? 'network_error'.tr)
        : 'network_error'.tr;
    Get.snackbar(
      'tab_chat'.tr,
      msg,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_displayName)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final mine = m.senderId == _myUserId;
                return _Bubble(
                  message: m,
                  mine: mine,
                  onLongPress: mine && !m.isRecalled ? () => _recall(m) : null,
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image_outlined),
                    onPressed: _sending ? null : _sendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _input,
                      decoration: InputDecoration(
                        hintText: 'chat_compose_hint'.tr,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _sendText(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _sending ? null : _sendText,
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

class _Bubble extends StatelessWidget {
  const _Bubble({
    required this.message,
    required this.mine,
    required this.onLongPress,
  });

  final ChatMessage message;
  final bool mine;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = mine ? scheme.primaryContainer : scheme.surfaceContainerHighest;
    final fg = mine ? scheme.onPrimaryContainer : scheme.onSurface;
    final align = mine ? Alignment.centerRight : Alignment.centerLeft;

    Widget child;
    if (message.isRecalled) {
      child = Text(
        'chat_recalled'.tr,
        style: TextStyle(color: fg.withAlpha(160), fontStyle: FontStyle.italic),
      );
    } else if (message.isImage && message.mediaUrl != null) {
      child = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          message.mediaUrl!,
          width: 200,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 200,
            height: 120,
            color: scheme.surfaceContainerLowest,
            child: const Icon(Icons.broken_image),
          ),
        ),
      );
    } else if (message.isText) {
      child = Text(message.content ?? '', style: TextStyle(color: fg));
    } else {
      child = Text(
        '[${message.msgType}]',
        style: TextStyle(color: fg.withAlpha(160)),
      );
    }

    return Align(
      alignment: align,
      child: GestureDetector(
        onLongPress: onLongPress,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(12),
          ),
          constraints: const BoxConstraints(maxWidth: 280),
          child: child,
        ),
      ),
    );
  }
}
