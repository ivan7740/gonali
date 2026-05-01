//! W6 moments integration tests.

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
    body_json(resp).await["data"]["access_token"]
        .as_str()
        .unwrap()
        .to_string()
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

#[sqlx::test(migrations = "./migrations")]
async fn member_creates_and_lists_moments(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let alice = register(&app, "13800000001", "alice").await;
    let (team_id, _) = create_team(&app, &alice).await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/teams/{team_id}/moments/"),
            &json!({"content": "Look at this view"}),
            Some(&alice),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            &format!("/api/v1/teams/{team_id}/moments/"),
            &alice,
        ))
        .await
        .unwrap();
    let v = body_json(resp).await;
    let arr = v["data"].as_array().unwrap();
    assert_eq!(arr.len(), 1);
    assert_eq!(arr[0]["content"], "Look at this view");
}

#[sqlx::test(migrations = "./migrations")]
async fn non_member_cannot_access_moments(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let alice = register(&app, "13800000001", "alice").await;
    let eve = register(&app, "13800000003", "eve").await;
    let (team_id, _) = create_team(&app, &alice).await;

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            &format!("/api/v1/teams/{team_id}/moments/"),
            &eve,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/teams/{team_id}/moments/"),
            &json!({"content": "sneak"}),
            Some(&eve),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

#[sqlx::test(migrations = "./migrations")]
async fn moment_rejects_empty_body(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let alice = register(&app, "13800000001", "alice").await;
    let (team_id, _) = create_team(&app, &alice).await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/teams/{team_id}/moments/"),
            &json!({}),
            Some(&alice),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
}
