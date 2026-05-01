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

use axum::{middleware as axum_mw, routing::get, Router};
use sqlx::PgPool;

use crate::{config::Config, state::AppState};

/// Build the full application router with the given AppState.
///
/// Public so integration tests in `tests/` can construct a router against an
/// `#[sqlx::test]`-provided pool.
pub fn build_router(state: AppState) -> Router {
    let public = Router::new()
        .route("/healthz", get(routes::health::healthz))
        .nest("/api/v1/auth", routes::auth::public_routes());

    let protected = Router::new()
        .nest("/api/v1/users", routes::users::routes())
        .route_layer(axum_mw::from_fn_with_state(
            state.clone(),
            middleware::auth::auth_mw,
        ));

    public.merge(protected).with_state(state)
}

/// Build an AppState from a connected PgPool and configuration.
pub fn build_state(db: PgPool, config: Config) -> AppState {
    AppState {
        db,
        jwt_secret: Arc::<str>::from(config.jwt_secret),
        access_ttl_secs: config.access_ttl_secs,
        refresh_ttl_secs: config.refresh_ttl_secs,
    }
}
