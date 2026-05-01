use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use crate::model::post::{MediaRow, PostRow};

#[derive(Debug, Deserialize)]
pub struct CreatePostReq {
    pub title: Option<String>,
    pub content: Option<String>,
    /// `public` | `private` (W5 only `public` is meaningful in feed; private posts
    /// are visible to author only).
    pub visibility: String,
    pub team_id: Option<i64>,
    /// IDs of `media_files` rows previously uploaded via `/media/upload`.
    /// Server attaches them by setting `owner_type='post'` + `owner_id=<post.id>`.
    #[serde(default)]
    pub media_ids: Vec<i64>,
}

#[derive(Debug, Deserialize)]
pub struct CreateCommentReq {
    pub content: String,
    pub parent_id: Option<i64>,
}

#[derive(Debug, Deserialize)]
pub struct FeedQuery {
    pub before_id: Option<i64>,
    pub limit: Option<i32>,
}

#[derive(Debug, Serialize)]
pub struct PostView {
    pub id: i64,
    pub author_id: i64,
    pub author_username: String,
    pub author_nickname: Option<String>,
    pub author_avatar_url: Option<String>,
    pub team_id: Option<i64>,
    pub activity_id: Option<i64>,
    pub post_type: i16,
    pub title: Option<String>,
    pub content: Option<String>,
    pub visibility: String,
    pub like_count: i32,
    pub comment_count: i32,
    pub created_at: Option<DateTime<Utc>>,
    pub media: Vec<MediaView>,
    pub liked_by_me: bool,
}

#[derive(Debug, Serialize)]
pub struct MediaView {
    pub id: i64,
    pub media_type: String,
    pub url: String,
    pub thumbnail_url: Option<String>,
    pub duration: Option<i32>,
    pub sort_order: i16,
}

impl From<&MediaRow> for MediaView {
    fn from(r: &MediaRow) -> Self {
        Self {
            id: r.id,
            media_type: r.media_type.clone(),
            url: r.url.clone(),
            thumbnail_url: r.thumbnail_url.clone(),
            duration: r.duration,
            sort_order: r.sort_order.unwrap_or(0),
        }
    }
}

#[derive(Debug, Serialize)]
pub struct CommentView {
    pub id: i64,
    pub post_id: i64,
    pub user_id: i64,
    pub username: String,
    pub nickname: Option<String>,
    pub avatar_url: Option<String>,
    pub parent_id: Option<i64>,
    pub content: String,
    pub created_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize)]
pub struct LikeToggleResp {
    pub liked: bool,
    pub like_count: i32,
}

/// Joined row for repo-level comment listing.
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct CommentJoinRow {
    pub id: i64,
    pub post_id: i64,
    pub user_id: i64,
    pub username: String,
    pub nickname: Option<String>,
    pub avatar_url: Option<String>,
    pub parent_id: Option<i64>,
    pub content: String,
    pub created_at: Option<DateTime<Utc>>,
}

impl From<CommentJoinRow> for CommentView {
    fn from(r: CommentJoinRow) -> Self {
        Self {
            id: r.id,
            post_id: r.post_id,
            user_id: r.user_id,
            username: r.username,
            nickname: r.nickname,
            avatar_url: r.avatar_url,
            parent_id: r.parent_id,
            content: r.content,
            created_at: r.created_at,
        }
    }
}

/// Joined row for repo-level feed listing.
#[derive(Debug, Clone, sqlx::FromRow)]
pub struct PostJoinRow {
    pub id: i64,
    pub author_id: i64,
    pub author_username: String,
    pub author_nickname: Option<String>,
    pub author_avatar_url: Option<String>,
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

pub fn build_post_view(row: PostJoinRow, media: Vec<MediaView>, liked_by_me: bool) -> PostView {
    PostView {
        id: row.id,
        author_id: row.author_id,
        author_username: row.author_username,
        author_nickname: row.author_nickname,
        author_avatar_url: row.author_avatar_url,
        team_id: row.team_id,
        activity_id: row.activity_id,
        post_type: row.post_type,
        title: row.title,
        content: row.content,
        visibility: row.visibility,
        like_count: row.like_count,
        comment_count: row.comment_count,
        created_at: row.created_at,
        media,
        liked_by_me,
    }
}

pub fn build_post_view_from_row(
    row: &PostRow,
    author_username: String,
    author_nickname: Option<String>,
    author_avatar_url: Option<String>,
    media: Vec<MediaView>,
    liked_by_me: bool,
) -> PostView {
    PostView {
        id: row.id,
        author_id: row.author_id,
        author_username,
        author_nickname,
        author_avatar_url,
        team_id: row.team_id,
        activity_id: row.activity_id,
        post_type: row.post_type,
        title: row.title.clone(),
        content: row.content.clone(),
        visibility: row.visibility.clone(),
        like_count: row.like_count,
        comment_count: row.comment_count,
        created_at: row.created_at,
        media,
        liked_by_me,
    }
}
