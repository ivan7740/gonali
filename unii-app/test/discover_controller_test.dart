import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:mocktail/mocktail.dart';

import 'package:unii_app/data/models/post.dart';
import 'package:unii_app/data/repositories/post_repo.dart';
import 'package:unii_app/modules/discover/discover_controller.dart';

class _MockPostRepo extends Mock implements PostRepo {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockPostRepo repo;

  Post mkPost({required int id, bool liked = false, int likes = 0}) => Post(
    id: id,
    authorId: 1,
    authorUsername: 'alice',
    visibility: 'public',
    likeCount: likes,
    commentCount: 0,
    likedByMe: liked,
    media: const [],
    content: 'p$id',
  );

  setUp(() {
    Get.reset();
    Get.testMode = true;
    repo = _MockPostRepo();
  });

  test('reload loads posts from repo', () async {
    when(
      () => repo.feed(
        beforeId: any(named: 'beforeId'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => [mkPost(id: 1), mkPost(id: 2)]);
    final c = Get.put(DiscoverController(repo: repo));
    await Future<void>.delayed(Duration.zero);
    expect(c.posts.length, 2);
    expect(c.error.value, isNull);
  });

  test('toggleLike updates the matching post in place', () async {
    when(
      () => repo.feed(
        beforeId: any(named: 'beforeId'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async => [mkPost(id: 1)]);
    when(() => repo.toggleLike(1)).thenAnswer(
      (_) async => const LikeToggleResult(liked: true, likeCount: 1),
    );

    final c = Get.put(DiscoverController(repo: repo));
    await Future<void>.delayed(Duration.zero);
    await c.toggleLike(1);

    expect(c.posts.first.likedByMe, true);
    expect(c.posts.first.likeCount, 1);
  });

  test('reload records error on repo failure', () async {
    when(
      () => repo.feed(
        beforeId: any(named: 'beforeId'),
        limit: any(named: 'limit'),
      ),
    ).thenThrow(Exception('boom'));
    final c = Get.put(DiscoverController(repo: repo));
    await Future<void>.delayed(Duration.zero);
    expect(c.posts, isEmpty);
    expect(c.error.value, contains('boom'));
  });
}
