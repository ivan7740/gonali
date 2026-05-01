use chrono::{DateTime, Utc};
use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, Clone, FromRow, Serialize)]
pub struct MomentRow {
    pub id: i64,
    pub team_id: i64,
    pub author_id: i64,
    pub content: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, FromRow, Serialize)]
pub struct MomentJoinRow {
    pub id: i64,
    pub team_id: i64,
    pub author_id: i64,
    pub author_username: String,
    pub author_nickname: Option<String>,
    pub author_avatar_url: Option<String>,
    pub content: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
}
