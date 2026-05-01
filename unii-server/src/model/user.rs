use chrono::{DateTime, Utc};
use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, Clone, FromRow, Serialize)]
pub struct UserRow {
    pub id: i64,
    pub phone: String,
    pub password_hash: String,
    pub username: String,
    pub nickname: Option<String>,
    pub avatar_url: Option<String>,
    pub email: Option<String>,
    pub city: Option<String>,
    pub occupation: Option<String>,
    pub gender: Option<i16>,
    pub birthday: Option<chrono::NaiveDate>,
    pub theme: Option<String>,
    pub language: Option<String>,
    pub map_engine: Option<String>,
    pub location_share_enabled: Option<bool>,
    pub created_at: Option<DateTime<Utc>>,
    pub updated_at: Option<DateTime<Utc>>,
}

impl UserRow {
    pub fn needs_map_setup(&self) -> bool {
        self.map_engine.as_deref().unwrap_or("").is_empty()
    }
}
