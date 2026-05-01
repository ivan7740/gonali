//! Integration tests for the W3 team module.

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
    let id = v["data"]["user"]["id"].as_i64().unwrap();
    let token = v["data"]["access_token"].as_str().unwrap().to_string();
    (id, token)
}

async fn create_team(app: &axum::Router, token: &str, name: &str) -> Value {
    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/teams/",
            &json!({"name": name}),
            Some(token),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    body_json(resp).await
}

#[sqlx::test(migrations = "./migrations")]
async fn create_team_returns_invite_code_and_owner_membership(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;

    let v = create_team(&app, &alice, "Hikers").await;
    assert_eq!(v["data"]["name"], "Hikers");
    assert_eq!(v["data"]["my_role"], 1);
    assert_eq!(v["data"]["member_count"], 1);
    let code = v["data"]["invite_code"].as_str().unwrap();
    assert_eq!(code.len(), 6);
    for c in code.chars() {
        assert!(c.is_ascii_alphanumeric());
        assert!(!"01ILO".contains(c));
    }
}

#[sqlx::test(migrations = "./migrations")]
async fn join_team_via_invite_code(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (_, bob) = register(&app, "13800000002", "bob").await;

    let team = create_team(&app, &alice, "Hikers").await;
    let code = team["data"]["invite_code"].as_str().unwrap().to_string();

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/teams/join",
            &json!({"invite_code": code}),
            Some(&bob),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    assert_eq!(v["data"]["my_role"], 0);
    assert_eq!(v["data"]["member_count"], 2);
}

#[sqlx::test(migrations = "./migrations")]
async fn duplicate_join_returns_conflict(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let team = create_team(&app, &alice, "Hikers").await;
    let code = team["data"]["invite_code"].as_str().unwrap().to_string();

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/teams/join",
            &json!({"invite_code": code}),
            Some(&alice),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::CONFLICT);
}

#[sqlx::test(migrations = "./migrations")]
async fn non_member_cannot_view_team(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (_, eve) = register(&app, "13800000003", "eve").await;
    let team = create_team(&app, &alice, "Hikers").await;
    let id = team["data"]["id"].as_i64().unwrap();

    let resp = app
        .clone()
        .oneshot(empty_req(Method::GET, &format!("/api/v1/teams/{id}"), &eve))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

#[sqlx::test(migrations = "./migrations")]
async fn list_mine_only_returns_my_teams(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (_, bob) = register(&app, "13800000002", "bob").await;

    let _t1 = create_team(&app, &alice, "Hikers").await;
    let _t2 = create_team(&app, &bob, "Climbers").await;

    let resp = app
        .clone()
        .oneshot(empty_req(Method::GET, "/api/v1/teams/mine", &alice))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    let teams = v["data"].as_array().unwrap();
    assert_eq!(teams.len(), 1);
    assert_eq!(teams[0]["name"], "Hikers");
}

#[sqlx::test(migrations = "./migrations")]
async fn members_lists_owner_first(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (_, bob) = register(&app, "13800000002", "bob").await;
    let team = create_team(&app, &alice, "Hikers").await;
    let id = team["data"]["id"].as_i64().unwrap();
    let code = team["data"]["invite_code"].as_str().unwrap().to_string();
    app.clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/teams/join",
            &json!({"invite_code": code}),
            Some(&bob),
        ))
        .await
        .unwrap();

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            &format!("/api/v1/teams/{id}/members"),
            &alice,
        ))
        .await
        .unwrap();
    let v = body_json(resp).await;
    let members = v["data"].as_array().unwrap();
    assert_eq!(members.len(), 2);
    assert_eq!(members[0]["role"], 1); // owner first
    assert_eq!(members[0]["username"], "alice");
}

#[sqlx::test(migrations = "./migrations")]
async fn owner_kicks_member(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (bob_id, bob) = register(&app, "13800000002", "bob").await;
    let team = create_team(&app, &alice, "Hikers").await;
    let id = team["data"]["id"].as_i64().unwrap();
    let code = team["data"]["invite_code"].as_str().unwrap().to_string();
    app.clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/teams/join",
            &json!({"invite_code": code}),
            Some(&bob),
        ))
        .await
        .unwrap();

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::DELETE,
            &format!("/api/v1/teams/{id}/members/{bob_id}"),
            &alice,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);

    // bob no longer has access
    let resp = app
        .clone()
        .oneshot(empty_req(Method::GET, &format!("/api/v1/teams/{id}"), &bob))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

#[sqlx::test(migrations = "./migrations")]
async fn non_owner_cannot_kick(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (alice_id, _) = (1_i64, ());
    let _ = alice_id;
    let (_, bob) = register(&app, "13800000002", "bob").await;
    let team = create_team(&app, &alice, "Hikers").await;
    let id = team["data"]["id"].as_i64().unwrap();
    let code = team["data"]["invite_code"].as_str().unwrap().to_string();
    app.clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/teams/join",
            &json!({"invite_code": code}),
            Some(&bob),
        ))
        .await
        .unwrap();

    // bob tries to kick alice
    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::DELETE,
            &format!("/api/v1/teams/{id}/members/1"),
            &bob,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[sqlx::test(migrations = "./migrations")]
async fn transfer_ownership(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (bob_id, bob) = register(&app, "13800000002", "bob").await;
    let team = create_team(&app, &alice, "Hikers").await;
    let id = team["data"]["id"].as_i64().unwrap();
    let code = team["data"]["invite_code"].as_str().unwrap().to_string();
    app.clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/teams/join",
            &json!({"invite_code": code}),
            Some(&bob),
        ))
        .await
        .unwrap();

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/teams/{id}/transfer"),
            &json!({"new_owner_id": bob_id}),
            Some(&alice),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);

    // bob can now disband
    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::DELETE,
            &format!("/api/v1/teams/{id}"),
            &bob,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[sqlx::test(migrations = "./migrations")]
async fn owner_disband_removes_team(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let team = create_team(&app, &alice, "Hikers").await;
    let id = team["data"]["id"].as_i64().unwrap();

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::DELETE,
            &format!("/api/v1/teams/{id}"),
            &alice,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            &format!("/api/v1/teams/{id}"),
            &alice,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

#[sqlx::test(migrations = "./migrations")]
async fn non_owner_cannot_disband(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (_, bob) = register(&app, "13800000002", "bob").await;
    let team = create_team(&app, &alice, "Hikers").await;
    let id = team["data"]["id"].as_i64().unwrap();
    let code = team["data"]["invite_code"].as_str().unwrap().to_string();
    app.clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/teams/join",
            &json!({"invite_code": code}),
            Some(&bob),
        ))
        .await
        .unwrap();

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::DELETE,
            &format!("/api/v1/teams/{id}"),
            &bob,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}

#[sqlx::test(migrations = "./migrations")]
async fn owner_cannot_leave(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let team = create_team(&app, &alice, "Hikers").await;
    let id = team["data"]["id"].as_i64().unwrap();

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::DELETE,
            &format!("/api/v1/teams/{id}/members/me"),
            &alice,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
}
