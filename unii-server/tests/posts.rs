//! Integration tests for /api/v1/posts (W5).

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

async fn create_post(app: &axum::Router, token: &str, content: &str) -> i64 {
    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/posts/",
            &json!({"content": content, "visibility": "public"}),
            Some(token),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    body_json(resp).await["data"]["id"].as_i64().unwrap()
}

#[sqlx::test(migrations = "./migrations")]
async fn create_then_feed_returns_post(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let alice = register(&app, "13800000001", "alice").await;
    let _id = create_post(&app, &alice, "first post").await;

    let resp = app
        .clone()
        .oneshot(empty_req(Method::GET, "/api/v1/posts/?limit=20", &alice))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    let posts = v["data"].as_array().unwrap();
    assert_eq!(posts.len(), 1);
    assert_eq!(posts[0]["content"], "first post");
    assert_eq!(posts[0]["visibility"], "public");
    assert_eq!(posts[0]["liked_by_me"], false);
}

#[sqlx::test(migrations = "./migrations")]
async fn create_post_rejects_empty_body(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let alice = register(&app, "13800000001", "alice").await;
    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/posts/",
            &json!({"visibility": "public"}),
            Some(&alice),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
}

#[sqlx::test(migrations = "./migrations")]
async fn private_post_hidden_from_others(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let alice = register(&app, "13800000001", "alice").await;
    let bob = register(&app, "13800000002", "bob").await;

    // alice creates a private post
    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/posts/",
            &json!({"content": "secret", "visibility": "private"}),
            Some(&alice),
        ))
        .await
        .unwrap();
    let pid = body_json(resp).await["data"]["id"].as_i64().unwrap();

    // alice can fetch detail
    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            &format!("/api/v1/posts/{pid}"),
            &alice,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);

    // bob cannot
    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            &format!("/api/v1/posts/{pid}"),
            &bob,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);

    // bob's feed is empty
    let resp = app
        .clone()
        .oneshot(empty_req(Method::GET, "/api/v1/posts/", &bob))
        .await
        .unwrap();
    let v = body_json(resp).await;
    assert_eq!(v["data"].as_array().unwrap().len(), 0);
}

#[sqlx::test(migrations = "./migrations")]
async fn like_toggle_round_trip(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let alice = register(&app, "13800000001", "alice").await;
    let bob = register(&app, "13800000002", "bob").await;
    let pid = create_post(&app, &alice, "like me").await;

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::POST,
            &format!("/api/v1/posts/{pid}/like"),
            &bob,
        ))
        .await
        .unwrap();
    let v = body_json(resp).await;
    assert_eq!(v["data"]["liked"], true);
    assert_eq!(v["data"]["like_count"], 1);

    // toggling again unlikes
    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::POST,
            &format!("/api/v1/posts/{pid}/like"),
            &bob,
        ))
        .await
        .unwrap();
    let v = body_json(resp).await;
    assert_eq!(v["data"]["liked"], false);
    assert_eq!(v["data"]["like_count"], 0);
}

#[sqlx::test(migrations = "./migrations")]
async fn comment_then_list(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let alice = register(&app, "13800000001", "alice").await;
    let bob = register(&app, "13800000002", "bob").await;
    let pid = create_post(&app, &alice, "hot take").await;

    app.clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/posts/{pid}/comments"),
            &json!({"content": "I disagree."}),
            Some(&bob),
        ))
        .await
        .unwrap();

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            &format!("/api/v1/posts/{pid}/comments"),
            &alice,
        ))
        .await
        .unwrap();
    let v = body_json(resp).await;
    let comments = v["data"].as_array().unwrap();
    assert_eq!(comments.len(), 1);
    assert_eq!(comments[0]["content"], "I disagree.");
    assert_eq!(comments[0]["username"], "bob");
}

#[sqlx::test(migrations = "./migrations")]
async fn comment_rejects_blank_content(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let alice = register(&app, "13800000001", "alice").await;
    let pid = create_post(&app, &alice, "x").await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/posts/{pid}/comments"),
            &json!({"content": "   "}),
            Some(&alice),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
}

#[sqlx::test(migrations = "./migrations")]
async fn comment_count_updates_after_post(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let alice = register(&app, "13800000001", "alice").await;
    let pid = create_post(&app, &alice, "x").await;

    app.clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/posts/{pid}/comments"),
            &json!({"content": "a"}),
            Some(&alice),
        ))
        .await
        .unwrap();

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            &format!("/api/v1/posts/{pid}"),
            &alice,
        ))
        .await
        .unwrap();
    assert_eq!(body_json(resp).await["data"]["comment_count"], 1);
}
