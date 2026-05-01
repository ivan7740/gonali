use chrono::{DateTime, Utc};
use sqlx::PgPool;

use crate::model::moment::{MomentJoinRow, MomentRow};

pub async fn insert(
    pool: &PgPool,
    team_id: i64,
    author_id: i64,
    content: Option<&str>,
) -> sqlx::Result<MomentRow> {
    sqlx::query_as::<_, MomentRow>(
        "INSERT INTO moments (team_id, author_id, content)
         VALUES ($1, $2, $3)
         RETURNING id, team_id, author_id, content, created_at",
    )
    .bind(team_id)
    .bind(author_id)
    .bind(content)
    .fetch_one(pool)
    .await
}

pub async fn list_team(
    pool: &PgPool,
    team_id: i64,
    since: Option<DateTime<Utc>>,
) -> sqlx::Result<Vec<MomentJoinRow>> {
    sqlx::query_as::<_, MomentJoinRow>(
        r#"SELECT m.id, m.team_id, m.author_id,
                  u.username AS author_username,
                  u.nickname AS author_nickname,
                  u.avatar_url AS author_avatar_url,
                  m.content, m.created_at
           FROM moments m
           JOIN users u ON u.id = m.author_id
           WHERE m.team_id = $1
             AND ($2::TIMESTAMPTZ IS NULL OR m.created_at > $2)
           ORDER BY m.created_at DESC
           LIMIT 100"#,
    )
    .bind(team_id)
    .bind(since)
    .fetch_all(pool)
    .await
}

/// Used by W4 heartbeat to surface unread moment counts; W6 ships the real
/// implementation. Counts moments newer than the user's last view of the
/// team's moments — for now we approximate with team_members.joined_at.
pub async fn unread_count_for_member(
    pool: &PgPool,
    team_id: i64,
    user_id: i64,
) -> sqlx::Result<i64> {
    let row: (i64,) = sqlx::query_as(
        r#"SELECT COUNT(*)::BIGINT
           FROM moments m
           WHERE m.team_id = $1
             AND m.author_id <> $2
             AND m.created_at > COALESCE(
                 (SELECT joined_at FROM team_members
                  WHERE team_id = $1 AND user_id = $2),
                 m.created_at
             )"#,
    )
    .bind(team_id)
    .bind(user_id)
    .fetch_one(pool)
    .await?;
    Ok(row.0)
}
