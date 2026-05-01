use sqlx::PgPool;

use crate::{
    dto::post::{CommentJoinRow, PostJoinRow},
    model::post::{MediaRow, PostCommentRow, PostRow},
};

const POST_COLS: &str = "id, author_id, team_id, activity_id, post_type, title, content,
        visibility, like_count, comment_count, created_at";

pub async fn insert_post(
    pool: &PgPool,
    author_id: i64,
    team_id: Option<i64>,
    title: Option<&str>,
    content: Option<&str>,
    visibility: &str,
) -> sqlx::Result<PostRow> {
    sqlx::query_as::<_, PostRow>(&format!(
        "INSERT INTO posts (author_id, team_id, post_type, title, content, visibility)
         VALUES ($1, $2, 0, $3, $4, $5)
         RETURNING {POST_COLS}"
    ))
    .bind(author_id)
    .bind(team_id)
    .bind(title)
    .bind(content)
    .bind(visibility)
    .fetch_one(pool)
    .await
}

pub async fn find_post(pool: &PgPool, id: i64) -> sqlx::Result<Option<PostRow>> {
    sqlx::query_as::<_, PostRow>(&format!("SELECT {POST_COLS} FROM posts WHERE id = $1"))
        .bind(id)
        .fetch_optional(pool)
        .await
}

/// Public feed: posts with visibility='public', most recent first, cursor-paginated
/// by `before_id`. Joined to users for author info.
pub async fn list_public_feed(
    pool: &PgPool,
    before_id: Option<i64>,
    limit: i32,
) -> sqlx::Result<Vec<PostJoinRow>> {
    sqlx::query_as::<_, PostJoinRow>(
        r#"SELECT p.id, p.author_id,
                  u.username AS author_username,
                  u.nickname AS author_nickname,
                  u.avatar_url AS author_avatar_url,
                  p.team_id, p.activity_id, p.post_type, p.title, p.content,
                  p.visibility, p.like_count, p.comment_count, p.created_at
           FROM posts p
           JOIN users u ON u.id = p.author_id
           WHERE p.visibility = 'public'
             AND ($1::BIGINT IS NULL OR p.id < $1)
           ORDER BY p.id DESC
           LIMIT $2"#,
    )
    .bind(before_id)
    .bind(limit as i64)
    .fetch_all(pool)
    .await
}

pub async fn find_post_join(pool: &PgPool, id: i64) -> sqlx::Result<Option<PostJoinRow>> {
    sqlx::query_as::<_, PostJoinRow>(
        r#"SELECT p.id, p.author_id,
                  u.username AS author_username,
                  u.nickname AS author_nickname,
                  u.avatar_url AS author_avatar_url,
                  p.team_id, p.activity_id, p.post_type, p.title, p.content,
                  p.visibility, p.like_count, p.comment_count, p.created_at
           FROM posts p
           JOIN users u ON u.id = p.author_id
           WHERE p.id = $1"#,
    )
    .bind(id)
    .fetch_optional(pool)
    .await
}

pub async fn media_for(
    pool: &PgPool,
    owner_type: &str,
    owner_id: i64,
) -> sqlx::Result<Vec<MediaRow>> {
    sqlx::query_as::<_, MediaRow>(
        "SELECT id, owner_type, owner_id, media_type, url, thumbnail_url,
                duration, size_bytes, sort_order, created_at
         FROM media_files
         WHERE owner_type = $1 AND owner_id = $2
         ORDER BY sort_order ASC, id ASC",
    )
    .bind(owner_type)
    .bind(owner_id)
    .fetch_all(pool)
    .await
}

pub async fn liked_by(pool: &PgPool, post_id: i64, user_id: i64) -> sqlx::Result<bool> {
    let row: Option<(i32,)> =
        sqlx::query_as("SELECT 1 FROM post_likes WHERE post_id = $1 AND user_id = $2")
            .bind(post_id)
            .bind(user_id)
            .fetch_optional(pool)
            .await?;
    Ok(row.is_some())
}

pub async fn liked_set(
    pool: &PgPool,
    post_ids: &[i64],
    user_id: i64,
) -> sqlx::Result<std::collections::HashSet<i64>> {
    if post_ids.is_empty() {
        return Ok(Default::default());
    }
    let rows: Vec<(i64,)> = sqlx::query_as(
        "SELECT post_id FROM post_likes
         WHERE user_id = $1 AND post_id = ANY($2::BIGINT[])",
    )
    .bind(user_id)
    .bind(post_ids)
    .fetch_all(pool)
    .await?;
    Ok(rows.into_iter().map(|(id,)| id).collect())
}

/// Toggle like; returns the new (liked, like_count) state.
pub async fn toggle_like(pool: &PgPool, post_id: i64, user_id: i64) -> sqlx::Result<(bool, i32)> {
    let mut tx = pool.begin().await?;
    let already: Option<(i32,)> =
        sqlx::query_as("SELECT 1 FROM post_likes WHERE post_id = $1 AND user_id = $2")
            .bind(post_id)
            .bind(user_id)
            .fetch_optional(&mut *tx)
            .await?;
    let liked = if already.is_some() {
        sqlx::query("DELETE FROM post_likes WHERE post_id = $1 AND user_id = $2")
            .bind(post_id)
            .bind(user_id)
            .execute(&mut *tx)
            .await?;
        sqlx::query("UPDATE posts SET like_count = GREATEST(like_count - 1, 0) WHERE id = $1")
            .bind(post_id)
            .execute(&mut *tx)
            .await?;
        false
    } else {
        sqlx::query("INSERT INTO post_likes (post_id, user_id) VALUES ($1, $2)")
            .bind(post_id)
            .bind(user_id)
            .execute(&mut *tx)
            .await?;
        sqlx::query("UPDATE posts SET like_count = like_count + 1 WHERE id = $1")
            .bind(post_id)
            .execute(&mut *tx)
            .await?;
        true
    };
    let count: (i32,) = sqlx::query_as("SELECT like_count FROM posts WHERE id = $1")
        .bind(post_id)
        .fetch_one(&mut *tx)
        .await?;
    tx.commit().await?;
    Ok((liked, count.0))
}

pub async fn insert_comment(
    pool: &PgPool,
    post_id: i64,
    user_id: i64,
    parent_id: Option<i64>,
    content: &str,
) -> sqlx::Result<PostCommentRow> {
    let mut tx = pool.begin().await?;
    let row = sqlx::query_as::<_, PostCommentRow>(
        "INSERT INTO post_comments (post_id, user_id, parent_id, content)
         VALUES ($1, $2, $3, $4)
         RETURNING id, post_id, user_id, parent_id, content, created_at",
    )
    .bind(post_id)
    .bind(user_id)
    .bind(parent_id)
    .bind(content)
    .fetch_one(&mut *tx)
    .await?;
    sqlx::query("UPDATE posts SET comment_count = comment_count + 1 WHERE id = $1")
        .bind(post_id)
        .execute(&mut *tx)
        .await?;
    tx.commit().await?;
    Ok(row)
}

pub async fn list_comments(pool: &PgPool, post_id: i64) -> sqlx::Result<Vec<CommentJoinRow>> {
    sqlx::query_as::<_, CommentJoinRow>(
        r#"SELECT c.id, c.post_id, c.user_id,
                  u.username, u.nickname, u.avatar_url,
                  c.parent_id, c.content, c.created_at
           FROM post_comments c
           JOIN users u ON u.id = c.user_id
           WHERE c.post_id = $1
           ORDER BY c.created_at ASC"#,
    )
    .bind(post_id)
    .fetch_all(pool)
    .await
}

/// Attach previously-uploaded media rows to a post (sets owner_type/owner_id).
/// Silently ignores IDs the caller doesn't own — caller already validated.
pub async fn attach_media_to_post(
    pool: &PgPool,
    post_id: i64,
    media_ids: &[i64],
) -> sqlx::Result<()> {
    if media_ids.is_empty() {
        return Ok(());
    }
    sqlx::query(
        "UPDATE media_files SET owner_type = 'post', owner_id = $1
         WHERE id = ANY($2::BIGINT[]) AND owner_type = 'pending'",
    )
    .bind(post_id)
    .bind(media_ids)
    .execute(pool)
    .await?;
    Ok(())
}
