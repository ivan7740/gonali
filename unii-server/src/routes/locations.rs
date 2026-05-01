use axum::{
    extract::{Query, State},
    routing::{get, post},
    Extension, Json, Router,
};
use tracing::{info, instrument};

use crate::{
    dto::{
        activity::LngLat,
        common::ApiResp,
        location::{
            parse_lng_lat, DistanceQuery, DistanceResp, MemberLocationView, ReportLocationReq,
            RouteQuery, RouteResp,
        },
    },
    error::{AppError, AppResult},
    service::location_repo,
    state::AppState,
    util::{coord, jwt::Claims},
};

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/report", post(report))
        .route("/distance", get(distance))
        .route("/route", get(route))
}

#[instrument(skip(state, body))]
async fn report(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<ReportLocationReq>,
) -> AppResult<Json<ApiResp<MemberLocationView>>> {
    if !body.is_valid() {
        return Err(AppError::validation("invalid lng/lat"));
    }
    // Look up the reporter so we can echo their public profile fields back.
    let user = crate::service::user_repo::find_by_id(&state.db, claims.sub)
        .await?
        .ok_or_else(|| AppError::NotFound("user".into()))?;

    let row = location_repo::upsert(
        &state.db,
        claims.sub,
        body.lng,
        body.lat,
        body.accuracy,
        body.speed,
        body.bearing,
    )
    .await?;

    info!(user_id = claims.sub, "location reported");
    Ok(ApiResp::ok(MemberLocationView {
        user_id: row.user_id,
        username: user.username,
        nickname: user.nickname,
        avatar_url: user.avatar_url,
        lng: row.lng,
        lat: row.lat,
        accuracy: row.accuracy,
        speed: row.speed,
        bearing: row.bearing,
        updated_at: row.updated_at,
    }))
}

#[instrument(skip(state))]
async fn distance(
    State(state): State<AppState>,
    Extension(_claims): Extension<Claims>,
    Query(q): Query<DistanceQuery>,
) -> AppResult<Json<ApiResp<DistanceResp>>> {
    let from = parse_lng_lat(&q.from).ok_or_else(|| AppError::validation("invalid `from`"))?;
    let to = parse_lng_lat(&q.to).ok_or_else(|| AppError::validation("invalid `to`"))?;
    let meters = location_repo::straight_line_distance(&state.db, from, to).await?;
    Ok(ApiResp::ok(DistanceResp { meters }))
}

#[instrument(skip(state))]
async fn route(
    State(state): State<AppState>,
    Extension(_claims): Extension<Claims>,
    Query(q): Query<RouteQuery>,
) -> AppResult<Json<ApiResp<RouteResp>>> {
    let from = parse_lng_lat(&q.from).ok_or_else(|| AppError::validation("invalid `from`"))?;
    let to = parse_lng_lat(&q.to).ok_or_else(|| AppError::validation("invalid `to`"))?;
    if !matches!(q.mode.as_str(), "driving" | "walking" | "bicycling") {
        return Err(AppError::validation(
            "mode must be driving/walking/bicycling",
        ));
    }
    if !matches!(q.engine.as_str(), "amap" | "osm") {
        return Err(AppError::validation("engine must be amap/osm"));
    }

    // Fall back to a straight-line response when the configured upstream
    // isn't available (no AMap key set, OSRM unreachable, etc). This keeps
    // the contract stable for the client during W4 development.
    let meters = location_repo::straight_line_distance(&state.db, from, to).await?;
    let fallback = RouteResp {
        distance_m: meters,
        duration_s: estimate_duration(meters, &q.mode),
        polyline: vec![
            LngLat {
                lng: from.0,
                lat: from.1,
            },
            LngLat {
                lng: to.0,
                lat: to.1,
            },
        ],
        source: "fallback".into(),
    };

    if q.engine == "amap" {
        let key = std::env::var("AMAP_WEB_KEY").unwrap_or_default();
        if key.is_empty() {
            return Ok(ApiResp::ok(fallback));
        }
        match call_amap_route(&key, from, to, &q.mode).await {
            Ok(r) => Ok(ApiResp::ok(r)),
            Err(e) => {
                tracing::warn!(error = %e, "amap route failed; using fallback");
                Ok(ApiResp::ok(fallback))
            }
        }
    } else {
        let base = std::env::var("OSRM_BASE_URL")
            .unwrap_or_else(|_| "https://router.project-osrm.org".into());
        match call_osrm_route(&base, from, to, &q.mode).await {
            Ok(r) => Ok(ApiResp::ok(r)),
            Err(e) => {
                tracing::warn!(error = %e, "osrm route failed; using fallback");
                Ok(ApiResp::ok(fallback))
            }
        }
    }
}

fn estimate_duration(meters: f64, mode: &str) -> i64 {
    let mps = match mode {
        "walking" => 1.4,
        "bicycling" => 4.5,
        _ => 13.0, // driving city-scale
    };
    (meters / mps).round() as i64
}

async fn call_amap_route(
    key: &str,
    from: (f64, f64),
    to: (f64, f64),
    mode: &str,
) -> anyhow::Result<RouteResp> {
    let path = match mode {
        "walking" => "v3/direction/walking",
        "bicycling" => "v4/direction/bicycling",
        _ => "v3/direction/driving",
    };
    // AMap expects GCJ-02. Convert from our WGS84 inputs.
    let (f_lng, f_lat) = coord::wgs84_to_gcj02(from.0, from.1);
    let (t_lng, t_lat) = coord::wgs84_to_gcj02(to.0, to.1);
    let url = format!(
        "https://restapi.amap.com/{path}?key={key}&origin={f_lng:.6},{f_lat:.6}&destination={t_lng:.6},{t_lat:.6}"
    );
    let resp: serde_json::Value = reqwest::Client::new()
        .get(&url)
        .send()
        .await?
        .json()
        .await?;

    // AMap response shape varies between v3 and v4 endpoints; handle both
    // common cases enough to extract distance/duration/polyline.
    let route_obj = resp
        .get("route")
        .or_else(|| resp.get("data"))
        .ok_or_else(|| anyhow::anyhow!("amap: missing route"))?;
    let path_obj = route_obj
        .pointer("/paths/0")
        .or_else(|| route_obj.pointer("/data/paths/0"))
        .ok_or_else(|| anyhow::anyhow!("amap: missing first path"))?;
    let distance: f64 = path_obj["distance"]
        .as_str()
        .and_then(|s| s.parse().ok())
        .or_else(|| path_obj["distance"].as_f64())
        .unwrap_or(0.0);
    let duration: i64 = path_obj["duration"]
        .as_str()
        .and_then(|s| s.parse().ok())
        .or_else(|| path_obj["duration"].as_i64())
        .unwrap_or(0);

    let mut polyline = Vec::new();
    if let Some(steps) = path_obj["steps"].as_array() {
        for step in steps {
            if let Some(pl) = step["polyline"].as_str() {
                for pair in pl.split(';') {
                    let mut p = pair.split(',');
                    if let (Some(lng), Some(lat)) = (p.next(), p.next()) {
                        if let (Ok(lng), Ok(lat)) = (lng.parse::<f64>(), lat.parse::<f64>()) {
                            let (w_lng, w_lat) = coord::gcj02_to_wgs84(lng, lat);
                            polyline.push(LngLat {
                                lng: w_lng,
                                lat: w_lat,
                            });
                        }
                    }
                }
            }
        }
    }
    if polyline.is_empty() {
        polyline.push(LngLat {
            lng: from.0,
            lat: from.1,
        });
        polyline.push(LngLat {
            lng: to.0,
            lat: to.1,
        });
    }

    Ok(RouteResp {
        distance_m: distance,
        duration_s: duration,
        polyline,
        source: "amap".into(),
    })
}

async fn call_osrm_route(
    base: &str,
    from: (f64, f64),
    to: (f64, f64),
    mode: &str,
) -> anyhow::Result<RouteResp> {
    let profile = match mode {
        "walking" => "foot",
        "bicycling" => "bike",
        _ => "driving",
    };
    let url = format!(
        "{base}/route/v1/{profile}/{:.6},{:.6};{:.6},{:.6}?overview=full&geometries=geojson",
        from.0, from.1, to.0, to.1
    );
    let resp: serde_json::Value = reqwest::Client::new()
        .get(&url)
        .send()
        .await?
        .json()
        .await?;

    let route0 = resp
        .pointer("/routes/0")
        .ok_or_else(|| anyhow::anyhow!("osrm: missing first route"))?;
    let distance = route0["distance"].as_f64().unwrap_or(0.0);
    let duration = route0["duration"].as_f64().unwrap_or(0.0).round() as i64;

    let mut polyline = Vec::new();
    if let Some(coords) = route0
        .pointer("/geometry/coordinates")
        .and_then(|v| v.as_array())
    {
        for c in coords {
            if let Some(arr) = c.as_array() {
                if let (Some(lng), Some(lat)) = (
                    arr.first().and_then(|v| v.as_f64()),
                    arr.get(1).and_then(|v| v.as_f64()),
                ) {
                    polyline.push(LngLat { lng, lat });
                }
            }
        }
    }
    if polyline.is_empty() {
        polyline.push(LngLat {
            lng: from.0,
            lat: from.1,
        });
        polyline.push(LngLat {
            lng: to.0,
            lat: to.1,
        });
    }

    Ok(RouteResp {
        distance_m: distance,
        duration_s: duration,
        polyline,
        source: "osm".into(),
    })
}
