//! Integration tests for /api/v1/teams/:id/heartbeat (W4).

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

async fn register(app: &axum::Router, phone: &str, username: &str) -> (i64, String) {
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
    (
        v["data"]["user"]["id"].as_i64().unwrap(),
        v["data"]["access_token"].as_str().unwrap().to_string(),
    )
}

async fn create_team(app: &axum::Router, token: &str) -> (i64, String) {
    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/teams/",
            &json!({"name": "Hikers"}),
            Some(token),
        ))
        .await
        .unwrap();
    let v = body_json(resp).await;
    (
        v["data"]["id"].as_i64().unwrap(),
        v["data"]["invite_code"].as_str().unwrap().to_string(),
    )
}

async fn join_team(app: &axum::Router, token: &str, code: &str) {
    app.clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/teams/join",
            &json!({"invite_code": code}),
            Some(token),
        ))
        .await
        .unwrap();
}

async fn report(app: &axum::Router, token: &str, lng: f64, lat: f64) {
    app.clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/locations/report",
            &json!({"lng": lng, "lat": lat}),
            Some(token),
        ))
        .await
        .unwrap();
}

#[sqlx::test(migrations = "./migrations")]
async fn heartbeat_returns_member_locations(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (_, bob) = register(&app, "13800000002", "bob").await;
    let (team_id, code) = create_team(&app, &alice).await;
    join_team(&app, &bob, &code).await;

    report(&app, &alice, 121.0, 31.0).await;
    report(&app, &bob, 121.5, 31.5).await;

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            &format!("/api/v1/teams/{team_id}/heartbeat"),
            &alice,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    let members = v["data"]["members"].as_array().unwrap();
    assert_eq!(members.len(), 2);
    assert_eq!(v["data"]["moment_unread"], 0);
}

#[sqlx::test(migrations = "./migrations")]
async fn heartbeat_omits_member_with_share_disabled(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (_, bob) = register(&app, "13800000002", "bob").await;
    let (team_id, code) = create_team(&app, &alice).await;
    join_team(&app, &bob, &code).await;

    report(&app, &alice, 121.0, 31.0).await;
    report(&app, &bob, 121.5, 31.5).await;

    // Bob disables location sharing.
    app.clone()
        .oneshot(json_req(
            Method::PUT,
            "/api/v1/users/me/settings",
            &json!({"location_share_enabled": false}),
            Some(&bob),
        ))
        .await
        .unwrap();

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            &format!("/api/v1/teams/{team_id}/heartbeat"),
            &alice,
        ))
        .await
        .unwrap();
    let v = body_json(resp).await;
    let members = v["data"]["members"].as_array().unwrap();
    assert_eq!(members.len(), 1);
    assert_eq!(members[0]["username"], "alice");
}

#[sqlx::test(migrations = "./migrations")]
async fn non_member_cannot_call_heartbeat(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (_, eve) = register(&app, "13800000003", "eve").await;
    let (team_id, _) = create_team(&app, &alice).await;

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            &format!("/api/v1/teams/{team_id}/heartbeat"),
            &eve,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

#[sqlx::test(migrations = "./migrations")]
async fn heartbeat_with_since_returns_recent_activities(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (team_id, _) = create_team(&app, &alice).await;

    // Take a `since` snapshot before creating the activity.
    let since = chrono::Utc::now() - chrono::Duration::seconds(1);

    app.clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/teams/{team_id}/activities/"),
            &json!({
                "title": "Hike",
                "location": {"lng": 121.0, "lat": 31.0},
                "visibility": "private"
            }),
            Some(&alice),
        ))
        .await
        .unwrap();

    let url = format!(
        "/api/v1/teams/{team_id}/heartbeat?since={}",
        urlencoding::encode(&since.to_rfc3339())
    );
    let resp = app
        .clone()
        .oneshot(empty_req(Method::GET, &url, &alice))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    assert_eq!(v["data"]["activity_changes"].as_array().unwrap().len(), 1);
}
