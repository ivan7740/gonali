use sqlx::PgPool;

use crate::model::chat::{ChatConversationRow, ChatMessageRow, ConversationListRow};

/// Resolve or create the canonical conversation between two users.
/// `user_a_id < user_b_id` is enforced by the schema.
pub async fn get_or_create(
    pool: &PgPool,
    me: i64,
    other: i64,
) -> sqlx::Result<ChatConversationRow> {
    if me == other {
        return Err(sqlx::Error::RowNotFound);
    }
    let (a, b) = if me < other { (me, other) } else { (other, me) };
    sqlx::query_as::<_, ChatConversationRow>(
        r#"WITH inserted AS (
               INSERT INTO chat_conversations (user_a_id, user_b_id)
               VALUES ($1, $2)
               ON CONFLICT (user_a_id, user_b_id) DO NOTHING
               RETURNING id, user_a_id, user_b_id, last_message_id, updated_at
           )
           SELECT * FROM inserted
           UNION ALL
           SELECT id, user_a_id, user_b_id, last_message_id, updated_at
           FROM chat_conversations
           WHERE user_a_id = $1 AND user_b_id = $2
           LIMIT 1"#,
    )
    .bind(a)
    .bind(b)
    .fetch_one(pool)
    .await
}

pub async fn find_conversation(
    pool: &PgPool,
    id: i64,
) -> sqlx::Result<Option<ChatConversationRow>> {
    sqlx::query_as::<_, ChatConversationRow>(
        "SELECT id, user_a_id, user_b_id, last_message_id, updated_at
         FROM chat_conversations WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(pool)
    .await
}

pub fn is_participant(conv: &ChatConversationRow, user_id: i64) -> bool {
    conv.user_a_id == user_id || conv.user_b_id == user_id
}

pub async fn list_for_user(pool: &PgPool, user_id: i64) -> sqlx::Result<Vec<ConversationListRow>> {
    sqlx::query_as::<_, ConversationListRow>(
        r#"SELECT c.id,
                  CASE WHEN c.user_a_id = $1 THEN c.user_b_id ELSE c.user_a_id END
                      AS other_user_id,
                  u.username AS other_username,
                  u.nickname AS other_nickname,
                  u.avatar_url AS other_avatar_url,
                  c.last_message_id,
                  CASE
                      WHEN m.is_recalled THEN ''
                      WHEN m.msg_type = 'text' THEN m.content
                      ELSE '[' || m.msg_type || ']'
                  END AS last_message_preview,
                  m.created_at AS last_message_at,
                  COALESCE(
                      (SELECT COUNT(*) FROM chat_messages mm
                       WHERE mm.conversation_id = c.id
                         AND mm.sender_id <> $1
                         AND mm.id > COALESCE(
                             (SELECT last_read_msg_id FROM chat_read_marks
                              WHERE conversation_id = c.id AND user_id = $1),
                             0
                         )
                      ),
                      0
                  ) AS unread_count,
                  c.updated_at
           FROM chat_conversations c
           JOIN users u ON u.id = (
               CASE WHEN c.user_a_id = $1 THEN c.user_b_id ELSE c.user_a_id END
           )
           LEFT JOIN chat_messages m ON m.id = c.last_message_id
           WHERE c.user_a_id = $1 OR c.user_b_id = $1
           ORDER BY COALESCE(m.created_at, c.updated_at) DESC NULLS LAST"#,
    )
    .bind(user_id)
    .fetch_all(pool)
    .await
}

pub async fn insert_message(
    pool: &PgPool,
    conversation_id: i64,
    sender_id: i64,
    msg_type: &str,
    content: Option<&str>,
    media_url: Option<&str>,
    duration: Option<i32>,
) -> sqlx::Result<ChatMessageRow> {
    let mut tx = pool.begin().await?;
    let row = sqlx::query_as::<_, ChatMessageRow>(
        "INSERT INTO chat_messages
           (conversation_id, sender_id, msg_type, content, media_url, duration)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING id, conversation_id, sender_id, msg_type, content, media_url,
                   duration, is_recalled, created_at",
    )
    .bind(conversation_id)
    .bind(sender_id)
    .bind(msg_type)
    .bind(content)
    .bind(media_url)
    .bind(duration)
    .fetch_one(&mut *tx)
    .await?;
    sqlx::query(
        "UPDATE chat_conversations
         SET last_message_id = $1, updated_at = NOW()
         WHERE id = $2",
    )
    .bind(row.id)
    .bind(conversation_id)
    .execute(&mut *tx)
    .await?;
    tx.commit().await?;
    Ok(row)
}

pub async fn list_messages_after(
    pool: &PgPool,
    conversation_id: i64,
    since_id: Option<i64>,
    limit: i64,
) -> sqlx::Result<Vec<ChatMessageRow>> {
    sqlx::query_as::<_, ChatMessageRow>(
        "SELECT id, conversation_id, sender_id, msg_type, content, media_url,
                duration, is_recalled, created_at
         FROM chat_messages
         WHERE conversation_id = $1
           AND ($2::BIGINT IS NULL OR id > $2)
         ORDER BY id ASC
         LIMIT $3",
    )
    .bind(conversation_id)
    .bind(since_id)
    .bind(limit)
    .fetch_all(pool)
    .await
}

pub async fn find_message(pool: &PgPool, id: i64) -> sqlx::Result<Option<ChatMessageRow>> {
    sqlx::query_as::<_, ChatMessageRow>(
        "SELECT id, conversation_id, sender_id, msg_type, content, media_url,
                duration, is_recalled, created_at
         FROM chat_messages WHERE id = $1",
    )
    .bind(id)
    .fetch_optional(pool)
    .await
}

pub async fn mark_recalled(pool: &PgPool, id: i64) -> sqlx::Result<u64> {
    let res = sqlx::query("UPDATE chat_messages SET is_recalled = TRUE WHERE id = $1")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(res.rows_affected())
}

pub async fn mark_read(
    pool: &PgPool,
    conversation_id: i64,
    user_id: i64,
    last_read_msg_id: i64,
) -> sqlx::Result<()> {
    sqlx::query(
        "INSERT INTO chat_read_marks (conversation_id, user_id, last_read_msg_id)
         VALUES ($1, $2, $3)
         ON CONFLICT (conversation_id, user_id) DO UPDATE
           SET last_read_msg_id = GREATEST(chat_read_marks.last_read_msg_id, $3)",
    )
    .bind(conversation_id)
    .bind(user_id)
    .bind(last_read_msg_id)
    .execute(pool)
    .await?;
    Ok(())
}
