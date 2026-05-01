use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use crate::{dto::post::MediaView, model::moment::MomentJoinRow};

#[derive(Debug, Deserialize)]
pub struct CreateMomentReq {
    pub content: Option<String>,
    #[serde(default)]
    pub media_ids: Vec<i64>,
}

#[derive(Debug, Deserialize)]
pub struct MomentsQuery {
    pub since: Option<DateTime<Utc>>,
}

#[derive(Debug, Serialize)]
pub struct MomentView {
    pub id: i64,
    pub team_id: i64,
    pub author_id: i64,
    pub author_username: String,
    pub author_nickname: Option<String>,
    pub author_avatar_url: Option<String>,
    pub content: Option<String>,
    pub created_at: Option<DateTime<Utc>>,
    pub media: Vec<MediaView>,
}

pub fn build_moment_view(row: MomentJoinRow, media: Vec<MediaView>) -> MomentView {
    MomentView {
        id: row.id,
        team_id: row.team_id,
        author_id: row.author_id,
        author_username: row.author_username,
        author_nickname: row.author_nickname,
        author_avatar_url: row.author_avatar_url,
        content: row.content,
        created_at: row.created_at,
        media,
    }
}
