use chrono::{DateTime, Utc};
use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, Clone, FromRow, Serialize)]
pub struct PostRow {
    pub id: i64,
    pub author_id: i64,
    pub team_id: Option<i64>,
    pub activity_id: Option<i64>,
    pub post_type: i16,
    pub title: Option<String>,
    pub content: Option<String>,
    pub visibility: String,
    pub like_count: i32,
    pub comment_count: i32,
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, FromRow, Serialize)]
pub struct PostCommentRow {
    pub id: i64,
    pub post_id: i64,
    pub user_id: i64,
    pub parent_id: Option<i64>,
    pub content: String,
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, FromRow, Serialize)]
pub struct MediaRow {
    pub id: i64,
    pub owner_type: String,
    pub owner_id: i64,
    pub media_type: String,
    pub url: String,
    pub thumbnail_url: Option<String>,
    pub duration: Option<i32>,
    pub size_bytes: Option<i64>,
    pub sort_order: Option<i16>,
    pub created_at: Option<DateTime<Utc>>,
}
