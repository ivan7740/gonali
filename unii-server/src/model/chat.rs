use chrono::{DateTime, Utc};
use serde::Serialize;
use sqlx::FromRow;

#[derive(Debug, Clone, FromRow, Serialize)]
pub struct ChatConversationRow {
    pub id: i64,
    pub user_a_id: i64,
    pub user_b_id: i64,
    pub last_message_id: Option<i64>,
    pub updated_at: Option<DateTime<Utc>>,
}

#[derive(Debug, Clone, FromRow, Serialize)]
pub struct ChatMessageRow {
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

/// Joined view for /chats/conversations: who's the other user, last message preview.
#[derive(Debug, Clone, FromRow, Serialize)]
pub struct ConversationListRow {
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
