use chrono::{DateTime, Utc};
use serde::Serialize;

/// Decomposed activity row.
///
/// We don't use FromRow because PostGIS GEOGRAPHY needs explicit `ST_X`/`ST_Y`
/// projection to be readable as floats — repos build this struct manually from
/// `query_as` against a SELECT that already extracts lng/lat.
#[derive(Debug, Clone, Serialize, sqlx::FromRow)]
pub struct ActivityRow {
    pub id: i64,
    pub team_id: i64,
    pub creator_id: i64,
    pub title: String,
    pub lng: f64,
    pub lat: f64,
    pub location_name: Option<String>,
    pub start_time: Option<DateTime<Utc>>,
    pub end_time: Option<DateTime<Utc>>,
    pub content: Option<String>,
    pub notice: Option<String>,
    pub visibility: String,
    pub created_at: Option<DateTime<Utc>>,
}
