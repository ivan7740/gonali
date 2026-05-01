# Plan: W4 — 地图双引擎 + 定位上报 + 心跳合并

## Summary
落地 plan §4 地图方案与 §6.2 定位/地图接口：
1. 后端：`user_locations` 表 + 上报/距离/心跳/路径四个端点 + GCJ-02 ↔ WGS84 转换
2. 前端：`MapAdapter` 抽象 + 双引擎工厂 + 首登地图选择弹窗 + 团队详情页地图视图 + 周期定位上报

## Pragmatic Compromises
- **AMap SDK 接入**：`amap_flutter_map`/`amap_flutter_location` 需要 Android `AndroidManifest.xml` + iOS `Info.plist` 注入 AMap Key（且需要单独的 SDK Key，与 Web Key 不同）。W4 完成完整抽象 + OSM 真实地图 + AMap **占位 widget**（白底 + "配置 AMap Key 后启用"）；用户选择 AMap 引擎时仍工作（坐标系、上报等都正确），只是 widget 渲染降级。W4.1 单独把 native 配置补全。
- **/route 端点**：在 `AMAP_WEB_KEY` 缺失时返回降级直线路径（首末点 + 距离），确保接口契约稳定。
- **离线瓦片下载**：plan §4.6 列入 W7（推迟）。

## Files

### Backend
| File | Action |
|---|---|
| `migrations/0003_user_locations.sql` | CREATE — user_locations 表 + GIST 索引 |
| `src/util/coord.rs` | CREATE — gcj02_to_wgs84 / wgs84_to_gcj02 + 单元测试 |
| `src/util/mod.rs` | UPDATE |
| `src/dto/location.rs` | CREATE — ReportLocationReq / RouteResp / HeartbeatResp |
| `src/dto/mod.rs` | UPDATE |
| `src/service/location_repo.rs` | CREATE — upsert_location / get_team_members_locations |
| `src/service/mod.rs` | UPDATE |
| `src/routes/locations.rs` | CREATE — POST /report, GET /distance, GET /route |
| `src/routes/teams.rs` | UPDATE — 加 GET /:id/heartbeat |
| `src/routes/mod.rs` | UPDATE |
| `src/lib.rs` | UPDATE — 挂 /locations |
| `tests/locations.rs` | CREATE |
| `tests/heartbeat.rs` | CREATE |
| `Cargo.toml` | 已有 reqwest 备用；W4 不引入新 crate（route 用 reqwest 代理） |

### Frontend
| File | Action |
|---|---|
| `pubspec.yaml` | UPDATE — 加 `flutter_map: ^7.0.2`, `latlong2: ^0.9.1`（OSM）|
| `lib/data/models/location.dart` | CREATE — Location, MemberLocation, RouteResult |
| `lib/data/repositories/location_repo.dart` | CREATE — report/distance/route/heartbeat |
| `lib/core/map/map_engine.dart` | CREATE — enum |
| `lib/core/map/map_adapter.dart` | CREATE — abstract MapAdapter + types |
| `lib/core/map/map_factory.dart` | CREATE |
| `lib/core/map/osm_adapter.dart` | CREATE — flutter_map 实现 |
| `lib/core/map/amap_adapter.dart` | CREATE — 占位 widget + 提示 |
| `lib/core/location/location_service.dart` | CREATE — 周期上报 (geolocator) |
| `lib/modules/auth/auth_controller.dart` | UPDATE — 登录后检查 needs_map_setup → push 弹窗 |
| `lib/modules/onboarding/map_picker_view.dart` | CREATE — 首登必选弹窗 |
| `lib/modules/profile/map/map_settings_view.dart` | UPDATE — 实际切换 MapAdapter |
| `lib/modules/team/detail/team_detail_view.dart` | UPDATE — 顶部嵌入团队地图 |
| `lib/modules/team/detail/team_map_widget.dart` | CREATE — 调用 MapAdapter.buildMap |
| `lib/app/bindings/initial_binding.dart` | UPDATE — 注入 MapAdapter / LocationService / LocationRepo |
| `lib/app/routes/app_routes.dart` + `app_pages.dart` | UPDATE — 加 mapPicker 路由 |
| `lib/core/i18n/translations.dart` | UPDATE — W4 键 |
| `test/coord_conversion_test.dart` (Rust 端已覆盖；前端不复测) |  |
| `test/location_service_test.dart` | CREATE — 上报间隔 + 隐私开关 |
| `android/app/src/main/AndroidManifest.xml` | UPDATE — `INTERNET`+`ACCESS_FINE_LOCATION`+`ACCESS_COARSE_LOCATION` 权限 |
| `ios/Runner/Info.plist` | UPDATE — `NSLocationWhenInUseUsageDescription` |

## Authorization & Privacy Rules
- 心跳接口仅返回团队成员中 `location_share_enabled=true` 的位置。
- 用户在「我的→隐私设置」关闭定位上报后，前端 `LocationService` 立即停止采集。
- W4 不做历史轨迹（plan §9：不存）。`user_locations` 用 PRIMARY KEY user_id 做 upsert，永远只有最新一条。

## Acceptance Criteria
- [ ] 后端 4 端点 + heartbeat 集成测试覆盖
- [ ] 首登必选地图引擎，跳过/取消不可（dialog `barrierDismissible: false`）
- [ ] 切换地图设置立即生效（`Get.replace<MapAdapter>(...)`）
- [ ] 团队详情页顶部嵌入地图，渲染当前团队成员位置点
- [ ] 隐私开关关闭后停止上报
- [ ] cargo fmt/clippy/test --lib 全绿；flutter analyze/test 全绿

## Risks
| Risk | Mitigation |
|---|---|
| flutter_map 7.x API 变化 | 实施时用 context7 拉最新文档校验 |
| iOS 模拟器拿不到真位置 | LocationService 检测 `Geolocator.checkPermission`，失败时使用 last_known 或 0,0 占位 |
| AMap key 缺失 | 占位 widget；plan 中明确 W4.1 补全 |
| 高频上报耗电 | 默认 30s 间隔，活跃团队页放 10s（plan §3.3）；后台暂停 |
