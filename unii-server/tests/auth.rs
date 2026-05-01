//! Integration tests covering the auth flow.
//!
//! Each test gets an isolated PG database via `#[sqlx::test]` and runs all
//! migrations under `migrations/` automatically.

use axum::{
    body::Body,
    http::{header, Method, Request, StatusCode},
};
use http_body_util::BodyExt;
use serde_json::{json, Value};
use sqlx::PgPool;
use tower::ServiceExt; // for `oneshot`
use unii_server::{build_router, build_state, config::Config};

fn cfg() -> Config {
    Config {
        database_url: String::new(),
        jwt_secret: "test-secret-test-secret-test-secret-1234".into(),
        port: 0,
        access_ttl_secs: 60 * 60,
        refresh_ttl_secs: 24 * 60 * 60,
    }
}

async fn body_json(resp: axum::response::Response) -> Value {
    let bytes = resp.into_body().collect().await.unwrap().to_bytes();
    serde_json::from_slice(&bytes).unwrap()
}

fn post(path: &str, body: &Value) -> Request<Body> {
    Request::builder()
        .method(Method::POST)
        .uri(path)
        .header(header::CONTENT_TYPE, "application/json")
        .body(Body::from(body.to_string()))
        .unwrap()
}

fn get(path: &str, bearer: Option<&str>) -> Request<Body> {
    let mut req = Request::builder().method(Method::GET).uri(path);
    if let Some(t) = bearer {
        req = req.header(header::AUTHORIZATION, format!("Bearer {t}"));
    }
    req.body(Body::empty()).unwrap()
}

#[sqlx::test(migrations = "./migrations")]
async fn register_then_login_then_me(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));

    // register
    let body = json!({
        "phone": "13800001111",
        "password": "Pa$$w0rd",
        "username": "alice"
    });
    let resp = app
        .clone()
        .oneshot(post("/api/v1/auth/register", &body))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    assert_eq!(v["code"], 0);
    let access = v["data"]["access_token"].as_str().unwrap().to_string();
    let refresh = v["data"]["refresh_token"].as_str().unwrap().to_string();
    assert!(!access.is_empty() && !refresh.is_empty());
    assert_eq!(v["data"]["user"]["needs_map_setup"], true);

    // login with same credentials
    let body = json!({"phone": "13800001111", "password": "Pa$$w0rd"});
    let resp = app
        .clone()
        .oneshot(post("/api/v1/auth/login", &body))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    let access2 = v["data"]["access_token"].as_str().unwrap().to_string();

    // /users/me with the new access token
    let resp = app
        .clone()
        .oneshot(get("/api/v1/users/me", Some(&access2)))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    assert_eq!(v["data"]["phone"], "13800001111");
    assert_eq!(v["data"]["username"], "alice");

    // refresh -> new access
    let resp = app
        .clone()
        .oneshot(post(
            "/api/v1/auth/refresh",
            &json!({"refresh_token": refresh}),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    assert!(v["data"]["access_token"].as_str().unwrap().len() > 10);
}

#[sqlx::test(migrations = "./migrations")]
async fn duplicate_register_returns_conflict(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let body = json!({"phone": "13800002222", "password": "Pa$$w0rd", "username": "bob"});

    let r1 = app
        .clone()
        .oneshot(post("/api/v1/auth/register", &body))
        .await
        .unwrap();
    assert_eq!(r1.status(), StatusCode::OK);
    let r2 = app
        .clone()
        .oneshot(post("/api/v1/auth/register", &body))
        .await
        .unwrap();
    assert_eq!(r2.status(), StatusCode::CONFLICT);
}

#[sqlx::test(migrations = "./migrations")]
async fn login_with_wrong_password(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    app.clone()
        .oneshot(post(
            "/api/v1/auth/register",
            &json!({"phone": "13800003333", "password": "Pa$$w0rd", "username": "carol"}),
        ))
        .await
        .unwrap();

    let resp = app
        .clone()
        .oneshot(post(
            "/api/v1/auth/login",
            &json!({"phone": "13800003333", "password": "wrong-pass1"}),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[sqlx::test(migrations = "./migrations")]
async fn me_without_token_is_401(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let resp = app.oneshot(get("/api/v1/users/me", None)).await.unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[sqlx::test(migrations = "./migrations")]
async fn validation_rejects_bad_phone(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let resp = app
        .clone()
        .oneshot(post(
            "/api/v1/auth/register",
            &json!({"phone": "not-a-phone", "password": "Pa$$w0rd", "username": "dave"}),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
}
