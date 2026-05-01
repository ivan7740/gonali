//! Integration tests for the W2 profile module.

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

fn get_req(path: &str, bearer: &str) -> Request<Body> {
    Request::builder()
        .method(Method::GET)
        .uri(path)
        .header(header::AUTHORIZATION, format!("Bearer {bearer}"))
        .body(Body::empty())
        .unwrap()
}

async fn register_alice(app: &axum::Router) -> String {
    let body = json!({
        "phone": "13800001234",
        "password": "Pa$$w0rd",
        "username": "alice",
    });
    let resp = app
        .clone()
        .oneshot(json_req(Method::POST, "/api/v1/auth/register", &body, None))
        .await
        .unwrap();
    let v = body_json(resp).await;
    v["data"]["access_token"].as_str().unwrap().to_string()
}

#[sqlx::test(migrations = "./migrations")]
async fn get_me_returns_full_profile(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let token = register_alice(&app).await;

    let resp = app
        .clone()
        .oneshot(get_req("/api/v1/users/me", &token))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    assert_eq!(v["data"]["phone"], "13800001234");
    assert_eq!(v["data"]["username"], "alice");
    assert_eq!(v["data"]["needs_map_setup"], true);
    // Defaults from migration:
    assert_eq!(v["data"]["theme"], "system");
    assert_eq!(v["data"]["language"], "zh");
    assert_eq!(v["data"]["location_share_enabled"], true);
}

#[sqlx::test(migrations = "./migrations")]
async fn put_me_updates_profile_partially(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let token = register_alice(&app).await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::PUT,
            "/api/v1/users/me",
            &json!({"nickname": "Alice", "city": "SH", "email": "a@b.co"}),
            Some(&token),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    assert_eq!(v["data"]["nickname"], "Alice");
    assert_eq!(v["data"]["city"], "SH");
    assert_eq!(v["data"]["email"], "a@b.co");
    // Untouched:
    assert_eq!(v["data"]["username"], "alice");
}

#[sqlx::test(migrations = "./migrations")]
async fn put_me_rejects_bad_email(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let token = register_alice(&app).await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::PUT,
            "/api/v1/users/me",
            &json!({"email": "nope"}),
            Some(&token),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
}

#[sqlx::test(migrations = "./migrations")]
async fn put_me_rejects_taken_username(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let token_a = register_alice(&app).await;
    // bob registers
    app.clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/auth/register",
            &json!({"phone": "13800005555", "password": "Pa$$w0rd", "username": "bob"}),
            None,
        ))
        .await
        .unwrap();

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::PUT,
            "/api/v1/users/me",
            &json!({"username": "bob"}),
            Some(&token_a),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::CONFLICT);
}

#[sqlx::test(migrations = "./migrations")]
async fn put_settings_updates_theme_and_map(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let token = register_alice(&app).await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::PUT,
            "/api/v1/users/me/settings",
            &json!({"theme": "dark", "map_engine": "amap", "location_share_enabled": false}),
            Some(&token),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    assert_eq!(v["data"]["theme"], "dark");
    assert_eq!(v["data"]["map_engine"], "amap");
    assert_eq!(v["data"]["location_share_enabled"], false);
    assert_eq!(v["data"]["needs_map_setup"], false);
}

#[sqlx::test(migrations = "./migrations")]
async fn put_settings_rejects_bad_theme(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let token = register_alice(&app).await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::PUT,
            "/api/v1/users/me/settings",
            &json!({"theme": "neon"}),
            Some(&token),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
}

#[sqlx::test(migrations = "./migrations")]
async fn change_password_then_login_with_new(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let token = register_alice(&app).await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/users/me/password",
            &json!({"old_password": "Pa$$w0rd", "new_password": "NewPa$$1"}),
            Some(&token),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);

    // login with old fails
    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/auth/login",
            &json!({"phone": "13800001234", "password": "Pa$$w0rd"}),
            None,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);

    // login with new succeeds
    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/auth/login",
            &json!({"phone": "13800001234", "password": "NewPa$$1"}),
            None,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[sqlx::test(migrations = "./migrations")]
async fn change_password_rejects_wrong_old(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let token = register_alice(&app).await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/users/me/password",
            &json!({"old_password": "WrongOne1", "new_password": "NewPa$$1"}),
            Some(&token),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[sqlx::test(migrations = "./migrations")]
async fn delete_me_then_login_fails(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let token = register_alice(&app).await;

    let req = Request::builder()
        .method(Method::DELETE)
        .uri("/api/v1/users/me")
        .header(header::AUTHORIZATION, format!("Bearer {token}"))
        .body(Body::empty())
        .unwrap();
    let resp = app.clone().oneshot(req).await.unwrap();
    assert_eq!(resp.status(), StatusCode::OK);

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/auth/login",
            &json!({"phone": "13800001234", "password": "Pa$$w0rd"}),
            None,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}
