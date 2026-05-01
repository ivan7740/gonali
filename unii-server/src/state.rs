use std::sync::Arc;

use sqlx::PgPool;

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
    pub jwt_secret: Arc<str>,
    pub access_ttl_secs: i64,
    pub refresh_ttl_secs: i64,
}
