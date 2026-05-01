use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use crate::dto::activity::LngLat;

#[derive(Debug, Deserialize)]
pub struct ReportLocationReq {
    pub lng: f64,
    pub lat: f64,
    pub accuracy: Option<f32>,
    pub speed: Option<f32>,
    pub bearing: Option<f32>,
}

impl ReportLocationReq {
    pub fn is_valid(&self) -> bool {
        (-180.0..=180.0).contains(&self.lng) && (-90.0..=90.0).contains(&self.lat)
    }
}

#[derive(Debug, Serialize)]
pub struct MemberLocationView {
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

#[derive(Debug, Serialize)]
pub struct DistanceResp {
    pub meters: f64,
}

#[derive(Debug, Deserialize)]
pub struct DistanceQuery {
    /// "lng,lat"
    pub from: String,
    pub to: String,
}

#[derive(Debug, Deserialize)]
pub struct RouteQuery {
    pub from: String,
    pub to: String,
    /// `driving` | `walking` | `bicycling`
    #[serde(default = "default_mode")]
    pub mode: String,
    /// `amap` | `osm`
    #[serde(default = "default_engine")]
    pub engine: String,
}

fn default_mode() -> String {
    "driving".into()
}

fn default_engine() -> String {
    "osm".into()
}

#[derive(Debug, Serialize)]
pub struct RouteResp {
    pub distance_m: f64,
    pub duration_s: i64,
    /// WGS84 polyline.
    pub polyline: Vec<LngLat>,
    /// "amap" | "osm" | "fallback"
    pub source: String,
}

#[derive(Debug, Serialize)]
pub struct HeartbeatResp {
    pub members: Vec<MemberLocationView>,
    /// Activities created/edited/deleted since `since`. W4 returns activities created
    /// after `since`; finer change tracking arrives with the moments work in W6.
    pub activity_changes: Vec<crate::dto::activity::ActivityView>,
    /// Unread moments count — always 0 in W4 (moments ship in W6).
    pub moment_unread: i64,
    pub server_time: DateTime<Utc>,
}

#[derive(Debug, Deserialize)]
pub struct HeartbeatQuery {
    pub since: Option<DateTime<Utc>>,
}

pub fn parse_lng_lat(s: &str) -> Option<(f64, f64)> {
    let mut parts = s.split(',');
    let lng = parts.next()?.trim().parse::<f64>().ok()?;
    let lat = parts.next()?.trim().parse::<f64>().ok()?;
    if !(-180.0..=180.0).contains(&lng) || !(-90.0..=90.0).contains(&lat) {
        return None;
    }
    Some((lng, lat))
}
