//! Integration tests for /api/v1/locations/* (W4).

use axum::{
    body::Body,
    http::{header, Method, Request, StatusCode},
};
use http_body_util::BodyExt;
use serde_json::{json, Value};
use sqlx::PgPool;
use tower::ServiceExt;
use unii_server::{build_router, build_state, config::Config};

fn cfg() -> Config {
    Config {
        database_url: String::new(),
        jwt_secret: "test-secret-test-secret-test-secret-1234".into(),
        port: 0,
        access_ttl_secs: 60 * 60,
        refresh_ttl_secs: 24 * 60 * 60,
        upload_dir: std::env::temp_dir().join("unii-test-uploads"),
        public_base_url: "http://localhost".into(),
    }
}

async fn body_json(resp: axum::response::Response) -> Value {
    let bytes = resp.into_body().collect().await.unwrap().to_bytes();
    serde_json::from_slice(&bytes).unwrap()
}

fn json_req(method: Method, path: &str, body: &Value, bearer: Option<&str>) -> Request<Body> {
    let mut b = Request::builder()
        .method(method)
        .uri(path)
        .header(header::CONTENT_TYPE, "application/json");
    if let Some(t) = bearer {
        b = b.header(header::AUTHORIZATION, format!("Bearer {t}"));
    }
    b.body(Body::from(body.to_string())).unwrap()
}

fn empty_req(method: Method, path: &str, bearer: &str) -> Request<Body> {
    Request::builder()
        .method(method)
        .uri(path)
        .header(header::AUTHORIZATION, format!("Bearer {bearer}"))
        .body(Body::empty())
        .unwrap()
}

async fn register(app: &axum::Router, phone: &str, username: &str) -> String {
    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/auth/register",
            &json!({"phone": phone, "password": "Pa$$w0rd", "username": username}),
            None,
        ))
        .await
        .unwrap();
    let v = body_json(resp).await;
    v["data"]["access_token"].as_str().unwrap().to_string()
}

#[sqlx::test(migrations = "./migrations")]
async fn report_then_distance(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let alice = register(&app, "13800000001", "alice").await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/locations/report",
            &json!({"lng": 121.4737, "lat": 31.2304, "accuracy": 10.0}),
            Some(&alice),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    assert!((v["data"]["lng"].as_f64().unwrap() - 121.4737).abs() < 1e-6);

    // ~111 km between two points 1 deg lng apart at 31N (cos(31)*111km).
    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            "/api/v1/locations/distance?from=121.0,31.0&to=122.0,31.0",
            &alice,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    let m = v["data"]["meters"].as_f64().unwrap();
    assert!(m > 90_000.0 && m < 100_000.0, "distance was {m}");
}

#[sqlx::test(migrations = "./migrations")]
async fn report_rejects_bad_coords(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let alice = register(&app, "13800000001", "alice").await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/locations/report",
            &json!({"lng": 999.0, "lat": 0.0}),
            Some(&alice),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
}

#[sqlx::test(migrations = "./migrations")]
async fn report_upserts_latest(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let alice = register(&app, "13800000001", "alice").await;

    // First report
    app.clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/locations/report",
            &json!({"lng": 121.4737, "lat": 31.2304}),
            Some(&alice),
        ))
        .await
        .unwrap();
    // Second report — should overwrite, not duplicate.
    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/locations/report",
            &json!({"lng": 121.5, "lat": 31.3}),
            Some(&alice),
        ))
        .await
        .unwrap();
    let v = body_json(resp).await;
    assert!((v["data"]["lng"].as_f64().unwrap() - 121.5).abs() < 1e-6);
}

#[sqlx::test(migrations = "./migrations")]
async fn route_returns_fallback_when_amap_key_missing(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let alice = register(&app, "13800000001", "alice").await;

    // Ensure AMAP_WEB_KEY is empty for this test.
    let prev = std::env::var("AMAP_WEB_KEY").ok();
    std::env::remove_var("AMAP_WEB_KEY");

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            "/api/v1/locations/route?from=121.0,31.0&to=122.0,31.0&engine=amap&mode=driving",
            &alice,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    assert_eq!(v["data"]["source"], "fallback");
    assert!(v["data"]["distance_m"].as_f64().unwrap() > 0.0);
    let polyline = v["data"]["polyline"].as_array().unwrap();
    assert_eq!(polyline.len(), 2);

    if let Some(p) = prev {
        std::env::set_var("AMAP_WEB_KEY", p);
    }
}

#[sqlx::test(migrations = "./migrations")]
async fn route_rejects_invalid_mode(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let alice = register(&app, "13800000001", "alice").await;

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            "/api/v1/locations/route?from=121.0,31.0&to=122.0,31.0&engine=osm&mode=teleport",
            &alice,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
}
