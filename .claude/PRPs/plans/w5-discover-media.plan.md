# Plan: W5 — 推荐模块 + 媒体上传

## Summary
落地 plan §2.1 推荐模块（D-01..D-07，简化版）+ §6.2 推荐 endpoints + 媒体上传。
- 内容支持：文字 + 图片（W5）；音频/视频留给 W6（图标占位）
- 公开活动同步（D-05）：feed 联合查询 posts.visibility=public 和 activities.visibility=public
- 举报/筛选（D-06/D-07）：占位（W7+）

## Scope
- **Migration 0004**: posts + post_likes + post_comments + media_files
- **Backend** 8 端点：
  - POST/GET /posts、GET /posts/:id、POST /posts/:id/like（toggle）、POST/GET /posts/:id/comments
  - POST /media/upload（multipart，存 ./uploads，复用 W2 ServeDir）
- **Frontend**：
  - DiscoverView 替换 placeholder（feed + 发布 FAB）
  - PostCreateView：文字 + 多图（image_picker）
  - PostDetailView：内容 + 评论 + 点赞按钮
  - PostRepo / MediaRepo

## NOT Building
- 音视频上传/播放（W6 媒体）
- 举报、按位置/时间筛选（W7+）
- 推荐排序的"热度"算法（仅时间倒序）
- 嵌套评论 UI（数据支持，UI 平铺）

## Files
- Backend: migrations/0004_posts_media.sql, model/{post,post_comment,media}.rs,
  dto/{post,media}.rs, service/{post_repo,media_repo}.rs, routes/{posts,media}.rs,
  tests/{posts,media}.rs
- Frontend: data/models/{post,post_comment,media}.dart, data/repositories/{post,media}_repo.dart,
  modules/discover/* (controller + view + create + detail), 
  modules/home/tabs/discover_placeholder.dart 删除
- pubspec: 加 `image_picker: ^1.1.2`
- i18n: W5 keys
- 测试: post_controller_test

## Acceptance Criteria
- [ ] 8 端点 + 集成测试覆盖（feed/like 切换/评论/上传）
- [ ] Discover tab 真实页面，可发布带图 post，看到自己和他人的 public 内容
- [ ] cargo fmt/clippy/test --lib + flutter analyze/test 全绿
