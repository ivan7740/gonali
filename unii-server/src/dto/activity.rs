use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use crate::model::activity::ActivityRow;

/// Coordinate pair — WGS84, `(lng, lat)` order matches plan.md §6.1.
#[derive(Debug, Clone, Copy, Deserialize, Serialize)]
pub struct LngLat {
    pub lng: f64,
    pub lat: f64,
}

impl LngLat {
    pub fn is_valid(&self) -> bool {
        (-180.0..=180.0).contains(&self.lng) && (-90.0..=90.0).contains(&self.lat)
    }
}

#[derive(Debug, Deserialize)]
pub struct CreateActivityReq {
    pub title: String,
    pub location: LngLat,
    pub location_name: Option<String>,
    pub start_time: Option<DateTime<Utc>>,
    pub end_time: Option<DateTime<Utc>>,
    pub content: Option<String>,
    pub notice: Option<String>,
    pub visibility: String,
}

#[derive(Debug, Default, Deserialize)]
pub struct UpdateActivityReq {
    pub title: Option<String>,
    pub location: Option<LngLat>,
    pub location_name: Option<String>,
    pub start_time: Option<DateTime<Utc>>,
    pub end_time: Option<DateTime<Utc>>,
    pub content: Option<String>,
    pub notice: Option<String>,
    pub visibility: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct ActivityView {
    pub id: i64,
    pub team_id: i64,
    pub creator_id: i64,
    pub title: String,
    pub location: LngLat,
    pub location_name: Option<String>,
    pub start_time: Option<DateTime<Utc>>,
    pub end_time: Option<DateTime<Utc>>,
    pub content: Option<String>,
    pub notice: Option<String>,
    pub visibility: String,
    pub created_at: Option<DateTime<Utc>>,
}

impl From<ActivityRow> for ActivityView {
    fn from(r: ActivityRow) -> Self {
        Self {
            id: r.id,
            team_id: r.team_id,
            creator_id: r.creator_id,
            title: r.title,
            location: LngLat {
                lng: r.lng,
                lat: r.lat,
            },
            location_name: r.location_name,
            start_time: r.start_time,
            end_time: r.end_time,
            content: r.content,
            notice: r.notice,
            visibility: r.visibility,
            created_at: r.created_at,
        }
    }
}
