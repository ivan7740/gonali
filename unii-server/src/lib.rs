pub mod config;
pub mod dto;
pub mod error;
pub mod middleware;
pub mod model;
pub mod routes;
pub mod service;
pub mod state;
pub mod util;

use std::sync::Arc;

use axum::{extract::DefaultBodyLimit, middleware as axum_mw, routing::get, Router};
use sqlx::PgPool;
use tower_http::services::ServeDir;

use crate::{config::Config, state::AppState};

/// Hard cap on request body size. Avatars are <5 MiB; W5 media uploads
/// stay below 10 MiB images per plan §9 (video lands in W6).
const MAX_BODY_BYTES: usize = 10 * 1024 * 1024;

/// Build the full application router with the given AppState.
///
/// Public so integration tests in `tests/` can construct a router against an
/// `#[sqlx::test]`-provided pool.
pub fn build_router(state: AppState) -> Router {
    let public = Router::new()
        .route("/healthz", get(routes::health::healthz))
        .nest("/api/v1/auth", routes::auth::public_routes());

    let teams_router =
        routes::teams::routes().nest("/:id/activities", routes::activities::team_scoped());

    let protected = Router::new()
        .nest("/api/v1/users", routes::users::routes())
        .nest("/api/v1/teams", teams_router)
        .nest("/api/v1/activities", routes::activities::standalone())
        .nest("/api/v1/locations", routes::locations::routes())
        .nest("/api/v1/posts", routes::posts::routes())
        .nest("/api/v1/media", routes::media::routes())
        .route_layer(axum_mw::from_fn_with_state(
            state.clone(),
            middleware::auth::auth_mw,
        ));

    let uploads = Router::new().nest_service("/uploads", ServeDir::new(state.upload_dir.as_ref()));

    public
        .merge(protected)
        .merge(uploads)
        .layer(DefaultBodyLimit::max(MAX_BODY_BYTES))
        .with_state(state)
}

/// Build an AppState from a connected PgPool and configuration.
pub fn build_state(db: PgPool, config: Config) -> AppState {
    // Best-effort: ensure the upload dir exists. Failing here is non-fatal because the
    // app may run with avatar upload disabled in some deployments — the route itself
    // will surface a clearer error if writes fail.
    let _ = std::fs::create_dir_all(&config.upload_dir);

    AppState {
        db,
        jwt_secret: Arc::<str>::from(config.jwt_secret),
        access_ttl_secs: config.access_ttl_secs,
        refresh_ttl_secs: config.refresh_ttl_secs,
        upload_dir: Arc::new(config.upload_dir),
        public_base_url: Arc::<str>::from(config.public_base_url),
    }
}
