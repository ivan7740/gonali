# Plan: W6 — 团队朋友圈 + 私聊 + 长轮询

## Summary
- 团队朋友圈（moments）：发布/增量拉取，仅团队成员可见
- 私聊：会话/消息/长轮询/撤回（2 分钟）
- W6 仅支持文本 + 图片消息（音视频留给 W6.1 媒体增强）

## Scope
- **Migration 0005**: moments, chat_conversations, chat_messages, chat_read_marks
- **Backend** 7+1 端点：
  - GET /teams/:id/moments?since= — 团队朋友圈增量（仅成员）
  - POST /teams/:id/moments — 发布（仅成员；可挂图片 media_ids）
  - GET /chats/conversations — 我的会话列表（含对方信息 + 最后一条消息）
  - POST /chats/:user_id/start — 创建/获取与某用户的会话
  - GET /chats/conversations/:id/messages?since=&wait=true — long-poll（最多 25s 等待新消息）
  - POST /chats/conversations/:id/messages — 发送（text/image）
  - POST /chats/messages/:id/recall — 撤回（120s 内 + sender 限定）
  - 心跳合并接口已在 W4，W6 把 `moment_unread` 算成真实数（自上次读 mark 以来未读）
- **Frontend**：
  - Chat tab 真实页：ChatListView（会话）→ ConversationView（消息流 + 长轮询 + 撤回）
  - Team detail 添加「团队朋友圈」入口 → MomentsView
  - 复用 W5 image_picker + MediaRepo

## NOT Building
- 音视频聊天（W6.1）
- 已读回执 UI（数据通已存）
- 撤回后的"已撤回"占位文本国际化变体（仅简单 placeholder）
- 推送（plan §3.3 是轮询架构）

## Files
- Backend: migrations/0005_moments_chat.sql, model/{moment,chat}.rs,
  dto/{moment,chat}.rs, service/{moment_repo,chat_repo}.rs,
  routes/{moments,chats}.rs, tests/{moments,chat}.rs
- Frontend: data/models/{moment,chat}.dart, data/repositories/{moment,chat}_repo.dart,
  modules/chat/* (controller + list + conversation views),
  modules/team/moments/moments_view.dart, 删 chat_placeholder.dart, i18n + 测试

## Acceptance Criteria
- [ ] 7 端点 + 集成测试覆盖（含撤回时间窗、非成员、long-poll 立即返回）
- [ ] Chat tab 真实页面，能与团队成员开启会话、发文本+图片消息、撤回
- [ ] Team detail 顶部新「团队朋友圈」入口
- [ ] cargo fmt/clippy/test --lib + flutter analyze/test 全绿
