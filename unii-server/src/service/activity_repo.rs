use chrono::{DateTime, Utc};
use sqlx::PgPool;

use crate::{
    dto::activity::{CreateActivityReq, UpdateActivityReq},
    model::activity::ActivityRow,
};

const SELECT_COLS: &str = "id, team_id, creator_id, title,
                ST_X(location::geometry) AS lng,
                ST_Y(location::geometry) AS lat,
                location_name, start_time, end_time, content, notice, visibility, created_at";

pub async fn insert(
    pool: &PgPool,
    team_id: i64,
    creator_id: i64,
    req: &CreateActivityReq,
) -> sqlx::Result<ActivityRow> {
    sqlx::query_as::<_, ActivityRow>(&format!(
        "WITH inserted AS (
             INSERT INTO activities (
                 team_id, creator_id, title, location, location_name,
                 start_time, end_time, content, notice, visibility
             ) VALUES (
                 $1, $2, $3,
                 ST_SetSRID(ST_MakePoint($4, $5), 4326)::geography,
                 $6, $7, $8, $9, $10, $11
             )
             RETURNING *
         )
         SELECT {SELECT_COLS} FROM inserted"
    ))
    .bind(team_id)
    .bind(creator_id)
    .bind(&req.title)
    .bind(req.location.lng)
    .bind(req.location.lat)
    .bind(req.location_name.as_deref())
    .bind(req.start_time)
    .bind(req.end_time)
    .bind(req.content.as_deref())
    .bind(req.notice.as_deref())
    .bind(&req.visibility)
    .fetch_one(pool)
    .await
}

pub async fn find_by_id(pool: &PgPool, id: i64) -> sqlx::Result<Option<ActivityRow>> {
    sqlx::query_as::<_, ActivityRow>(&format!(
        "SELECT {SELECT_COLS} FROM activities WHERE id = $1"
    ))
    .bind(id)
    .fetch_optional(pool)
    .await
}

pub async fn list_by_team(pool: &PgPool, team_id: i64) -> sqlx::Result<Vec<ActivityRow>> {
    sqlx::query_as::<_, ActivityRow>(&format!(
        "SELECT {SELECT_COLS} FROM activities WHERE team_id = $1 ORDER BY created_at DESC"
    ))
    .bind(team_id)
    .fetch_all(pool)
    .await
}

pub async fn update(pool: &PgPool, id: i64, req: &UpdateActivityReq) -> sqlx::Result<ActivityRow> {
    let (lng, lat) = match req.location {
        Some(p) => (Some(p.lng), Some(p.lat)),
        None => (None, None),
    };
    sqlx::query_as::<_, ActivityRow>(&format!(
        "WITH updated AS (
             UPDATE activities SET
                title         = COALESCE($2, title),
                location      = CASE
                    WHEN $3::DOUBLE PRECISION IS NOT NULL AND $4::DOUBLE PRECISION IS NOT NULL
                    THEN ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography
                    ELSE location
                END,
                location_name = COALESCE($5, location_name),
                start_time    = COALESCE($6, start_time),
                end_time      = COALESCE($7, end_time),
                content       = COALESCE($8, content),
                notice        = COALESCE($9, notice),
                visibility    = COALESCE($10, visibility)
             WHERE id = $1
             RETURNING *
         )
         SELECT {SELECT_COLS} FROM updated"
    ))
    .bind(id)
    .bind(req.title.as_deref())
    .bind::<Option<f64>>(lng)
    .bind::<Option<f64>>(lat)
    .bind(req.location_name.as_deref())
    .bind::<Option<DateTime<Utc>>>(req.start_time)
    .bind::<Option<DateTime<Utc>>>(req.end_time)
    .bind(req.content.as_deref())
    .bind(req.notice.as_deref())
    .bind(req.visibility.as_deref())
    .fetch_one(pool)
    .await
}

pub async fn delete(pool: &PgPool, id: i64) -> sqlx::Result<u64> {
    let res = sqlx::query("DELETE FROM activities WHERE id = $1")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(res.rows_affected())
}
