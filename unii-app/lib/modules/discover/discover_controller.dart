import 'package:get/get.dart' hide Response;

import 'package:unii_app/data/models/post.dart';
import 'package:unii_app/data/repositories/post_repo.dart';

class DiscoverController extends GetxController {
  DiscoverController({required this.repo});

  final PostRepo repo;

  final posts = <Post>[].obs;
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
      posts.value = await repo.feed();
    } on Object catch (e) {
      error.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleLike(int postId) async {
    final idx = posts.indexWhere((p) => p.id == postId);
    if (idx < 0) return;
    try {
      final r = await repo.toggleLike(postId);
      posts[idx] = posts[idx].copyWith(
        likedByMe: r.liked,
        likeCount: r.likeCount,
      );
    } on Object catch (e) {
      error.value = e.toString();
    }
  }
}
