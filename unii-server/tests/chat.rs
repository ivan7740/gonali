//! W6 chat integration tests.

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

async fn start_with(app: &axum::Router, token: &str, other_id: i64) -> i64 {
    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::POST,
            &format!("/api/v1/chats/{other_id}/start"),
            token,
        ))
        .await
        .unwrap();
    body_json(resp).await["data"]["id"].as_i64().unwrap()
}

#[sqlx::test(migrations = "./migrations")]
async fn start_creates_canonical_conversation(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (alice_id, alice) = register(&app, "13800000001", "alice").await;
    let (bob_id, bob) = register(&app, "13800000002", "bob").await;

    let from_alice = start_with(&app, &alice, bob_id).await;
    let from_bob = start_with(&app, &bob, alice_id).await;
    assert_eq!(
        from_alice, from_bob,
        "both sides should resolve to the same conversation"
    );
}

#[sqlx::test(migrations = "./migrations")]
async fn cannot_chat_with_self(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (alice_id, alice) = register(&app, "13800000001", "alice").await;

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::POST,
            &format!("/api/v1/chats/{alice_id}/start"),
            &alice,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
}

#[sqlx::test(migrations = "./migrations")]
async fn send_then_fetch_messages(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (bob_id, bob) = register(&app, "13800000002", "bob").await;
    let conv = start_with(&app, &alice, bob_id).await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/chats/conversations/{conv}/messages"),
            &json!({"msg_type": "text", "content": "hello"}),
            Some(&alice),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            &format!("/api/v1/chats/conversations/{conv}/messages"),
            &bob,
        ))
        .await
        .unwrap();
    let v = body_json(resp).await;
    let msgs = v["data"].as_array().unwrap();
    assert_eq!(msgs.len(), 1);
    assert_eq!(msgs[0]["content"], "hello");
    assert_eq!(msgs[0]["msg_type"], "text");
}

#[sqlx::test(migrations = "./migrations")]
async fn outsider_cannot_read_messages(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (bob_id, bob) = register(&app, "13800000002", "bob").await;
    let (_, eve) = register(&app, "13800000003", "eve").await;
    let conv = start_with(&app, &alice, bob_id).await;
    let _ = bob;

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            &format!("/api/v1/chats/conversations/{conv}/messages"),
            &eve,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

#[sqlx::test(migrations = "./migrations")]
async fn recall_marks_message(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (bob_id, _bob) = register(&app, "13800000002", "bob").await;
    let conv = start_with(&app, &alice, bob_id).await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/chats/conversations/{conv}/messages"),
            &json!({"msg_type": "text", "content": "oops"}),
            Some(&alice),
        ))
        .await
        .unwrap();
    let mid = body_json(resp).await["data"]["id"].as_i64().unwrap();

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::POST,
            &format!("/api/v1/chats/messages/{mid}/recall"),
            &alice,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    assert_eq!(v["data"]["is_recalled"], true);
}

#[sqlx::test(migrations = "./migrations")]
async fn non_sender_cannot_recall(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (bob_id, bob) = register(&app, "13800000002", "bob").await;
    let conv = start_with(&app, &alice, bob_id).await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/chats/conversations/{conv}/messages"),
            &json!({"msg_type": "text", "content": "hi"}),
            Some(&alice),
        ))
        .await
        .unwrap();
    let mid = body_json(resp).await["data"]["id"].as_i64().unwrap();

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::POST,
            &format!("/api/v1/chats/messages/{mid}/recall"),
            &bob,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[sqlx::test(migrations = "./migrations")]
async fn list_conversations_shows_unread(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (bob_id, bob) = register(&app, "13800000002", "bob").await;
    let conv = start_with(&app, &alice, bob_id).await;
    app.clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/chats/conversations/{conv}/messages"),
            &json!({"msg_type": "text", "content": "ping"}),
            Some(&alice),
        ))
        .await
        .unwrap();

    let resp = app
        .clone()
        .oneshot(empty_req(Method::GET, "/api/v1/chats/conversations", &bob))
        .await
        .unwrap();
    let v = body_json(resp).await;
    let convs = v["data"].as_array().unwrap();
    assert_eq!(convs.len(), 1);
    assert_eq!(convs[0]["unread_count"], 1);
    assert_eq!(convs[0]["last_message_preview"], "ping");
}
