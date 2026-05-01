import 'package:get/get.dart' hide Response;

import 'package:unii_app/data/models/chat.dart';
import 'package:unii_app/data/repositories/chat_repo.dart';

class ChatListController extends GetxController {
  ChatListController({required this.repo});

  final ChatRepo repo;

  final conversations = <Conversation>[].obs;
  final isLoading = false.obs;
  final error = RxnString();

  @override
  void onInit() {
    super.onInit();
    reload();
  }

  Future<void> reload() async {
    isLoading.value = true;
    error.value = null;
    try {
      conversations.value = await repo.listConversations();
    } on Object catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }
}
