import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:mocktail/mocktail.dart';

import 'package:unii_app/data/models/chat.dart';
import 'package:unii_app/data/repositories/chat_repo.dart';
import 'package:unii_app/modules/chat/chat_list_controller.dart';

class _MockChatRepo extends Mock implements ChatRepo {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockChatRepo repo;

  Conversation conv({int id = 1, int unread = 0, String? preview}) =>
      Conversation(
        id: id,
        otherUserId: 2,
        otherUsername: 'bob',
        unreadCount: unread,
        lastMessagePreview: preview,
      );

  setUp(() {
    Get.reset();
    Get.testMode = true;
    repo = _MockChatRepo();
  });

  test('reload populates conversations', () async {
    when(() => repo.listConversations()).thenAnswer(
      (_) async => [conv(id: 1, preview: 'hi'), conv(id: 2, unread: 3)],
    );
    final c = Get.put(ChatListController(repo: repo));
    await Future<void>.delayed(Duration.zero);
    expect(c.conversations.length, 2);
    expect(c.conversations.first.lastMessagePreview, 'hi');
    expect(c.conversations[1].unreadCount, 3);
    expect(c.error.value, isNull);
  });

  test('reload records error', () async {
    when(() => repo.listConversations()).thenThrow(Exception('boom'));
    final c = Get.put(ChatListController(repo: repo));
    await Future<void>.delayed(Duration.zero);
    expect(c.conversations, isEmpty);
    expect(c.error.value, contains('boom'));
  });
}
