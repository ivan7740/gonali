# UNII - 小型团队户外实时定位共享 APP 项目方案

## 一、项目概述

### 1.1 项目名称
**UNII** —— 小型团队户外实时定位共享移动应用

### 1.2 项目目标
为户外活动小型团队（骑行、登山、徒步、自驾、景区游览等）提供一款集**实时定位共享**、**团队管理**、**社交互动**、**内容分享**于一体的轻量级移动应用，解决团队户外活动中"看不见队友、走散难找、沟通不便、回忆难存"的痛点。

### 1.3 核心特色
- **轻量级实时定位**：基于 HTTP 轮询的低成本定位共享方案
- **团队为中心**：所有功能围绕"团队"组织
- **公私分离**：内容/活动支持 public（推荐流可见）与 private（仅团队内可见）
- **多媒体内容**：支持文字、图片、音频、视频
- **双地图引擎**：高德（国内）+ OpenStreetMap（海外/离线），**用户手动切换**

### 1.4 目标用户
- 户外骑行 / 徒步 / 登山团体（5–30 人规模）
- 景区跟团出游小团队
- 公司团建、亲友自驾游团队
- 学校社团户外活动小组

---

## 二、功能需求

### 2.1 推荐模块（Discover）

| ID | 功能 | 说明 |
|----|------|------|
| D-01 | 推荐内容流 | 时间倒序展示所有 public 内容（团队成员发布的人/事/风景） |
| D-02 | 内容详情 | 标题、正文、图片轮播、视频、音频 |
| D-03 | 互动入口 | 详情页底部：私聊作者、点赞、留言三按钮 |
| D-04 | 留言区 | 二级评论，支持 @ 团队成员 |
| D-05 | 公开活动同步 | 团队 public 活动公告自动入推荐流，类型标记为"活动" |
| D-06 | 内容筛选 | 按类型（动态/活动）、按位置、按时间筛选 |
| D-07 | 内容举报 | 不良内容举报入口 |

### 2.2 团队模块（Team）

| ID | 功能 | 说明 |
|----|------|------|
| T-01 | 创建团队 | 名称、头像、简介、人数上限（默认 30） |
| T-02 | 加入团队 | 通过 6 位邀请码加入 |
| T-03 | 退出 / 解散团队 | 普通成员可退出，队长可解散 |
| T-04 | 团队活动公告 | 名称、地点（地图选点）、时间、内容、注意事项、public/private |
| T-05 | 实时定位 | 团队成员在地图上以小图标实时呈现（10–30s 轮询） |
| T-06 | 距离计算 | 任意成员到固定点（活动起/终点）或到当前用户的直线距离 + 路径距离 |
| T-07 | 团队朋友圈 | 团队内文字、语音、视频动态（仅团队成员可见） |
| T-08 | 成员管理 | 队长可移除成员、转让队长 |
| T-09 | 定位开关 | 用户可临时关闭定位上报（隐私保护） |

### 2.3 私聊模块（Chat）

| ID | 功能 | 说明 |
|----|------|------|
| C-01 | 发起私聊 | 通过 @ 团队成员或搜索昵称发起 |
| C-02 | 消息类型 | 文字、音频、视频、图片 |
| C-03 | 历史会话列表 | 时间倒序，未读消息红点 |
| C-04 | 加好友 | 私聊后可发起加好友请求 |
| C-05 | 好友列表 | 独立好友分组管理 |
| C-06 | 消息撤回 | 2 分钟内可撤回 |

### 2.4 我的模块（Profile）

| ID | 功能 | 说明 |
|----|------|------|
| P-01 | 个人资料 | 用户名、头像、昵称、手机号、所在城市、邮箱、职业、性别、生日 |
| P-02 | 主题切换 | 暗黑 / 浅色 / 跟随系统 |
| P-03 | 语言切换 | 中文 / 英文 |
| P-04 | **地图设置** | **手动切换：高德地图 / OpenStreetMap，立即生效；含离线地图下载（OSM）** |
| P-05 | 我的团队 | 已加入的团队列表 |
| P-06 | 我的发布 | 推荐 + 团队朋友圈历史发布 |
| P-07 | 隐私设置 | 定位上报开关、谁可加我好友 |
| P-08 | 账号安全 | 密码修改、注销账号 |
| P-09 | 关于与帮助 | 版本、用户协议、隐私政策、意见反馈 |

---

## 三、技术架构

### 3.1 整体架构图

```
┌──────────────────────────────────────────────────┐
│           Flutter 移动端 (iOS / Android)          │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐ │
│  │ 推荐 Page  │  │ 团队 Page  │  │ 私聊 Page  │ │
│  └────────────┘  └────────────┘  └────────────┘ │
│  ┌────────────────────────────────────────────┐ │
│  │     GetX (路由 / 状态 / 依赖注入)           │ │
│  └────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────┐ │
│  │  MapAdapter (统一接口) ← 用户手动切换       │ │
│  │   ├── AmapAdapter   (高德 amap_flutter_map) │ │
│  │   └── OsmAdapter    (flutter_map + OSM)     │ │
│  └────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────┐ │
│  │     Dio (HTTP) + Polling Timer Manager      │ │
│  └────────────────────────────────────────────┘ │
└────────────────────┬─────────────────────────────┘
                     │ HTTPS (JSON / multipart)
                     │ Bearer Token (JWT)
┌────────────────────▼─────────────────────────────┐
│         Axum 后端服务 (Rust + Tokio)              │
│  ┌────────────────────────────────────────────┐ │
│  │  Router: /api/v1/{auth,team,location,...}   │ │
│  ├────────────────────────────────────────────┤ │
│  │  Middleware: JWT / CORS / 日志 / 限流        │ │
│  ├──────────────┬─────────────────────────────┤ │
│  │ Handler 层   │  Service / Domain 层         │ │
│  ├──────────────┴─────────────────────────────┤ │
│  │  GeoService:                                │ │
│  │   ├── 坐标转换 (WGS84 ↔ GCJ-02)             │ │
│  │   └── 路径距离 (高德 Web API + OSRM)         │ │
│  ├────────────────────────────────────────────┤ │
│  │       sqlx (PostgreSQL 异步驱动)            │ │
│  └────────────────────────────────────────────┘ │
└────┬──────────────────────────┬──────────────────┘
     │                          │
┌────▼──────────┐      ┌────────▼─────────────────┐
│ PostgreSQL 16 │      │  对象存储 (MinIO / S3)    │
│ + PostGIS     │      │  存储图片/音频/视频        │
└───────────────┘      └──────────────────────────┘
```

### 3.2 技术栈

| 层 | 技术 | 版本 | 用途 |
|----|------|------|------|
| 移动端框架 | Flutter | 3.24+ | 跨平台 UI |
| 状态/路由 | GetX | 4.6+ | 状态、路由、DI、国际化 |
| HTTP | Dio | 5.x | 请求 + 拦截器 |
| **地图 - 国内** | **amap_flutter_map + amap_flutter_location** | – | 高德地图、定位、POI |
| **地图 - 海外/离线** | **flutter_map + flutter_map_tile_caching** | 7.x | OSM 瓦片渲染 + 离线 |
| 设备定位 | geolocator | 12.x | 跨平台 GPS（OSM 模式） |
| 路径规划 | 高德 Web API / OSRM | – | 后端代理调用 |
| 本地存储 | get_storage / hive | – | Token、配置、瓦片缓存 |
| 后端框架 | Axum | 0.7+ | Web 框架 |
| 异步运行时 | Tokio | 1.x | 异步 |
| ORM/SQL | sqlx | 0.8+ | 编译期校验 SQL |
| 鉴权 | jsonwebtoken | – | JWT |
| 数据库 | PostgreSQL | 16+ | 主存储 |
| 地理扩展 | PostGIS | 3.x | 地理查询 |
| 对象存储 | MinIO / 阿里云 OSS | – | 媒体文件 |
| 部署 | Docker + Docker Compose | – | 容器化 |
| 反向代理 | Nginx / Caddy | – | TLS、限流 |

### 3.3 通信方式：HTTP 轮询策略

| 业务 | 轮询间隔 | 触发条件 |
|------|---------|---------|
| 团队成员实时定位 | 10s | 团队详情页可见时 |
| 私聊新消息 | 5s | 聊天页可见时 |
| 私聊会话列表未读数 | 30s | 应用前台 |
| 推荐流刷新 | 手动下拉 | 用户操作 |
| 团队朋友圈 | 60s | 朋友圈页可见时 |
| 团队公告 | 120s | 团队首页 |

**优化策略**：
- **长轮询兜底**：消息类接口请求带 `since` 时间戳，服务端最多挂起 25s
- **指数退避**：连续空响应时，间隔 5s → 30s
- **App 进入后台**：暂停所有轮询
- **批量接口**：定位 + 公告 + 朋友圈未读数合并为 `/api/v1/team/{id}/heartbeat`

---

## 四、地图与定位方案（双引擎，用户手动切换）

### 4.1 双地图对比

| 引擎 | 适用场景 | 坐标系 | 优势 | 劣势 |
|------|---------|--------|------|------|
| **高德 Amap** | 国内用户、需要 POI/路径规划/逆地理编码 | GCJ-02 | 国内精度高、POI 全、配额免费够用 | 海外覆盖差、需注册 Key |
| **OpenStreetMap** | 海外、离线、隐私敏感 | WGS84 | 完全免费开源、可离线缓存 | 国内无偏移纠正、POI 弱、瓦片在国外较慢 |

### 4.2 切换策略：完全由用户手动决定
> 不做基于地理位置的自动判定。

#### 4.2.1 登录后首次提示（一次性）
- 用户**首次登录成功**进入主界面前，弹出**全屏选择对话框**：
  ```
  ┌─────────────────────────────────────┐
  │       请选择地图引擎                  │
  │                                     │
  │   ┌─────────────────────────────┐   │
  │   │ 🇨🇳 高德地图                 │   │
  │   │ 推荐：国内活动、POI 搜索精准  │   │
  │   └─────────────────────────────┘   │
  │   ┌─────────────────────────────┐   │
  │   │ 🌍 OpenStreetMap            │   │
  │   │ 推荐：海外活动、离线使用      │   │
  │   └─────────────────────────────┘   │
  │                                     │
  │   可在「我的 → 地图设置」随时更改     │
  └─────────────────────────────────────┘
  ```
- 选择后：本地 `get_storage` 持久化 + 调用 `PUT /users/me/settings` 同步到后端
- **判定首次的依据**：用户记录中 `map_engine IS NULL`；后端在 `/users/me` 中返回 `needs_map_setup: true` 字段。设置成功后该字段变 false，不再弹出。
- 跨设备登录：若服务端已设置则直接采用；该设备本地无配置时静默使用服务端值，不重复弹窗。

#### 4.2.2 「我的 → 地图设置」入口（随时切换）
- Radio 单选：`高德地图` / `OpenStreetMap`
- 切换后立即生效（`Get.replace<MapAdapter>(...)`），并同步到后端
- OSM 选项下方提供「下载离线地图」入口（按团队活动区域缓存瓦片）

#### 4.2.3 兜底降级
- 若所选引擎初始化失败（如高德 SDK 加载异常、无网络且 OSM 无离线缓存），弹窗提示：
  > "当前地图引擎不可用，是否临时切换到另一引擎？"
- 用户确认后临时切换，**不**改写持久化偏好。

### 4.3 前端统一抽象层
```dart
abstract class MapAdapter {
  MapEngine get engine;             // amap | osm

  Widget buildMap({
    required LatLng center,
    required double zoom,
    required List<MemberMarker> markers,
    PolyLine? route,
    void Function(LatLng)? onTap,
  });

  Future<LatLng> getCurrentLocation();
  Future<List<PoiResult>> searchPoi(String keyword, LatLng around);
  Future<RouteResult> planRoute(LatLng from, LatLng to, RouteMode mode);

  CoordSystem get coordSystem;
}

class AmapAdapter implements MapAdapter { ... }
class OsmAdapter  implements MapAdapter { ... }
```

注入与切换（GetX）：
```dart
// 启动时根据持久化值创建
Get.put<MapAdapter>(MapFactory.create(engine: savedEngine), permanent: true);

// 用户在「地图设置」切换
void switchEngine(MapEngine e) {
  Get.replace<MapAdapter>(MapFactory.create(engine: e));
  storage.write('map_engine', e.name);
  api.updateSettings({'map_engine': e.name});
}
```

### 4.4 坐标系统一约定
> **所有跨端 / 入库的经纬度统一 WGS84**。仅在渲染到高德地图时由 `AmapAdapter` 内部 WGS84 → GCJ-02。

- 客户端：geolocator 直接拿 WGS84，原样上报；高德 SDK 内部拿到 GCJ-02 时在 Adapter 中转回 WGS84 再上报
- 后端：`user_locations.location` 始终存 WGS84（PostGIS `GEOGRAPHY(Point, 4326)`）
- 后端调用高德 Web API 路径规划：WGS84 → GCJ-02 入参，结果再 GCJ-02 → WGS84 返回前端
- Rust 端实现 `gcj02 ↔ wgs84` 函数（公开算法），并配单元测试

### 4.5 路径规划与距离
| 引擎 | 来源 |
|------|------|
| Amap | 高德 Web API `/v3/direction/driving|walking|bicycling`（后端代理） |
| OSM  | 公共 OSRM (router.project-osrm.org) 或自建 OSRM 实例 |

后端统一接口：`GET /locations/route?from=&to=&mode=&engine=`，返回距离、时长、polyline（WGS84）。

### 4.6 离线支持（OSM 独占）
- `flutter_map_tile_caching` 在出发前下载活动区域瓦片
- 团队活动详情页提供「下载离线地图」按钮（仅当用户当前为 OSM 引擎时显示），按活动地点周边 10km、zoom 10–16 缓存

---

## 五、数据库设计（PostgreSQL + PostGIS）

### 5.1 ER

```
users ──< team_members >── teams ──< activities
  │                          │
  │                          ├──< posts (动态/活动)
  │                          └──< moments (团队朋友圈)
  │
  ├──< user_locations  (定位时序)
  ├──< friendships     (好友关系)
  ├──< chat_messages   (私聊)
  ├──< post_likes / post_comments
  └──< media_files     (统一媒体表)
```

### 5.2 核心表结构

```sql
CREATE EXTENSION IF NOT EXISTS postgis;

-- 用户表
CREATE TABLE users (
    id            BIGSERIAL PRIMARY KEY,
    phone         VARCHAR(20) UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    username      VARCHAR(50) UNIQUE NOT NULL,
    nickname      VARCHAR(50),
    avatar_url    TEXT,
    email         VARCHAR(100),
    city          VARCHAR(50),
    occupation    VARCHAR(50),
    gender        SMALLINT,
    birthday      DATE,
    theme         VARCHAR(10) DEFAULT 'system',  -- light/dark/system
    language      VARCHAR(10) DEFAULT 'zh',      -- zh/en
    map_engine    VARCHAR(10),                   -- amap/osm；NULL 表示未设置（触发首次弹窗）
    location_share_enabled BOOLEAN DEFAULT TRUE,
    created_at    TIMESTAMPTZ DEFAULT NOW(),
    updated_at    TIMESTAMPTZ DEFAULT NOW()
);

-- 团队
CREATE TABLE teams (
    id           BIGSERIAL PRIMARY KEY,
    name         VARCHAR(50) NOT NULL,
    avatar_url   TEXT,
    description  TEXT,
    invite_code  CHAR(6) UNIQUE NOT NULL,
    owner_id     BIGINT NOT NULL REFERENCES users(id),
    member_limit INT DEFAULT 30,
    created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- 团队成员
CREATE TABLE team_members (
    team_id    BIGINT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role       SMALLINT DEFAULT 0,    -- 0 成员 1 队长
    joined_at  TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (team_id, user_id)
);

-- 团队活动（坐标统一 WGS84）
CREATE TABLE activities (
    id           BIGSERIAL PRIMARY KEY,
    team_id      BIGINT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    creator_id   BIGINT NOT NULL REFERENCES users(id),
    title        VARCHAR(100) NOT NULL,
    location     GEOGRAPHY(Point, 4326) NOT NULL,
    location_name VARCHAR(200),
    start_time   TIMESTAMPTZ,
    end_time     TIMESTAMPTZ,
    content      TEXT,
    notice       TEXT,
    visibility   VARCHAR(10) NOT NULL,    -- 'public' | 'private'
    created_at   TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_activities_location ON activities USING GIST(location);

-- 推荐内容
CREATE TABLE posts (
    id           BIGSERIAL PRIMARY KEY,
    author_id    BIGINT NOT NULL REFERENCES users(id),
    team_id      BIGINT REFERENCES teams(id),
    activity_id  BIGINT REFERENCES activities(id),
    post_type    SMALLINT NOT NULL,       -- 0 动态 1 活动
    title        VARCHAR(200),
    content      TEXT,
    visibility   VARCHAR(10) DEFAULT 'public',
    like_count   INT DEFAULT 0,
    comment_count INT DEFAULT 0,
    created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- 团队朋友圈
CREATE TABLE moments (
    id         BIGSERIAL PRIMARY KEY,
    team_id    BIGINT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    author_id  BIGINT NOT NULL REFERENCES users(id),
    content    TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 媒体文件
CREATE TABLE media_files (
    id         BIGSERIAL PRIMARY KEY,
    owner_type VARCHAR(20) NOT NULL,     -- post / moment / message / activity
    owner_id   BIGINT NOT NULL,
    media_type VARCHAR(10) NOT NULL,     -- image / audio / video
    url        TEXT NOT NULL,
    thumbnail_url TEXT,
    duration   INT,
    size_bytes BIGINT,
    sort_order SMALLINT DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_media_owner ON media_files(owner_type, owner_id);

-- 点赞
CREATE TABLE post_likes (
    post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (post_id, user_id)
);

-- 评论
CREATE TABLE post_comments (
    id         BIGSERIAL PRIMARY KEY,
    post_id    BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id    BIGINT NOT NULL REFERENCES users(id),
    parent_id  BIGINT REFERENCES post_comments(id),
    content    TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 用户实时定位（最新覆盖）
CREATE TABLE user_locations (
    user_id    BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    location   GEOGRAPHY(Point, 4326) NOT NULL,
    accuracy   REAL,
    speed      REAL,
    bearing    REAL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_user_locations_geo ON user_locations USING GIST(location);

-- 好友
CREATE TABLE friendships (
    user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_id  BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status     SMALLINT NOT NULL,      -- 0 待确认 1 已确认 2 已拒绝
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (user_id, friend_id)
);

-- 私聊会话
CREATE TABLE chat_conversations (
    id         BIGSERIAL PRIMARY KEY,
    user_a_id  BIGINT NOT NULL REFERENCES users(id),
    user_b_id  BIGINT NOT NULL REFERENCES users(id),
    last_message_id BIGINT,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_a_id, user_b_id),
    CHECK (user_a_id < user_b_id)
);

-- 私聊消息
CREATE TABLE chat_messages (
    id              BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    sender_id       BIGINT NOT NULL REFERENCES users(id),
    msg_type        VARCHAR(10) NOT NULL,    -- text/image/audio/video
    content         TEXT,
    media_url       TEXT,
    duration        INT,
    is_recalled     BOOLEAN DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_chat_msg_conv_time ON chat_messages(conversation_id, created_at DESC);

-- 已读位
CREATE TABLE chat_read_marks (
    conversation_id BIGINT NOT NULL,
    user_id         BIGINT NOT NULL,
    last_read_msg_id BIGINT NOT NULL,
    PRIMARY KEY (conversation_id, user_id)
);
```

---

## 六、后端 API 设计（RESTful）

### 6.1 通用约定
- 前缀：`/api/v1`
- 鉴权：`Authorization: Bearer <JWT>`
- 响应：`{ "code": 0, "msg": "ok", "data": {...} }`
- 分页：`?cursor=<id>&limit=20`
- 增量：`?since=<timestamp>`
- **坐标统一 WGS84**（lng, lat 顺序）

### 6.2 接口清单

#### 鉴权
| Method | Path | 说明 |
|--------|------|------|
| POST | /auth/register | 手机号注册 |
| POST | /auth/login | 登录 |
| POST | /auth/refresh | 刷新 token |
| POST | /auth/logout | 登出 |

#### 用户
| Method | Path | 说明 |
|--------|------|------|
| GET  | /users/me | 当前用户（含 `needs_map_setup` 标识，用于首次弹窗） |
| PUT  | /users/me | 修改资料 |
| PUT  | /users/me/settings | 主题/语言/地图引擎/隐私 |
| POST | /users/me/avatar | 上传头像 |

`PUT /users/me/settings` 请求体示例：
```json
{ "theme": "dark", "language": "zh", "map_engine": "amap" }
```

#### 团队
| Method | Path | 说明 |
|--------|------|------|
| POST   | /teams | 创建 |
| GET    | /teams/mine | 我的团队 |
| GET    | /teams/{id} | 团队详情 |
| POST   | /teams/join | 邀请码加入 |
| DELETE | /teams/{id}/members/me | 退出 |
| DELETE | /teams/{id} | 解散（队长） |
| GET    | /teams/{id}/members | 成员列表 |
| GET    | /teams/{id}/heartbeat?since= | 心跳合并：定位 + 公告变更 + 朋友圈未读 |

#### 活动
| Method | Path | 说明 |
|--------|------|------|
| POST   | /teams/{id}/activities | 创建 |
| GET    | /teams/{id}/activities | 列表 |
| GET    | /activities/{id} | 详情 |
| PUT    | /activities/{id} | 修改 |
| DELETE | /activities/{id} | 删除 |

#### 定位与地图
| Method | Path | 说明 |
|--------|------|------|
| POST | /locations/report | 上报位置（WGS84） |
| GET  | /locations/distance?from=&to= | 直线距离（PostGIS） |
| GET  | /locations/route?from=&to=&mode=&engine= | 路径规划 |
| GET  | /geo/poi/search?keyword=&lat=&lng=&engine= | POI 搜索 |
| GET  | /geo/reverse?lat=&lng=&engine= | 逆地理 |

#### 推荐
| Method | Path | 说明 |
|--------|------|------|
| GET    | /posts?cursor=&limit= | 流（含活动同步） |
| POST   | /posts | 发布动态 |
| GET    | /posts/{id} | 详情 |
| POST   | /posts/{id}/like | 点赞/取消 |
| POST   | /posts/{id}/comments | 评论 |
| GET    | /posts/{id}/comments | 评论列表 |

#### 团队朋友圈
| Method | Path | 说明 |
|--------|------|------|
| GET  | /teams/{id}/moments?since= | 增量 |
| POST | /teams/{id}/moments | 发布 |

#### 私聊
| Method | Path | 说明 |
|--------|------|------|
| GET  | /chats/conversations | 会话列表 |
| GET  | /chats/conversations/{id}/messages?since= | long-poll 25s |
| POST | /chats/conversations/{id}/messages | 发送 |
| POST | /chats/messages/{id}/recall | 撤回 |
| POST | /chats/{user_id}/start | 开启会话 |

#### 好友
| Method | Path | 说明 |
|--------|------|------|
| POST | /friends/requests | 发送请求 |
| GET  | /friends/requests | 待确认 |
| POST | /friends/requests/{id}/accept | 接受 |
| POST | /friends/requests/{id}/reject | 拒绝 |
| GET  | /friends | 好友列表 |

#### 媒体
| Method | Path | 说明 |
|--------|------|------|
| POST | /media/upload | multipart 直传 |

---

## 七、前端架构（Flutter + GetX）

### 7.1 目录
```
lib/
├── main.dart
├── app/{routes, bindings, theme}
├── core/
│   ├── network/            // Dio + Polling Manager
│   ├── storage/
│   ├── i18n/
│   ├── map/                // ★ 地图抽象层
│   │   ├── map_adapter.dart
│   │   ├── amap_adapter.dart
│   │   ├── osm_adapter.dart
│   │   ├── coord_convert.dart   // WGS84 ↔ GCJ-02
│   │   └── map_factory.dart
│   └── utils/
├── data/{models, providers, repositories}
├── modules/
│   ├── auth/
│   ├── splash/                  // 启动 + 首次地图引擎选择对话框
│   ├── discover/
│   ├── team/
│   ├── chat/
│   └── profile/
│       └── map_settings/        // 「我的 → 地图设置」
└── shared/widgets/
```

### 7.2 启动与首次引擎选择流程
```
启动 → SplashController
   ├── 读本地 token
   ├── 拉 GET /users/me
   ├── 若 user.map_engine == null → 弹「地图引擎选择」全屏对话框
   │     ├─ 用户选 amap/osm
   │     ├─ 本地 storage.write('map_engine', x)
   │     ├─ PUT /users/me/settings { map_engine: x }
   │     └─ Get.put<MapAdapter>(MapFactory.create(x), permanent:true)
   └── 否则直接 Get.put<MapAdapter>(MapFactory.create(saved), permanent:true)
   → 进入主导航
```

### 7.3 「我的 → 地图设置」页
```dart
class MapSettingsView extends GetView<MapSettingsController> {
  @override
  Widget build(_) => Obx(() => Column(children: [
    RadioListTile(
      title: Text('amap_title'.tr),
      subtitle: Text('amap_subtitle'.tr),
      value: MapEngine.amap,
      groupValue: controller.engine.value,
      onChanged: controller.switchTo,
    ),
    RadioListTile(
      title: Text('osm_title'.tr),
      subtitle: Text('osm_subtitle'.tr),
      value: MapEngine.osm,
      groupValue: controller.engine.value,
      onChanged: controller.switchTo,
    ),
    if (controller.engine.value == MapEngine.osm)
      ListTile(
        leading: Icon(Icons.download),
        title: Text('offline_map_download'.tr),
        onTap: controller.openOfflineDownload,
      ),
  ]));
}
```

### 7.4 轮询管理器
```dart
class PollingManager {
  final Map<String, Timer> _timers = {};
  void start(String key, Duration interval, Future Function() task);
  void stop(String key);
  void pauseAll();    // App 切后台
  void resumeAll();   // App 切前台
}
```

### 7.5 关键页面
1. 底部导航：四 tab
2. 团队地图页：`Get.find<MapAdapter>().buildMap(...)`，10s 刷新
3. 聊天页：列表 + 输入栏（文本/语音长按/相册/视频）
4. 发布页：富文本 + 多图/视频 + 地图选点
5. 离线地图页：OSM 引擎下显示

---

## 八、后端架构（Axum + sqlx）

### 8.1 工程结构
```
unii-server/
├── Cargo.toml
├── migrations/
├── src/
│   ├── main.rs
│   ├── config.rs
│   ├── error.rs
│   ├── state.rs
│   ├── middleware/{auth.rs, rate_limit.rs}
│   ├── routes/
│   │   ├── mod.rs
│   │   ├── auth.rs
│   │   ├── user.rs
│   │   ├── team.rs
│   │   ├── activity.rs
│   │   ├── post.rs
│   │   ├── moment.rs
│   │   ├── chat.rs
│   │   ├── friend.rs
│   │   ├── location.rs
│   │   ├── geo.rs           // POI / 逆地理 / 路径
│   │   └── media.rs
│   ├── service/
│   │   ├── geo/
│   │   │   ├── mod.rs
│   │   │   ├── coord.rs     // GCJ-02 ↔ WGS84
│   │   │   ├── amap.rs      // 高德 Web API
│   │   │   └── osrm.rs
│   │   └── ...
│   ├── model/
│   ├── dto/
│   └── util/
└── Dockerfile
```

### 8.2 关键依赖
```toml
[dependencies]
axum = { version = "0.7", features = ["multipart"] }
tokio = { version = "1", features = ["full"] }
sqlx = { version = "0.8", features = ["postgres","runtime-tokio-rustls","macros","chrono","uuid","bigdecimal"] }
tower-http = { version = "0.5", features = ["cors","trace","limit"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
jsonwebtoken = "9"
argon2 = "0.5"
geo = "0.28"
reqwest = { version = "0.12", features = ["json","rustls-tls"] }
chrono = { version = "0.4", features = ["serde"] }
tracing = "0.1"
tracing-subscriber = "0.3"
thiserror = "1"
anyhow = "1"
validator = { version = "0.18", features = ["derive"] }
```

### 8.3 鉴权中间件
```rust
pub async fn auth_middleware(
    State(state): State<AppState>,
    mut req: Request,
    next: Next,
) -> Result<Response, AppError> {
    let token = extract_bearer(&req)?;
    let claims = decode_jwt(&token, &state.jwt_secret)?;
    req.extensions_mut().insert(claims);
    Ok(next.run(req).await)
}
```

### 8.4 GET /users/me 含 needs_map_setup
```rust
#[derive(Serialize)]
pub struct MeResp {
    pub user: UserDto,
    pub needs_map_setup: bool,   // map_engine IS NULL
}
```

### 8.5 GeoService 路径规划
```rust
pub enum GeoEngine { Amap, Osm }

pub async fn plan_route(
    engine: GeoEngine, from: LatLng, to: LatLng, mode: RouteMode,
) -> Result<RouteResult> {
    match engine {
        GeoEngine::Amap => {
            let from_g = wgs84_to_gcj02(from);
            let to_g   = wgs84_to_gcj02(to);
            let raw = amap::direction(from_g, to_g, mode).await?;
            Ok(raw.into_wgs84())
        }
        GeoEngine::Osm => osrm::route(from, to, mode).await,
    }
}
```

### 8.6 长轮询接口
```rust
async fn poll_messages(...) -> Json<...> {
    let deadline = Instant::now() + Duration::from_secs(25);
    loop {
        let msgs = repo::fetch_after(conv_id, since).await?;
        if !msgs.is_empty() || Instant::now() >= deadline {
            return Json(msgs);
        }
        tokio::time::sleep(Duration::from_secs(1)).await;
    }
}
```

### 8.7 心跳合并接口
`GET /teams/{id}/heartbeat?since=` 返回：
```json
{
  "members": [{"user_id":1,"lng":..,"lat":..,"updated_at":..}],
  "activity_changes": [...],
  "moment_unread": 3
}
```

---

## 九、安全与隐私

| 项 | 方案 |
|----|------|
| 密码 | Argon2id 哈希 |
| Token | JWT（access 2h + refresh 30d）+ 黑名单 |
| 传输 | 全链路 HTTPS（Let's Encrypt） |
| 上传 | 服务端校验 MIME + 扩展名 + 大小限制（图 10M、视频 50M） |
| 定位隐私 | 用户开关 + 仅团队成员可见 + 不存历史轨迹 |
| 高德 Key | 仅在后端持有，前端通过 `/geo/*` 代理调用 |
| 限流 | tower-governor，登录接口 5 次/分钟 |
| SQL 注入 | sqlx 编译期校验 + 参数绑定 |
| XSS | 富文本入库前 HTML 转义 |
| 越权 | 所有团队/聊天接口校验 caller 是否团队成员 / 会话参与者 |

---

## 十、部署方案

### 10.1 Docker Compose
```yaml
services:
  postgres:
    image: postgis/postgis:16-3.4
    environment:
      POSTGRES_DB: unii
      POSTGRES_USER: unii
      POSTGRES_PASSWORD: ${DB_PASS}
    volumes: [pgdata:/var/lib/postgresql/data]

  minio:
    image: minio/minio
    command: server /data --console-address ":9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_USER}
      MINIO_ROOT_PASSWORD: ${MINIO_PASS}
    volumes: [miniodata:/data]

  osrm:                    # 可选：自建 OSM 路径规划
    image: osrm/osrm-backend
    command: osrm-routed --algorithm mld /data/region.osrm
    volumes: [./osrm-data:/data]

  unii-server:
    build: ./unii-server
    environment:
      DATABASE_URL: postgres://unii:${DB_PASS}@postgres:5432/unii
      JWT_SECRET: ${JWT_SECRET}
      AMAP_WEB_KEY: ${AMAP_WEB_KEY}
      OSRM_BASE_URL: http://osrm:5000
      S3_ENDPOINT: http://minio:9000
    depends_on: [postgres, minio]
    ports: ["8080:8080"]

  caddy:
    image: caddy:2
    ports: ["443:443","80:80"]
    volumes: [./Caddyfile:/etc/caddy/Caddyfile, caddydata:/data]

volumes: { pgdata: {}, miniodata: {}, caddydata: {} }
```

### 10.2 CI/CD
- GitHub Actions：Rust `cargo test` + `sqlx prepare`；Flutter `flutter test` + `build apk/ipa`
- 镜像推送私有 registry，服务器 `docker compose pull && up -d`

---

## 十一、性能与扩展性

| 维度 | 当前目标 | 横向扩展 |
|------|---------|---------|
| 并发用户 | 1k 在线 | 多副本 Axum + Nginx 负载均衡 |
| 定位写入 | 100 写/s | Redis 缓存最新位置，异步落库 |
| 消息推送 | 5s 拉取 | 后续可平滑升级 SSE / WebSocket |
| 媒体存储 | 100GB | 切换公有云 OSS + CDN |
| 数据库 | 单实例 | 主从 + 分区表（按月分 chat_messages） |
| 高德配额 | 个人 30 万次/日 | 升级企业 Key 或自建 OSRM 兜底 |

---

## 十二、开发里程碑（建议 8 周）

| 周 | 里程碑 |
|----|--------|
| W1 | 项目脚手架、CI、数据库迁移、鉴权 |
| W2 | 用户/我的模块（资料、主题、语言、隐私） |
| W3 | 团队模块（创建/加入/成员管理）、活动 CRUD |
| W4 | **MapAdapter 双引擎接入 + 登录后地图引擎选择弹窗 + 我的→地图设置**；定位上报 + 团队地图渲染；心跳合并接口 |
| W5 | 推荐模块（发布/列表/详情/点赞/评论）+ 媒体上传 |
| W6 | 团队朋友圈 + 私聊（文本/媒体）+ 长轮询 |
| W7 | 好友系统 + 通知红点 + 消息撤回 + OSM 离线下载 |
| W8 | 体验优化、压测、Bug 修复、上架准备 |

---

## 十三、风险与对策

| 风险 | 对策 |
|------|------|
| HTTP 轮询耗电/流量 | 分级间隔、心跳合并、后台暂停、长轮询兜底 |
| 定位精度差/室内漂移 | 客户端平滑 + 精度过滤；UI 显示精度圈 |
| 媒体上传失败 | 客户端断点续传 + 服务端 ETag 去重 |
| 团队人数膨胀 | 心跳接口 only diff（基于 since），避免全量 |
| 隐私合规 | 启动页弹隐私协议；权限按需申请；账号注销可彻底删除数据 |
| 高德 Key 被刷/超额 | 后端代理 + 用户级限流；提示用户切换 OSM |
| OSM 国内瓦片慢 | 自建瓦片缓存代理；推荐用户选高德 |
| 坐标系混乱 | 全链路 WGS84，仅 AmapAdapter 渲染前转换；单元测试覆盖 |
| 用户跳过引擎选择对话框 | 对话框不可点击外部关闭，无默认选项；未选不进入主界面 |

---

## 附录 A：技术选型说明

- **GetX**：路由、状态、DI、国际化一体化，学习曲线友好。
- **Axum + sqlx**：类型安全、零成本抽象、编译期 SQL 校验。
- **PostgreSQL + PostGIS**：地理查询原生支持。
- **HTTP 轮询**：项目硬性要求；分级 + 长轮询 + 心跳合并降本。
- **高德 + OSM 双引擎，用户手动选**：尊重用户选择，避免误判（边境地区、VPN 用户、海外华人等场景容易自动判错）；MapAdapter 抽象隔离差异。

## 附录 B：高德 Key 申请清单

1. 注册「高德开放平台」账号 → 实名认证
2. 创建应用 → 添加 Key：
   - **Android Key**：包名 + SHA1 调试/发布两套
   - **iOS Key**：BundleID
   - **Web 服务 Key**：用于后端代理（POI / 路径 / 逆地理）
3. 在 `unii-server` 注入 `AMAP_WEB_KEY`，移动端 SDK Key 通过远程配置下发
