use sqlx::PgPool;

use crate::model::post::MediaRow;

/// Insert an uploaded media row in `pending` state — caller must later
/// re-bind it to a real owner via `post_repo::attach_media_to_post` (or
/// equivalent for other owner types).
pub async fn insert_pending(
    pool: &PgPool,
    uploader_id: i64,
    media_type: &str,
    url: &str,
    size_bytes: Option<i64>,
) -> sqlx::Result<MediaRow> {
    sqlx::query_as::<_, MediaRow>(
        "INSERT INTO media_files (owner_type, owner_id, media_type, url, size_bytes)
         VALUES ('pending', $1, $2, $3, $4)
         RETURNING id, owner_type, owner_id, media_type, url, thumbnail_url,
                   duration, size_bytes, sort_order, created_at",
    )
    .bind(uploader_id)
    .bind(media_type)
    .bind(url)
    .bind(size_bytes)
    .fetch_one(pool)
    .await
}
