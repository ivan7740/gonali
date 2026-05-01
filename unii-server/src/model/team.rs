use chrono::{DateTime, Utc};
use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, Clone, FromRow, Serialize)]
pub struct TeamRow {
    pub id: i64,
    pub name: String,
    pub avatar_url: Option<String>,
    pub description: Option<String>,
    pub invite_code: String,
    pub owner_id: i64,
    pub member_limit: i32,
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, FromRow, Serialize)]
pub struct TeamMemberRow {
    pub team_id: i64,
    pub user_id: i64,
    pub role: i16,
    pub joined_at: Option<DateTime<Utc>>,
}

/// Joined view of `team_members` + `users` for member listing.
#[derive(Debug, Clone, FromRow, Serialize)]
pub struct TeamMemberWithUser {
    pub user_id: i64,
    pub role: i16,
    pub joined_at: Option<DateTime<Utc>>,
    pub username: String,
    pub nickname: Option<String>,
    pub avatar_url: Option<String>,
}
