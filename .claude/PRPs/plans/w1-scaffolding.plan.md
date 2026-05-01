# Plan: W1 — UNII 项目脚手架

## Summary
为 UNII 项目搭建端到端可启动的脚手架：Flutter (GetX) 移动端骨架 + Axum + sqlx Rust 后端骨架 + PostgreSQL/PostGIS 迁移 + JWT 鉴权（注册/登录/刷新/登出）+ Docker Compose 开发环境 + GitHub Actions CI。完成后 `docker compose up` 可启动后端，`flutter run` 可在模拟器上完成「注册→登录→进入主导航占位页」的最小闭环。

## User Story
作为 UNII 项目的开发者，我希望有一套可立即启动的前后端脚手架，**以便** 后续 W2–W8 的所有业务模块都能在统一的代码组织、错误处理、日志、CI 规范上进行开发，避免重复决策和返工。

## Problem → Solution
**当前**：仓库根目录仅有 `plan.md` 设计文档，无任何代码、无 CI、无可启动环境，团队无法立即开工。
**目标**：完成 W1 后，仓库具备 `unii-server/`（后端）+ `unii-app/`（前端）两个独立子项目，配合根目录的 `docker-compose.yml`、`.github/workflows/`、`.env.example`、`README.md`，新成员 `clone → 准备 .env → docker compose up → flutter run` 即可看到登录页并完成最小闭环。

## Metadata
- **Complexity**: Large（10+ 文件、跨技术栈、需要 CI 与 Docker 配置）
- **Source PRD**: `/Users/apple/developer/flutter_rust_app/plan.md`
- **PRD Phase**: W1（项目脚手架 + CI + 数据库迁移 + 鉴权）
- **Estimated Files**: 约 50 个新文件（Flutter ~20、Axum ~20、根/CI/Docker ~10）
- **Greenfield**: ✅ 工作区当前为空，无现有代码模式可参考；所有"Patterns to Mirror"取自上游官方文档（实施时通过 context7 MCP 二次校验最新版本）

---

## UX Design

### Before
```
┌────────────────────────────────┐
│ 仓库根：                        │
│   plan.md                      │
│ 状态：无代码、无环境            │
└────────────────────────────────┘
```

### After
```
┌────────────────────────────────┐
│ flutter_rust_app/              │
│   plan.md                      │
│   docker-compose.yml           │
│   .env.example                 │
│   README.md                    │
│   .github/workflows/ci.yml     │
│   unii-server/    (Axum)       │
│   unii-app/       (Flutter)    │
│                                │
│ 启动：                          │
│   docker compose up -d         │
│   cd unii-app && flutter run   │
│                                │
│ 用户体验：                      │
│   App 启动 → 登录页 → 注册 → │
│   登录 → 主导航占位（4 tab）   │
└────────────────────────────────┘
```

### Interaction Changes
| Touchpoint | Before | After | Notes |
|---|---|---|---|
| 登录页 | 不存在 | 手机号 + 密码两输入框 + 登录/注册切换 | 仅 UI + API 调用，无业务样式细化 |
| 注册流程 | 不存在 | 手机号 + 密码 + 确认密码 → POST /auth/register → 自动登录 | 后端 Argon2 哈希 |
| Token 持久化 | 不存在 | 登录成功后 access+refresh 存 get_storage | Dio 拦截器自动带 Bearer |
| 主导航占位 | 不存在 | 4 tab 底部导航（推荐 / 团队 / 私聊 / 我的），每页仅显示 "Coming in Wx" | W2 起逐 tab 实现 |

---

## Mandatory Reading

### 项目设计依据
| Priority | File | Lines | Why |
|---|---|---|---|
| **P0** | `/Users/apple/developer/flutter_rust_app/plan.md` | 全文 | 项目总体方案；W1 范围在第 12 章里程碑表 |
| P0 | `plan.md` | §3.2 技术栈表 | 所有依赖版本约束的唯一真相源 |
| P0 | `plan.md` | §5.2 数据库 DDL | W1 仅落 `users` 表的 DDL；其余表后续阶段迁移 |
| P0 | `plan.md` | §6.2 鉴权 API 清单 | W1 实现 4 个鉴权接口的契约 |
| P0 | `plan.md` | §7.1 Flutter 目录结构 + §8.1 Axum 工程结构 | 严格遵循 |
| P1 | `plan.md` | §9 安全与隐私 | Argon2id、JWT 双 token、限流 |
| P1 | `plan.md` | §10 部署方案 | docker-compose 模板基底 |
| P1 | `~/.claude/rules/ecc/common/*.md` | 全部 | ECC 通用规则（编码风格、安全、测试） |
| P1 | `~/.claude/rules/ecc/dart/*.md` | 全部 | Dart/Flutter 规则 |
| P1 | `~/.claude/rules/ecc/rust/*.md` | 全部 | Rust 规则 |
| P2 | `~/.claude/rules/ecc/zh/*.md` | 全部 | 中文版补充 |

### 实施时必须用 context7 MCP 拉的最新文档
| Topic | context7 library id（建议） | 用途 |
|---|---|---|
| Axum 0.7 路由/中间件/State | `tokio-rs/axum` | 防止用过时 0.6 写法 |
| sqlx 0.8 PgPool / Migrate | `launchbadge/sqlx` | 0.8 vs 0.7 在 macros、`PgPoolOptions` 上有差异 |
| Flutter 3.24 项目模板 | Flutter `flutter` repo | 确认 `flutter create` 默认结构 |
| GetX 4.6 路由/绑定 | `jonataslaw/getx` | `GetMaterialApp` + Bindings 写法 |
| Dio 5 拦截器 | `cfug/dio` | InterceptorsWrapper + retry 写法 |
| jsonwebtoken 9 (Rust) | `keats/jsonwebtoken` | encode/decode + 自定义 Claims |
| Argon2 0.5 (Rust) | `RustCrypto/password-hashes` | `PasswordHasher` API |

> 实施 Task 时，遇到任意 API 不确定 → 先 `mcp__context7__resolve-library-id` → `mcp__context7__query-docs`，再写代码。

---

## External Documentation

| Topic | Source | Key Takeaway |
|---|---|---|
| PostGIS 安装 | `postgis/postgis:16-3.4` Docker 镜像 | 直接用官方镜像；`CREATE EXTENSION IF NOT EXISTS postgis;` 在迁移里 |
| sqlx CLI | `cargo install sqlx-cli --no-default-features --features postgres,rustls` | CI 与本地都需要 |
| Flutter pub deps 顺序 | `flutter pub get` 在 build 前 | CI 缓存 `~/.pub-cache` 提速 |
| GitHub Actions Rust 缓存 | `Swatinem/rust-cache@v2` | 标准做法 |
| GitHub Actions Flutter | `subosito/flutter-action@v2` | 锁定 stable channel + version |

---

## Patterns to Mirror

> **重要**：当前为 greenfield，无内部代码可镜像。以下"模式"取自各库官方文档与 `~/.claude/rules/ecc/` 通用规则，将作为本项目代码风格的 **第 0 版基准**。后续 plan（W2+）应以本 W1 产出的 _实际_ 代码作为镜像源。

### NAMING_CONVENTION
- **Rust**：snake_case 文件、模块；PascalCase struct/enum/trait；SCREAMING_SNAKE 常量
- **Dart**：lower_snake_case 文件名；PascalCase 类；camelCase 变量/方法
- **DB**：snake_case 表/列；表名复数（`users`, `teams`）；外键 `<entity>_id`

### ERROR_HANDLING — Rust 端统一 AppError
```rust
// SOURCE: 行业标准 Axum 0.7 + thiserror，将落地在 unii-server/src/error.rs
use axum::{http::StatusCode, response::{IntoResponse, Response}, Json};
use serde_json::json;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum AppError {
    #[error("invalid credentials")]
    InvalidCredentials,
    #[error("unauthorized")]
    Unauthorized,
    #[error("not found: {0}")]
    NotFound(String),
    #[error("validation: {0}")]
    Validation(String),
    #[error("conflict: {0}")]
    Conflict(String),
    #[error(transparent)]
    Sqlx(#[from] sqlx::Error),
    #[error(transparent)]
    Jwt(#[from] jsonwebtoken::errors::Error),
    #[error("internal: {0}")]
    Internal(String),
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, code, msg) = match &self {
            AppError::InvalidCredentials => (StatusCode::UNAUTHORIZED, 1001, self.to_string()),
            AppError::Unauthorized => (StatusCode::UNAUTHORIZED, 1002, self.to_string()),
            AppError::NotFound(_) => (StatusCode::NOT_FOUND, 1003, self.to_string()),
            AppError::Validation(_) => (StatusCode::BAD_REQUEST, 1004, self.to_string()),
            AppError::Conflict(_) => (StatusCode::CONFLICT, 1005, self.to_string()),
            _ => {
                tracing::error!(error = ?self, "internal error");
                (StatusCode::INTERNAL_SERVER_ERROR, 5000, "internal error".into())
            }
        };
        (status, Json(json!({ "code": code, "msg": msg, "data": null }))).into_response()
    }
}
```

### RESPONSE_ENVELOPE
```rust
// SOURCE: plan.md §6.1 响应格式
#[derive(serde::Serialize)]
pub struct ApiResp<T> { pub code: i32, pub msg: &'static str, pub data: T }
impl<T> ApiResp<T> { pub fn ok(data: T) -> Json<Self> { Json(Self { code: 0, msg: "ok", data }) } }
```

### LOGGING_PATTERN
```rust
use tracing::{info, instrument};

#[instrument(skip(state, body), fields(phone=%body.phone))]
pub async fn login(State(state): State<AppState>, Json(body): Json<LoginReq>) -> Result<Json<ApiResp<LoginResp>>, AppError> {
    info!(user_id = %user.id, "login success");
    Ok(ApiResp::ok(resp))
}
```
- 启动时 `tracing_subscriber` 通过 `RUST_LOG` 环境变量控制级别
- 默认 `info` 级别，DB 查询 `debug`

### REPOSITORY_PATTERN — sqlx 仓储层
```rust
use sqlx::PgPool;

pub async fn find_by_phone(pool: &PgPool, phone: &str) -> Result<Option<UserRow>, sqlx::Error> {
    sqlx::query_as!(
        UserRow,
        r#"SELECT id, phone, password_hash, username, nickname, avatar_url
           FROM users WHERE phone = $1"#,
        phone
    )
    .fetch_optional(pool)
    .await
}
```
- **必须用 `query_as!` / `query!` 宏**（编译期校验）；CI 跑 `cargo sqlx prepare --check`

### MIDDLEWARE_PATTERN — Axum 0.7 from_fn JWT 鉴权
```rust
use axum::{extract::{Request, State}, middleware::Next, response::Response};

#[derive(Clone)]
pub struct Claims { pub sub: i64, pub exp: usize }

pub async fn auth_mw(State(state): State<AppState>, mut req: Request, next: Next) -> Result<Response, AppError> {
    let token = req.headers().get("authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|s| s.strip_prefix("Bearer "))
        .ok_or(AppError::Unauthorized)?;
    let data = jsonwebtoken::decode::<Claims>(
        token,
        &jsonwebtoken::DecodingKey::from_secret(state.jwt_secret.as_bytes()),
        &jsonwebtoken::Validation::default(),
    )?;
    req.extensions_mut().insert(data.claims);
    Ok(next.run(req).await)
}
```

### TEST_STRUCTURE — Rust 集成测试
```rust
#[sqlx::test]
async fn register_then_login(pool: sqlx::PgPool) {
    let app = build_app_with_pool(pool).await;
    let body = serde_json::json!({"phone":"13800001111","password":"Pa$$w0rd","username":"alice"});
    let resp = app.clone().oneshot(post_json("/api/v1/auth/register", &body)).await.unwrap();
    assert_eq!(resp.status(), 200);
}
```
- 用 `#[sqlx::test]` 自动准备临时库；CI 启用 `DATABASE_URL` 指向 `postgres` service container

### FLUTTER_GETX_PATTERN — Controller + Binding
```dart
class AuthController extends GetxController {
  final isLoading = false.obs;
  final phone = ''.obs;
  final password = ''.obs;

  Future<void> login() async {
    isLoading.value = true;
    try {
      final tokens = await Get.find<AuthRepo>().login(phone.value, password.value);
      await Get.find<TokenStorage>().save(tokens);
      Get.offAllNamed(Routes.HOME);
    } on DioException catch (e) {
      Get.snackbar('login_failed'.tr, e.response?.data?['msg'] ?? 'network_error'.tr);
    } finally {
      isLoading.value = false;
    }
  }
}

class AuthBinding implements Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthController());
  }
}
```

### DIO_INTERCEPTOR_PATTERN — JWT 自动注入 + 401 刷新
```dart
class AuthInterceptor extends QueuedInterceptorsWrapper {
  final TokenStorage storage;
  final AuthRepo repo;
  AuthInterceptor(this.storage, this.repo);

  @override
  void onRequest(RequestOptions opt, RequestInterceptorHandler handler) async {
    final t = await storage.access();
    if (t != null) opt.headers['Authorization'] = 'Bearer $t';
    handler.next(opt);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final ok = await repo.refresh();
      if (ok) {
        final retry = await Dio().fetch(err.requestOptions);
        return handler.resolve(retry);
      }
      Get.offAllNamed(Routes.LOGIN);
    }
    handler.next(err);
  }
}
```

---

## Files to Change

> 全部为 CREATE（greenfield）。

### 根目录
| File | Action | Justification |
|---|---|---|
| `README.md` | CREATE | quickstart：clone → cp .env → docker compose up → flutter run |
| `.gitignore` | CREATE | Rust + Flutter + Node + IDE 通用忽略 |
| `.env.example` | CREATE | DATABASE_URL / JWT_SECRET / AMAP_WEB_KEY 等占位 |
| `docker-compose.yml` | CREATE | postgres+postgis、unii-server、（可选 minio） |
| `Caddyfile` | CREATE | 占位（W8 启用 TLS 时填 domain） |

### CI
| File | Action | Justification |
|---|---|---|
| `.github/workflows/server-ci.yml` | CREATE | Rust：fmt + clippy + sqlx prepare check + cargo test |
| `.github/workflows/app-ci.yml` | CREATE | Flutter：format + analyze + test |

### 后端 unii-server/
| File | Action | Justification |
|---|---|---|
| `unii-server/Cargo.toml` | CREATE | 依赖固定版本（plan §8.2） |
| `unii-server/.sqlx/` | CREATE (dir) | sqlx prepare 输出，纳入版本控制 |
| `unii-server/Dockerfile` | CREATE | 多阶段 builder + distroless |
| `unii-server/.dockerignore` | CREATE | 排除 target/、.git |
| `unii-server/migrations/0001_init.sql` | CREATE | 启 PostGIS + users 表 + 索引 |
| `unii-server/src/main.rs` | CREATE | tokio runtime + 路由装配 + tracing init |
| `unii-server/src/config.rs` | CREATE | 从 env 读取 + Validate |
| `unii-server/src/state.rs` | CREATE | AppState：PgPool + jwt_secret |
| `unii-server/src/error.rs` | CREATE | AppError + IntoResponse |
| `unii-server/src/dto/mod.rs` | CREATE | mod 入口 |
| `unii-server/src/dto/auth.rs` | CREATE | RegisterReq/LoginReq/TokenResp |
| `unii-server/src/dto/common.rs` | CREATE | ApiResp<T> 响应壳 |
| `unii-server/src/model/mod.rs` | CREATE | mod 入口 |
| `unii-server/src/model/user.rs` | CREATE | UserRow（FromRow） |
| `unii-server/src/middleware/mod.rs` | CREATE | mod 入口 |
| `unii-server/src/middleware/auth.rs` | CREATE | JWT 鉴权中间件 |
| `unii-server/src/routes/mod.rs` | CREATE | 路由聚合（仅含 auth + health） |
| `unii-server/src/routes/auth.rs` | CREATE | register/login/refresh/logout |
| `unii-server/src/routes/health.rs` | CREATE | GET /healthz |
| `unii-server/src/service/mod.rs` | CREATE | mod 入口 |
| `unii-server/src/service/user_repo.rs` | CREATE | find_by_phone / insert |
| `unii-server/src/util/mod.rs` | CREATE | mod 入口 |
| `unii-server/src/util/password.rs` | CREATE | Argon2id hash + verify |
| `unii-server/src/util/jwt.rs` | CREATE | issue_access / issue_refresh / decode |
| `unii-server/tests/auth.rs` | CREATE | 注册→登录→刷新 集成测试 |

### 前端 unii-app/
| File | Action | Justification |
|---|---|---|
| `unii-app/pubspec.yaml` | CREATE | get / dio / get_storage / geolocator（仅声明，W4 用） |
| `unii-app/analysis_options.yaml` | CREATE | flutter_lints + 严格 mode |
| `unii-app/lib/main.dart` | CREATE | GetMaterialApp + 初始 Bindings |
| `unii-app/lib/app/routes/app_routes.dart` | CREATE | 路由常量 |
| `unii-app/lib/app/routes/app_pages.dart` | CREATE | GetPage 列表 |
| `unii-app/lib/app/bindings/initial_binding.dart` | CREATE | 全局依赖注入（Dio、Storage、Repos） |
| `unii-app/lib/app/theme/app_theme.dart` | CREATE | light/dark 主题 |
| `unii-app/lib/core/network/dio_client.dart` | CREATE | Dio 单例 + AuthInterceptor |
| `unii-app/lib/core/storage/token_storage.dart` | CREATE | get_storage 封装 |
| `unii-app/lib/core/i18n/translations.dart` | CREATE | zh/en 字典（W1 仅 auth + nav） |
| `unii-app/lib/data/models/auth.dart` | CREATE | TokensDto / UserDto |
| `unii-app/lib/data/repositories/auth_repo.dart` | CREATE | register / login / refresh / logout |
| `unii-app/lib/modules/auth/login_view.dart` | CREATE | 登录 + 注册切换 UI |
| `unii-app/lib/modules/auth/auth_controller.dart` | CREATE | 表单状态 + 调用 repo |
| `unii-app/lib/modules/auth/auth_binding.dart` | CREATE | DI |
| `unii-app/lib/modules/home/home_view.dart` | CREATE | 4 tab 占位（推荐/团队/私聊/我的） |
| `unii-app/lib/modules/home/home_binding.dart` | CREATE | DI |
| `unii-app/lib/modules/home/tabs/discover_placeholder.dart` | CREATE | "Coming in W5" |
| `unii-app/lib/modules/home/tabs/team_placeholder.dart` | CREATE | "Coming in W3" |
| `unii-app/lib/modules/home/tabs/chat_placeholder.dart` | CREATE | "Coming in W6" |
| `unii-app/lib/modules/home/tabs/profile_placeholder.dart` | CREATE | "Coming in W2" |
| `unii-app/test/auth_controller_test.dart` | CREATE | mock repo，验证 login 状态机 |

## NOT Building（W1 范围明确排除，留给后续阶段）
- 用户资料完整字段（W2）
- 团队/活动/定位（W3–W4）
- 推荐/朋友圈/媒体上传（W5–W6）
- 私聊/好友（W6–W7）
- 离线地图、双地图引擎切换（W4 + W7）
- Argon2 参数硬性合规调优（用 Argon2id 默认参数即可）
- 限流、CORS 自定义白名单（W8 安全加固）
- Refresh token 黑名单/旋转（仅做基础刷新；W7 安全加固时再补）
- 国际化全字典（W1 只覆盖登录页 + 主导航 6–10 个键）
- 代码签名、上架配置（W8）

---

## Step-by-Step Tasks

> 每个 Task 都要在完成后跑对应 VALIDATE 命令。Task 之间存在依赖（标注 `DEPENDS_ON`）。

### Task 1：根目录基础与 Docker Compose
- **ACTION**：创建根目录配置文件
- **IMPLEMENT**：
  - `.gitignore`：合并 GitHub 官方 Rust + Flutter + macOS 模板
  - `.env.example`：列出 `DATABASE_URL`、`JWT_SECRET`、`AMAP_WEB_KEY`、`RUST_LOG=info`
  - `docker-compose.yml`：service `postgres`（image: `postgis/postgis:16-3.4`）、`unii-server`（暂时 `build: ./unii-server`）；postgres 暴露 5432，server 暴露 8080；postgres data volume；env 从根 `.env`
  - `README.md`：5 段（项目简介 / 前置依赖 / 启动后端 / 启动前端 / 故障排查）
- **MIRROR**：plan.md §10.1
- **GOTCHA**：postgres 镜像的 healthcheck 必须等 `pg_isready` 通过，server depends_on 用 `condition: service_healthy`
- **VALIDATE**：
  ```bash
  docker compose config
  docker compose up -d postgres
  docker compose ps   # postgres healthy
  ```

### Task 2：Rust 工程初始化
- **DEPENDS_ON**：Task 1
- **ACTION**：在 `unii-server/` 用 `cargo new --bin` 初始化，写 `Cargo.toml`
- **IMPLEMENT**：依赖按 plan §8.2 全量列出；`[profile.release] lto = "thin"`；`rustfmt.toml`（max_width=100）
- **MIRROR**：plan.md §8.2
- **GOTCHA**：`sqlx` 必须开 `runtime-tokio-rustls`；`reqwest` 同样开 `rustls-tls` 避免 OpenSSL 依赖
- **VALIDATE**：
  ```bash
  cd unii-server && cargo check
  ```

### Task 3：sqlx 迁移 0001_init
- **DEPENDS_ON**：Task 1, 2
- **ACTION**：写第一条迁移
- **IMPLEMENT**：`unii-server/migrations/0001_init.sql`：
  ```sql
  CREATE EXTENSION IF NOT EXISTS postgis;
  CREATE TABLE users (
      id BIGSERIAL PRIMARY KEY,
      phone VARCHAR(20) UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      username VARCHAR(50) UNIQUE NOT NULL,
      nickname VARCHAR(50),
      avatar_url TEXT,
      email VARCHAR(100),
      city VARCHAR(50),
      occupation VARCHAR(50),
      gender SMALLINT,
      birthday DATE,
      theme VARCHAR(10) DEFAULT 'system',
      language VARCHAR(10) DEFAULT 'zh',
      map_engine VARCHAR(10),
      location_share_enabled BOOLEAN DEFAULT TRUE,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW()
  );
  CREATE INDEX idx_users_phone ON users(phone);
  ```
- **MIRROR**：plan.md §5.2 users 表
- **GOTCHA**：W1 仅落 users 表；其余表（teams/activities/posts...）由后续 plan 各自迁移文件添加
- **VALIDATE**：
  ```bash
  cargo install sqlx-cli --no-default-features --features postgres,rustls
  export DATABASE_URL=postgres://unii:unii@localhost:5432/unii
  sqlx database create && sqlx migrate run
  psql $DATABASE_URL -c "\dt"
  ```

### Task 4：error / dto / response 壳
- **DEPENDS_ON**：Task 2
- **ACTION**：写 `src/error.rs`、`src/dto/common.rs`、`src/dto/auth.rs`
- **IMPLEMENT**：见上文 ERROR_HANDLING、RESPONSE_ENVELOPE
- **MIRROR**：上文 ERROR_HANDLING、RESPONSE_ENVELOPE
- **IMPORTS**：`axum`、`thiserror`、`serde`、`serde_json`
- **GOTCHA**：`#[error(transparent)]` + `#[from]` 让 `?` 自动转换；不要手写 `From` impl
- **VALIDATE**：`cargo check`

### Task 5：config / state / main 装配
- **DEPENDS_ON**：Task 4
- **IMPLEMENT**：
  - `Config { database_url, jwt_secret, port }`，用 `validator` 检查长度
  - `AppState { db: PgPool, jwt_secret: Arc<str> }`
  - `main`：tracing init → load config → `PgPoolOptions::new().max_connections(20).connect(...)` → router → `axum::serve(...).await`
- **MIRROR**：上文 LOGGING_PATTERN
- **IMPORTS**：`tokio`, `tracing_subscriber::EnvFilter`
- **GOTCHA**：`PgPool` 必须在 main 内 `await`，不能放静态变量
- **VALIDATE**：`cargo run` + `curl http://localhost:8080/healthz`

### Task 6：password util + jwt util
- **DEPENDS_ON**：Task 4
- **IMPLEMENT**：
  - password：`hash(plain) -> String`、`verify(plain, hash) -> bool`，Argon2id 默认参数
  - jwt：`issue_access(uid)`（exp=2h）、`issue_refresh(uid)`（exp=30d）、`decode(token) -> Claims`
- **MIRROR**：jsonwebtoken 9 + argon2 0.5 官方 README
- **GOTCHA**：Argon2 的 `PasswordHasher::hash_password` 需要 `SaltString::generate(&mut OsRng)`；不要复用 salt
- **VALIDATE**：`cargo test util::`

### Task 7：user_repo + auth routes
- **DEPENDS_ON**：Task 3, 5, 6
- **IMPLEMENT**：4 个端点
  - `POST /api/v1/auth/register`：校验 → 查重 → hash → insert → access+refresh
  - `POST /api/v1/auth/login`：find_by_phone → verify → 签发
  - `POST /api/v1/auth/refresh`：解码 refresh → 新签 access
  - `POST /api/v1/auth/logout`：W1 简化为客户端丢弃；接口返回 ok
- **MIRROR**：上文 REPOSITORY_PATTERN
- **GOTCHA**：所有 SQL 必须 `query!`/`query_as!`；CI 跑 `cargo sqlx prepare --check`
- **VALIDATE**：
  ```bash
  curl -X POST localhost:8080/api/v1/auth/register \
       -H 'content-type: application/json' \
       -d '{"phone":"13800001111","password":"Test1234!","username":"alice"}'
  ```

### Task 8：JWT 中间件 + 受保护示例
- **DEPENDS_ON**：Task 7
- **IMPLEMENT**：见上文 MIDDLEWARE_PATTERN；新增 `GET /api/v1/users/me`（W1 占位返回 `{ id, phone, needs_map_setup: true }`）
- **MIRROR**：上文 MIDDLEWARE_PATTERN
- **GOTCHA**：用 `with_state` + `from_fn_with_state` 才能注入 state
- **VALIDATE**：用上面拿到的 token curl `/users/me`

### Task 9：后端集成测试
- **DEPENDS_ON**：Task 7, 8
- **IMPLEMENT**：见上文 TEST_STRUCTURE；覆盖 register → login → refresh → me
- **MIRROR**：上文 TEST_STRUCTURE
- **IMPORTS**：`tower::ServiceExt`, `axum::body::Body`
- **GOTCHA**：`#[sqlx::test]` 自动跑 migrations；CI service container 须暴露 `DATABASE_URL`
- **VALIDATE**：`DATABASE_URL=... cargo test --test auth`

### Task 10：Dockerfile（多阶段）
- **DEPENDS_ON**：Task 7
- **IMPLEMENT**：阶段 1 `rust:1-slim` + sqlx-cli + 编译；阶段 2 `gcr.io/distroless/cc-debian12` 拷贝 binary；端口 8080
- **GOTCHA**：把 `.sqlx/` 目录拷进 builder；`SQLX_OFFLINE=true`
- **VALIDATE**：`docker build -t unii-server unii-server/ && docker compose up -d`

### Task 11：Flutter 工程初始化
- **DEPENDS_ON**：Task 1
- **ACTION**：`flutter create unii-app --org com.unii --platforms=android,ios`
- **IMPLEMENT**：`pubspec.yaml`：依赖 `get: ^4.6.6`、`dio: ^5.7.0`、`get_storage: ^2.1.1`、`geolocator: ^12.0.0`、`flutter_localizations`；`analysis_options.yaml` 启 `flutter_lints` + `prefer_relative_imports`
- **MIRROR**：plan.md §7.1
- **GOTCHA**：iOS Podfile `platform :ios, '13.0'`；Android `minSdkVersion 21`
- **VALIDATE**：`flutter pub get && flutter analyze`

### Task 12：Flutter 路由 + 主题 + initial binding
- **DEPENDS_ON**：Task 11
- **IMPLEMENT**：
  - `app_routes.dart`：`LOGIN`、`HOME` 常量
  - `app_pages.dart`：两条 GetPage（login/home）+ binding
  - `app_theme.dart`：light + dark `ThemeData`
  - `initial_binding.dart`：注入 `Dio`、`TokenStorage`、`AuthRepo`（permanent）
  - `main.dart`：`WidgetsFlutterBinding.ensureInitialized` → `GetStorage.init` → `runApp(GetMaterialApp(initialBinding, getPages, translations))`
- **MIRROR**：上文 FLUTTER_GETX_PATTERN
- **GOTCHA**：`GetMaterialApp` 必须设 `initialRoute`
- **VALIDATE**：`flutter analyze && flutter test`

### Task 13：网络层 + token 持久化
- **DEPENDS_ON**：Task 12
- **IMPLEMENT**：见上文 DIO_INTERCEPTOR_PATTERN；`baseUrl` 从 `--dart-define=API_BASE_URL=...` 读取（默认 Android `http://10.0.2.2:8080`、iOS `http://localhost:8080`）
- **MIRROR**：上文 DIO_INTERCEPTOR_PATTERN
- **GOTCHA**：QueuedInterceptorsWrapper 处理 401 时避免无限重试（refresh 失败立即跳登录）
- **VALIDATE**：手工触发过期 token，验证自动刷新或跳回登录

### Task 14：Auth 模块 UI
- **DEPENDS_ON**：Task 13
- **IMPLEMENT**：
  - 单页面 Tab 切换 登录/注册；GetX `Obx` 响应 isLoading
  - 注册成功后立即调用 login，跳 HOME
- **MIRROR**：上文 FLUTTER_GETX_PATTERN
- **GOTCHA**：手机号 `^1[3-9]\d{9}$`；密码 ≥8 位含数字+字母
- **VALIDATE**：`flutter test test/auth_controller_test.dart`

### Task 15：Home 占位 + 4 tab 导航
- **DEPENDS_ON**：Task 12
- **IMPLEMENT**：`BottomNavigationBar` + `IndexedStack`；4 placeholder
  - 推荐 → "Coming in W5"
  - 团队 → "Coming in W3"
  - 私聊 → "Coming in W6"
  - 我的 → "Coming in W2"
- **GOTCHA**：HOME 路由挂 AuthGuard：在 binding 里读 token，无则 `Get.offAllNamed(LOGIN)`
- **VALIDATE**：`flutter run` 完成 注册 → 登录 → 看到 4 tab

### Task 16：i18n 字典（W1 子集）
- **DEPENDS_ON**：Task 12
- **IMPLEMENT**：键：`login_title`、`register_title`、`phone`、`password`、`submit`、`tab_discover/team/chat/profile`、`coming_soon`、`login_failed`、`network_error`，提供 zh + en
- **MIRROR**：GetX `Translations` 官方
- **GOTCHA**：W1 暂不支持运行时切语言（W2 在「我的」页加切换）；初始用系统 locale
- **VALIDATE**：`flutter analyze`

### Task 17：CI — Server
- **DEPENDS_ON**：Task 9
- **IMPLEMENT**：`.github/workflows/server-ci.yml`
  - trigger：push、pr，paths: `unii-server/**`
  - jobs：fmt → clippy → sqlx prepare check → test（service container postgis）
  - 用 `Swatinem/rust-cache@v2`
- **GOTCHA**：service container 启动慢，第一步 `pg_isready` 等待
- **VALIDATE**：本地 `act -j test` 或 push 触发观察

### Task 18：CI — App
- **DEPENDS_ON**：Task 14, 16
- **IMPLEMENT**：`.github/workflows/app-ci.yml`
  - trigger：push、pr，paths: `unii-app/**`
  - jobs：analyze → test → build apk --debug
  - 用 `subosito/flutter-action@v2`，channel: stable
- **GOTCHA**：缓存 `~/.gradle` + `~/.pub-cache`
- **VALIDATE**：push 后观察 GitHub Actions

### Task 19：README + 故障排查文档
- **DEPENDS_ON**：所有
- **IMPLEMENT**：5 段
  1. 项目简介
  2. 前置依赖（Rust 1.81+、Flutter 3.24+、Docker、PostgreSQL CLI）
  3. 启动后端（cp .env、docker compose up、sqlx migrate run）
  4. 启动前端（flutter pub get、flutter run --dart-define=...）
  5. 故障排查（端口冲突、DB 连接、token 失效、模拟器网络）
- **VALIDATE**：人工 review

---

## Testing Strategy

### Unit Tests

| Test | Input | Expected Output | Edge? |
|---|---|---|---|
| `password::hash_then_verify` | "Pa$$w0rd" | verify=true | ✗ |
| `password::verify_wrong` | hash, "wrong" | verify=false | ✓ |
| `jwt::issue_then_decode` | uid=42 | claims.sub=42 | ✗ |
| `jwt::decode_expired` | exp=过去 | Err(Expired) | ✓ |
| `jwt::decode_tampered` | 改一位 | Err(Invalid) | ✓ |
| `auth_controller_test.login_loading` | mock repo 延时 | isLoading=true→false | ✓ |
| `auth_controller_test.login_401` | mock repo throw 401 | snackbar 触发 | ✓ |

### Integration Tests (Rust)

| Test | Path |
|---|---|
| register → login → me 闭环 | `tests/auth.rs::register_then_login` |
| 重复注册返回 Conflict | `tests/auth.rs::duplicate_register` |
| 错误密码 InvalidCredentials | `tests/auth.rs::wrong_password` |
| 无 Token → 401 | `tests/auth.rs::missing_token` |
| 过期 Token → 401 | `tests/auth.rs::expired_token` |

### Edge Cases Checklist
- [ ] 空手机号 / 空密码 → 400
- [ ] 手机号格式非法 → 400
- [ ] 密码 <8 位 → 400
- [ ] 重复注册同一手机号 → 409
- [ ] DB 不可达 → 500（且日志记录）
- [ ] JWT 密钥未设置 → 启动失败
- [ ] 模拟器：Android 用 10.0.2.2 / iOS 用 localhost

---

## Validation Commands

### Static Analysis
```bash
cd unii-server && cargo fmt --check && cargo clippy --all-targets -- -D warnings
cd unii-app && flutter analyze
```
EXPECT：零错误零警告

### SQL 校验
```bash
cd unii-server && SQLX_OFFLINE=false cargo sqlx prepare --check --workspace
```
EXPECT：query 与 schema 一致

### Unit Tests
```bash
cd unii-server && cargo test --lib
cd unii-app && flutter test
```
EXPECT：全绿

### Integration Tests
```bash
docker compose up -d postgres
export DATABASE_URL=postgres://unii:unii@localhost:5432/unii
cd unii-server && sqlx migrate run && cargo test --test auth
```
EXPECT：全绿

### 端到端冒烟
```bash
docker compose up -d
sleep 5
curl -sf http://localhost:8080/healthz
curl -X POST http://localhost:8080/api/v1/auth/register \
     -H 'content-type: application/json' \
     -d '{"phone":"13800001111","password":"Test1234!","username":"alice"}'
TOKEN=$(curl -s -X POST http://localhost:8080/api/v1/auth/login \
     -H 'content-type: application/json' \
     -d '{"phone":"13800001111","password":"Test1234!"}' | jq -r .data.access_token)
curl -H "Authorization: Bearer $TOKEN" http://localhost:8080/api/v1/users/me
```

### Flutter 手工冒烟
```bash
cd unii-app
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080  # Android
# 或
flutter run --dart-define=API_BASE_URL=http://localhost:8080  # iOS
```
- 启动 → 登录页
- 切到注册 → 提交 → 自动登录 → 进入 4 tab home
- kill 后重启 → token 持久化生效，直接进 home

---

## Acceptance Criteria
- [ ] 所有 19 个 Task 完成
- [ ] 全部 Validation Commands 通过
- [ ] `docker compose up` 一键启动后端 + DB
- [ ] `flutter run` 完成「注册→登录→主导航」最小闭环
- [ ] CI 在 GitHub Actions 上 server-ci 与 app-ci 双绿
- [ ] README 步骤经一台干净机器（或 fresh container）验证可复现
- [ ] 无 hardcoded 密钥（JWT_SECRET 走 env）

## Completion Checklist
- [ ] 代码遵循 Patterns to Mirror（命名、错误、日志、Repo、Test 模式）
- [ ] 错误处理统一通过 AppError + IntoResponse
- [ ] 日志用 tracing 结构化字段（不用 println）
- [ ] 测试覆盖 password / jwt / auth 三个核心
- [ ] 无硬编码 URL / 端口
- [ ] README 含故障排查
- [ ] 不引入 W2+ 范围功能（NOT Building 严格遵守）

## Risks
| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| sqlx 0.8 与 plan.md 中 0.7 写法差异 | 中 | 中 | Task 实施时 context7 拉 launchbadge/sqlx 最新文档；preferring `query_as!` 宏 |
| Axum 0.7 中间件 API 与早期教程不一致 | 中 | 中 | 用 context7 拉 tokio-rs/axum；优先看官方 examples |
| iOS 模拟器无法访问 host 8080 | 低 | 低 | README 说明 iOS 用 `localhost`、Android 用 `10.0.2.2` |
| postgis 镜像首次启动慢 | 低 | 低 | docker-compose healthcheck + depends_on condition |
| Argon2 默认参数在弱机性能差 | 低 | 低 | W1 用默认；W8 安全审计时按 hardware benchmark 调整 |
| CI service container 启动竞态 | 中 | 低 | step 第一步 `pg_isready -h postgres -p 5432 -t 30` |
| JWT 密钥提交进 git | 低 | 高 | `.env` 加 `.gitignore`；CI 用 `secrets.JWT_SECRET` |

## Notes
- 本 plan 严格落 plan.md 第 12 章 W1 范围，不向前/向后越界
- 完成后请把实际产出（特别是 `error.rs`、`auth.rs`、`dio_client.dart`、`login_view.dart`）登记为 W2+ 后续 plan 的"Patterns to Mirror"主源
- 本 plan 标注的 context7 查询点应在每个 Task 真正写代码前做一次，避免依赖过时知识
- 完成度自评信心：8/10（greenfield 单遍执行可达，主要风险是 0.7/0.8 库的 API 漂移，已通过 context7 兜底）
