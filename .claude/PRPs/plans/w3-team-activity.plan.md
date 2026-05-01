# Plan: W3 — 团队 + 活动 CRUD

## Summary
落地 plan §2.2 团队模块 + §6.2 活动 CRUD：建表、邀请码加入、成员管理、转让、活动 CRUD。心跳/定位（T-05/T-06）依赖 W4 定位上报，本期不做。团队朋友圈（T-07）由 W6。

## Scope
- **Migration 0002**: `teams` + `team_members` + `activities`（PostGIS GEOGRAPHY）
- **Backend** 11 个端点：
  - 团队：POST /teams、GET /teams/mine、GET /teams/{id}、POST /teams/join、GET /teams/{id}/members、DELETE /teams/{id}/members/me、DELETE /teams/{id}/members/{uid}（队长踢人）、POST /teams/{id}/transfer（转让队长）、DELETE /teams/{id}（解散）
  - 活动：POST /teams/{id}/activities、GET /teams/{id}/activities、GET /activities/{id}、PUT /activities/{id}、DELETE /activities/{id}
- **Frontend**：把 Team tab 占位换成完整页（团队列表 + 创建 + 加入）；团队详情（信息 + 成员 + 活动）；活动 CRUD 表单（W3 用经纬度输入框，W4 加地图选点）

## NOT Building
- 心跳合并接口 GET /teams/{id}/heartbeat — 依赖 W4 location 表
- 团队/活动头像上传 — 复用 W2 /uploads，但 W3 表单不暴露上传 UI（plan §10 说明 W5 媒体上传统一处理）
- 朋友圈 moments — W6
- 距离计算 T-06 — 依赖 W4 定位

## Authorization Rules
| 端点 | 要求 |
|---|---|
| GET /teams/{id} & members & activities list | 必须是成员 |
| POST /teams/{id}/activities | 必须是成员 |
| PUT/DELETE /activities/{id} | creator 或 owner |
| DELETE /teams/{id}/members/{uid} | owner 且 uid != owner |
| POST /teams/{id}/transfer | owner，目标必须是成员 |
| DELETE /teams/{id} | owner |

## Files

### Backend
| File | Action |
|---|---|
| `migrations/0002_teams_activities.sql` | CREATE |
| `src/model/team.rs` | CREATE — TeamRow, TeamMemberRow |
| `src/model/activity.rs` | CREATE — ActivityRow + Point |
| `src/dto/team.rs` | CREATE |
| `src/dto/activity.rs` | CREATE |
| `src/dto/mod.rs` | UPDATE |
| `src/service/team_repo.rs` | CREATE |
| `src/service/activity_repo.rs` | CREATE |
| `src/service/mod.rs` | UPDATE |
| `src/routes/teams.rs` | CREATE |
| `src/routes/activities.rs` | CREATE |
| `src/routes/mod.rs` | UPDATE |
| `src/lib.rs` | UPDATE — nest 新路由 |
| `src/util/invite_code.rs` | CREATE — 6 字符随机（去除 0/O/I/1） |
| `src/util/mod.rs` | UPDATE |
| `tests/teams.rs` | CREATE |
| `tests/activities.rs` | CREATE |

### Frontend
| File | Action |
|---|---|
| `lib/data/models/team.dart` | CREATE |
| `lib/data/models/activity.dart` | CREATE |
| `lib/data/repositories/team_repo.dart` | CREATE |
| `lib/data/repositories/activity_repo.dart` | CREATE |
| `lib/app/bindings/initial_binding.dart` | UPDATE — 注入 TeamRepo/ActivityRepo |
| `lib/modules/team/team_controller.dart` | CREATE |
| `lib/modules/team/team_view.dart` | CREATE |
| `lib/modules/team/team_binding.dart` | CREATE |
| `lib/modules/team/create/team_create_view.dart` | CREATE |
| `lib/modules/team/join/team_join_view.dart` | CREATE |
| `lib/modules/team/detail/team_detail_controller.dart` | CREATE |
| `lib/modules/team/detail/team_detail_view.dart` | CREATE |
| `lib/modules/team/members/team_members_view.dart` | CREATE |
| `lib/modules/activity/activity_form_view.dart` | CREATE — create + edit 复用 |
| `lib/modules/activity/activity_detail_view.dart` | CREATE |
| `lib/modules/home/home_view.dart` | UPDATE — TeamPlaceholder → TeamView |
| `lib/modules/home/home_binding.dart` | UPDATE — 注入 TeamController |
| `lib/modules/home/tabs/team_placeholder.dart` | DELETE |
| `lib/app/routes/app_routes.dart` | UPDATE |
| `lib/app/routes/app_pages.dart` | UPDATE |
| `lib/core/i18n/translations.dart` | UPDATE — 加 W3 键 |
| `test/team_controller_test.dart` | CREATE |

## Acceptance Criteria
- [ ] 0002 迁移执行成功，三表创建并索引
- [ ] 11 个后端端点 + 集成测试覆盖
- [ ] Team tab 真实页可创建/加入/查看团队、查看成员、创建活动
- [ ] 权限规则集成测试明确：非成员访问 detail 返回 403/404，非 owner 解散返回 403
- [ ] cargo fmt/clippy/test --lib 全绿；flutter analyze/test 全绿
