//! Integration tests for the W3 activity CRUD module.

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

fn create_activity_body(title: &str) -> Value {
    json!({
        "title": title,
        "location": {"lng": 121.4737, "lat": 31.2304},
        "location_name": "Bund, Shanghai",
        "visibility": "private",
    })
}

#[sqlx::test(migrations = "./migrations")]
async fn member_creates_and_lists_activities(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (team_id, _) = create_team(&app, &alice).await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/teams/{team_id}/activities/"),
            &create_activity_body("Sunday hike"),
            Some(&alice),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    assert_eq!(v["data"]["title"], "Sunday hike");
    assert_eq!(v["data"]["visibility"], "private");
    let lng = v["data"]["location"]["lng"].as_f64().unwrap();
    assert!((lng - 121.4737).abs() < 1e-6);

    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::GET,
            &format!("/api/v1/teams/{team_id}/activities/"),
            &alice,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
    let v = body_json(resp).await;
    assert_eq!(v["data"].as_array().unwrap().len(), 1);
}

#[sqlx::test(migrations = "./migrations")]
async fn non_member_cannot_create_activity(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (_, eve) = register(&app, "13800000002", "eve").await;
    let (team_id, _) = create_team(&app, &alice).await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/teams/{team_id}/activities/"),
            &create_activity_body("Sneaky"),
            Some(&eve),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::NOT_FOUND);
}

#[sqlx::test(migrations = "./migrations")]
async fn create_activity_rejects_bad_location(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (team_id, _) = create_team(&app, &alice).await;

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/teams/{team_id}/activities/"),
            &json!({
                "title": "Bad coords",
                "location": {"lng": 999.0, "lat": 0.0},
                "visibility": "public",
            }),
            Some(&alice),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::BAD_REQUEST);
}

#[sqlx::test(migrations = "./migrations")]
async fn creator_updates_then_owner_deletes(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (_, bob) = register(&app, "13800000002", "bob").await;
    let (team_id, code) = create_team(&app, &alice).await;
    app.clone()
        .oneshot(json_req(
            Method::POST,
            "/api/v1/teams/join",
            &json!({"invite_code": code}),
            Some(&bob),
        ))
        .await
        .unwrap();

    // bob (member) creates an activity
    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/teams/{team_id}/activities/"),
            &create_activity_body("Bob's hike"),
            Some(&bob),
        ))
        .await
        .unwrap();
    let v = body_json(resp).await;
    let act_id = v["data"]["id"].as_i64().unwrap();

    // bob updates his own activity
    let resp = app
        .clone()
        .oneshot(json_req(
            Method::PUT,
            &format!("/api/v1/activities/{act_id}"),
            &json!({"title": "Bob's epic hike"}),
            Some(&bob),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);

    // alice (owner) can also delete it
    let resp = app
        .clone()
        .oneshot(empty_req(
            Method::DELETE,
            &format!("/api/v1/activities/{act_id}"),
            &alice,
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::OK);
}

#[sqlx::test(migrations = "./migrations")]
async fn non_creator_non_owner_cannot_edit(pool: PgPool) {
    let app = build_router(build_state(pool, cfg()));
    let (_, alice) = register(&app, "13800000001", "alice").await;
    let (_, bob) = register(&app, "13800000002", "bob").await;
    let (_, carol) = register(&app, "13800000003", "carol").await;
    let (team_id, code) = create_team(&app, &alice).await;
    for tok in [&bob, &carol] {
        app.clone()
            .oneshot(json_req(
                Method::POST,
                "/api/v1/teams/join",
                &json!({"invite_code": code}),
                Some(tok),
            ))
            .await
            .unwrap();
    }

    let resp = app
        .clone()
        .oneshot(json_req(
            Method::POST,
            &format!("/api/v1/teams/{team_id}/activities/"),
            &create_activity_body("Bob's hike"),
            Some(&bob),
        ))
        .await
        .unwrap();
    let act_id = body_json(resp).await["data"]["id"].as_i64().unwrap();

    // carol (member, not creator, not owner) tries to edit
    let resp = app
        .clone()
        .oneshot(json_req(
            Method::PUT,
            &format!("/api/v1/activities/{act_id}"),
            &json!({"title": "stolen"}),
            Some(&carol),
        ))
        .await
        .unwrap();
    assert_eq!(resp.status(), StatusCode::UNAUTHORIZED);
}
