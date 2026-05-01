# Plan: W2 — 用户/我的模块

## Summary
在 W1 鉴权脚手架之上落地「我的」模块完整闭环：个人资料（P-01）、主题（P-02）、语言（P-03）、地图设置入口（P-04，W4 实际生效）、隐私（P-07）、账号安全（P-08）、关于（P-09）。P-05/P-06 暂留占位（依赖 W3/W5/W6）。

## Scope
- **Backend**: 在 `unii-server/src/routes/users.rs` 扩展为 6 个端点
  - `GET /api/v1/users/me`（已有，扩展返回全部 profile 字段）
  - `PUT /api/v1/users/me` — 资料部分更新（username/nickname/email/city/occupation/gender/birthday）
  - `PUT /api/v1/users/me/settings` — theme/language/map_engine/location_share_enabled
  - `POST /api/v1/users/me/password` — old + new
  - `DELETE /api/v1/users/me` — 注销
  - `POST /api/v1/users/me/avatar` — multipart 上传
  - 静态：`GET /uploads/*` 服务上传文件（W2 暂用本地磁盘，W5 迁 S3/MinIO）

- **Frontend**: 替换 `profile_placeholder.dart`
  - ProfileMainView：9 个 ListTile（P-01..P-09）
  - 子页：ProfileEditView、PasswordChangeView、PrivacySettingsView、AboutView、MapSettingsView（占位）
  - 主题/语言切换全局响应（GetX rx + GetMaterialApp 重建）
  - 持久化：写后端 + 写本地 storage（启动时本地优先）

- **NOT Building**：S3/MinIO 实际存储、好友请求隐私（依赖好友表 W7）、地图引擎切换的实际生效（W4）、我的团队/我的发布（W3/W5/W6 占位）

## Patterns to Mirror
- W1 已有：AppError、ApiResp、tracing instrument、`sqlx::query_as::<_, UserRow>` 运行时查询、`#[sqlx::test(migrations=...)]` 集成测试、Bindings、Get.find
- 新增 multipart：用 `axum::extract::Multipart` + `tokio::fs`

## Files to Change

### Backend
| File | Action |
|---|---|
| `unii-server/Cargo.toml` | UPDATE — 加 `tower-http = { features = ["fs"] }` 已在；新增 `mime_guess`（如需） |
| `unii-server/src/dto/user.rs` | CREATE — UpdateProfileReq / UpdateSettingsReq / ChangePasswordReq DTO |
| `unii-server/src/dto/mod.rs` | UPDATE — 加 `pub mod user;` |
| `unii-server/src/service/user_repo.rs` | UPDATE — update_profile / update_settings / update_password / delete / update_avatar |
| `unii-server/src/routes/users.rs` | UPDATE — 5 个新路由 + multipart |
| `unii-server/src/lib.rs` | UPDATE — 静态文件 ServeDir 挂在 /uploads |
| `unii-server/tests/profile.rs` | CREATE — 集成测试 |

### Frontend
| File | Action |
|---|---|
| `unii-app/lib/data/models/user.dart` | CREATE — User 完整模型（含全部字段 + copyWith） |
| `unii-app/lib/data/repositories/user_repo.dart` | CREATE — getMe/updateProfile/updateSettings/changePassword/deleteAccount/uploadAvatar |
| `unii-app/lib/core/theme/theme_controller.dart` | CREATE — 全局主题 rx + 持久化 |
| `unii-app/lib/core/i18n/locale_controller.dart` | CREATE — 全局 locale rx + 持久化 |
| `unii-app/lib/core/i18n/translations.dart` | UPDATE — 加 W2 全部键 |
| `unii-app/lib/app/bindings/initial_binding.dart` | UPDATE — 注入 UserRepo / ThemeController / LocaleController |
| `unii-app/lib/main.dart` | UPDATE — themeMode/locale 绑定 controller |
| `unii-app/lib/modules/home/tabs/profile_placeholder.dart` | DELETE/REPLACE → `profile_view.dart` 真实页 |
| `unii-app/lib/modules/profile/profile_controller.dart` | CREATE |
| `unii-app/lib/modules/profile/profile_view.dart` | CREATE — 9 个 tile |
| `unii-app/lib/modules/profile/profile_binding.dart` | CREATE |
| `unii-app/lib/modules/profile/edit/profile_edit_view.dart` | CREATE |
| `unii-app/lib/modules/profile/edit/profile_edit_controller.dart` | CREATE |
| `unii-app/lib/modules/profile/security/password_change_view.dart` | CREATE |
| `unii-app/lib/modules/profile/security/account_security_view.dart` | CREATE |
| `unii-app/lib/modules/profile/privacy/privacy_settings_view.dart` | CREATE |
| `unii-app/lib/modules/profile/about/about_view.dart` | CREATE |
| `unii-app/lib/modules/profile/map/map_settings_view.dart` | CREATE — 占位 (W4) |
| `unii-app/lib/app/routes/app_routes.dart` | UPDATE — 加 7 条路由 |
| `unii-app/lib/app/routes/app_pages.dart` | UPDATE |
| `unii-app/test/profile_controller_test.dart` | CREATE |

## Acceptance Criteria
- [ ] 6 个后端端点 + 静态服务可用，集成测试覆盖资料/设置/密码/注销
- [ ] 「我的」页 9 个入口可点击，P-05/P-06 显示 placeholder
- [ ] 切主题立即重绘；切语言立即生效
- [ ] cargo fmt/clippy/test --lib 全绿；flutter analyze/test 全绿

## Risks
| Risk | Mitigation |
|---|---|
| Multipart 文件越界 | 限制 Content-Length（axum DefaultBodyLimit） |
| 密码改后旧 refresh token 仍有效 | 留 W7 黑名单做；W2 只校验 old password |
| 注销账户级联 | W2 仅删 users 行；W3+ 添加级联前在迁移里加 ON DELETE CASCADE |
| 头像本地磁盘易丢 | docker volume 挂 ./uploads；README 记录 |
