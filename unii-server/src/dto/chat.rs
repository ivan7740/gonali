use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use crate::model::chat::{ChatMessageRow, ConversationListRow};

#[derive(Debug, Deserialize)]
pub struct SendMessageReq {
    /// `text` | `image`
    pub msg_type: String,
    pub content: Option<String>,
    pub media_url: Option<String>,
    pub duration: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct MessagesQuery {
    pub since_id: Option<i64>,
    /// When true, the server holds the request for up to 25s waiting for new
    /// messages (long-poll). Defaults to false (one-shot).
    #[serde(default)]
    pub wait: bool,
}

#[derive(Debug, Serialize)]
pub struct ConversationView {
    pub id: i64,
    pub other_user_id: i64,
    pub other_username: String,
    pub other_nickname: Option<String>,
    pub other_avatar_url: Option<String>,
    pub last_message_id: Option<i64>,
    pub last_message_preview: Option<String>,
    pub last_message_at: Option<DateTime<Utc>>,
    pub unread_count: i64,
    pub updated_at: Option<DateTime<Utc>>,
}

impl From<ConversationListRow> for ConversationView {
    fn from(r: ConversationListRow) -> Self {
        Self {
            id: r.id,
            other_user_id: r.other_user_id,
            other_username: r.other_username,
            other_nickname: r.other_nickname,
            other_avatar_url: r.other_avatar_url,
            last_message_id: r.last_message_id,
            last_message_preview: r.last_message_preview,
            last_message_at: r.last_message_at,
            unread_count: r.unread_count,
            updated_at: r.updated_at,
        }
    }
}

#[derive(Debug, Serialize)]
pub struct MessageView {
    pub id: i64,
    pub conversation_id: i64,
    pub sender_id: i64,
    pub msg_type: String,
    pub content: Option<String>,
    pub media_url: Option<String>,
    pub duration: Option<i32>,
    pub is_recalled: bool,
    pub created_at: Option<DateTime<Utc>>,
}

impl From<ChatMessageRow> for MessageView {
    fn from(r: ChatMessageRow) -> Self {
        Self {
            id: r.id,
            conversation_id: r.conversation_id,
            sender_id: r.sender_id,
            msg_type: r.msg_type,
            content: r.content,
            media_url: r.media_url,
            duration: r.duration,
            is_recalled: r.is_recalled,
            created_at: r.created_at,
        }
    }
}

#[derive(Debug, Serialize)]
pub struct StartConversationResp {
    pub id: i64,
    pub other_user_id: i64,
}

pub fn is_valid_msg_type(s: &str) -> bool {
    matches!(s, "text" | "image" | "audio" | "video")
}
