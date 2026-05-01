use chrono::{DateTime, Utc};
use sqlx::{FromRow, PgPool};

#[derive(Debug, Clone, FromRow)]
pub struct UserLocationRow {
    pub user_id: i64,
    pub lng: f64,
    pub lat: f64,
    pub accuracy: Option<f32>,
    pub speed: Option<f32>,
    pub bearing: Option<f32>,
    pub updated_at: DateTime<Utc>,
}

#[derive(Debug, Clone, FromRow)]
pub struct MemberLocationJoin {
    pub user_id: i64,
    pub username: String,
    pub nickname: Option<String>,
    pub avatar_url: Option<String>,
    pub lng: f64,
    pub lat: f64,
    pub accuracy: Option<f32>,
    pub speed: Option<f32>,
    pub bearing: Option<f32>,
    pub updated_at: DateTime<Utc>,
}

pub async fn upsert(
    pool: &PgPool,
    user_id: i64,
    lng: f64,
    lat: f64,
    accuracy: Option<f32>,
    speed: Option<f32>,
    bearing: Option<f32>,
) -> sqlx::Result<UserLocationRow> {
    sqlx::query_as::<_, UserLocationRow>(
        r#"INSERT INTO user_locations (user_id, location, accuracy, speed, bearing, updated_at)
           VALUES ($1, ST_SetSRID(ST_MakePoint($2, $3), 4326)::geography, $4, $5, $6, NOW())
           ON CONFLICT (user_id) DO UPDATE
             SET location   = EXCLUDED.location,
                 accuracy   = EXCLUDED.accuracy,
                 speed      = EXCLUDED.speed,
                 bearing    = EXCLUDED.bearing,
                 updated_at = NOW()
           RETURNING user_id,
                     ST_X(location::geometry) AS lng,
                     ST_Y(location::geometry) AS lat,
                     accuracy, speed, bearing, updated_at"#,
    )
    .bind(user_id)
    .bind(lng)
    .bind(lat)
    .bind(accuracy)
    .bind(speed)
    .bind(bearing)
    .fetch_one(pool)
    .await
}

/// Fetch the most recent location for every member of `team_id` whose
/// `users.location_share_enabled` is non-FALSE (NULL is treated as TRUE — the
/// migration default).
pub async fn team_member_locations(
    pool: &PgPool,
    team_id: i64,
) -> sqlx::Result<Vec<MemberLocationJoin>> {
    sqlx::query_as::<_, MemberLocationJoin>(
        r#"SELECT u.id AS user_id,
                  u.username,
                  u.nickname,
                  u.avatar_url,
                  ST_X(l.location::geometry) AS lng,
                  ST_Y(l.location::geometry) AS lat,
                  l.accuracy,
                  l.speed,
                  l.bearing,
                  l.updated_at
           FROM user_locations l
           JOIN team_members m ON m.user_id = l.user_id
           JOIN users u        ON u.id = l.user_id
           WHERE m.team_id = $1
             AND COALESCE(u.location_share_enabled, TRUE) = TRUE
           ORDER BY l.updated_at DESC"#,
    )
    .bind(team_id)
    .fetch_all(pool)
    .await
}

/// Straight-line geographic distance in meters using PostGIS `ST_Distance`
/// on `geography` columns. No DB row needed — purely computational.
pub async fn straight_line_distance(
    pool: &PgPool,
    from: (f64, f64),
    to: (f64, f64),
) -> sqlx::Result<f64> {
    let row: (f64,) = sqlx::query_as(
        "SELECT ST_Distance(
                  ST_SetSRID(ST_MakePoint($1, $2), 4326)::geography,
                  ST_SetSRID(ST_MakePoint($3, $4), 4326)::geography
               )",
    )
    .bind(from.0)
    .bind(from.1)
    .bind(to.0)
    .bind(to.1)
    .fetch_one(pool)
    .await?;
    Ok(row.0)
}
