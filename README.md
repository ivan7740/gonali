# UNII

> Cross-platform social/teaming app — Flutter (GetX) client + Rust (Axum + sqlx) backend + PostgreSQL/PostGIS.

W1 milestone (this commit) ships the project scaffold: an end-to-end runnable shell with auth (register / login / refresh / logout), Docker Compose dev environment, GitHub Actions CI, and a 4-tab home placeholder ready for W2+ feature work. See `plan.md` for the full roadmap.

## Prerequisites

| Tool | Min Version | Why |
|---|---|---|
| Rust | 1.81+ (stable) | backend toolchain |
| Flutter SDK | 3.24+ (stable) | mobile client |
| Docker + Compose v2 | 24+ | local Postgres/PostGIS + backend container |
| PostgreSQL CLI (`psql`) | 14+ | optional — manual DB inspection |
| `sqlx-cli` | 0.8 | DB migration runner — `cargo install sqlx-cli --no-default-features --features postgres,rustls` |

iOS dev additionally needs Xcode 15+; Android dev needs Android Studio + SDK 34.

## Start the Backend

```bash
# 1. Prepare env
cp .env.example .env
# edit .env: set JWT_SECRET to a 64-byte hex (openssl rand -hex 64)

# 2. Boot Postgres + server
docker compose up -d postgres
# wait until pg_isready returns 0
docker compose ps

# 3. Run migrations (one time)
export DATABASE_URL=postgres://unii:$(grep POSTGRES_PASSWORD .env | cut -d= -f2)@localhost:5432/unii
cd unii-server && sqlx migrate run && cd ..

# 4. Bring up the API server
docker compose up -d unii-server
curl -sf http://localhost:8080/healthz   # → {"code":0,"msg":"ok","data":"healthy"}
```

Or run the server natively (faster iteration during development):

```bash
cd unii-server
cargo run
```

## Start the App

The Flutter project lives under `unii-app/`.

```bash
cd unii-app
flutter pub get

# iOS simulator (host networking is straight localhost)
flutter run --dart-define=API_BASE_URL=http://localhost:8080

# Android emulator (must use 10.0.2.2 to reach host)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Expected flow: launch → login screen → switch to register → submit → auto-login → 4-tab home (Discover / Team / Chat / Profile, each rendering a "Coming in W*" placeholder).

## Project Structure

```
flutter_rust_app/
├── plan.md                # full product/architecture spec
├── docker-compose.yml     # postgres + unii-server (caddy in W8)
├── .env.example           # template — copy to .env
├── Caddyfile              # reverse proxy placeholder (W8)
├── unii-server/           # Rust + Axum + sqlx backend
│   ├── src/
│   ├── migrations/
│   └── tests/
├── unii-app/              # Flutter + GetX client
│   └── lib/
└── .github/workflows/     # server-ci.yml + app-ci.yml
```

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `cargo run` fails: `connection refused` | Postgres not up yet | `docker compose ps`, wait for `healthy`, retry |
| `sqlx::query!` macro errors at compile time | offline metadata stale | run `cargo sqlx prepare` against a live DB or `export SQLX_OFFLINE=false` |
| `flutter run` on Android can't reach API | using `localhost` from emulator | use `--dart-define=API_BASE_URL=http://10.0.2.2:8080` |
| App immediately bounces back to login | refresh token expired or JWT_SECRET rotated | clear app storage; re-register |
| Port 5432 already in use | another local Postgres is running | stop it, or change the host port mapping in `docker-compose.yml` |
| `JWT_SECRET` warning at server boot | `.env` missing or value is the placeholder | generate via `openssl rand -hex 64` and update `.env` |

## Development

- Backend tests: `cd unii-server && cargo test` (needs `DATABASE_URL` for integration tests).
- App tests: `cd unii-app && flutter test`.
- Static checks: `cargo fmt --check && cargo clippy --all-targets -- -D warnings` and `flutter analyze`.

CI runs the same checks on every push. See `.github/workflows/`.
