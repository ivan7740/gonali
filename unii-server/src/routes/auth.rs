use axum::{extract::State, routing::post, Json, Router};
use tracing::{info, instrument};

use crate::{
    dto::{
        auth::{
            is_valid_password, is_valid_phone, AccessResp, LoginReq, RefreshReq, RegisterReq,
            TokenResp, UserPublic,
        },
        common::ApiResp,
    },
    error::{AppError, AppResult},
    model::user::UserRow,
    service::user_repo,
    state::AppState,
    util::{
        jwt::{decode_token, issue_access, issue_refresh, require_type, TokenType},
        password,
    },
};

pub fn public_routes() -> Router<AppState> {
    Router::new()
        .route("/register", post(register))
        .route("/login", post(login))
        .route("/refresh", post(refresh))
        .route("/logout", post(logout))
}

#[instrument(skip(state, body), fields(phone = %body.phone, username = %body.username))]
async fn register(
    State(state): State<AppState>,
    Json(body): Json<RegisterReq>,
) -> AppResult<Json<ApiResp<TokenResp>>> {
    if !is_valid_phone(&body.phone) {
        return Err(AppError::validation("invalid phone format"));
    }
    if !is_valid_password(&body.password) {
        return Err(AppError::validation(
            "password must be 8-64 chars and contain a letter and a digit",
        ));
    }
    if body.username.trim().len() < 2 {
        return Err(AppError::validation("username too short"));
    }

    if user_repo::find_by_phone(&state.db, &body.phone)
        .await?
        .is_some()
    {
        return Err(AppError::conflict("phone already registered"));
    }
    if user_repo::find_by_username(&state.db, &body.username)
        .await?
        .is_some()
    {
        return Err(AppError::conflict("username already taken"));
    }

    let phc = password::hash(&body.password)?;
    let user = user_repo::insert(&state.db, &body.phone, &phc, &body.username).await?;

    info!(user_id = user.id, "user registered");
    Ok(ApiResp::ok(token_resp(&state, &user)?))
}

#[instrument(skip(state, body), fields(phone = %body.phone))]
async fn login(
    State(state): State<AppState>,
    Json(body): Json<LoginReq>,
) -> AppResult<Json<ApiResp<TokenResp>>> {
    let user = user_repo::find_by_phone(&state.db, &body.phone)
        .await?
        .ok_or(AppError::InvalidCredentials)?;
    if !password::verify(&body.password, &user.password_hash) {
        return Err(AppError::InvalidCredentials);
    }
    info!(user_id = user.id, "login success");
    Ok(ApiResp::ok(token_resp(&state, &user)?))
}

#[instrument(skip(state, body))]
async fn refresh(
    State(state): State<AppState>,
    Json(body): Json<RefreshReq>,
) -> AppResult<Json<ApiResp<AccessResp>>> {
    let claims =
        decode_token(&state.jwt_secret, &body.refresh_token).map_err(|_| AppError::Unauthorized)?;
    require_type(&claims, TokenType::Refresh).map_err(|_| AppError::Unauthorized)?;
    // Best-effort sanity check: user still exists.
    if user_repo::find_by_id(&state.db, claims.sub)
        .await?
        .is_none()
    {
        return Err(AppError::Unauthorized);
    }
    let access = issue_access(&state.jwt_secret, claims.sub, state.access_ttl_secs)?;
    Ok(ApiResp::ok(AccessResp {
        access_token: access,
        token_type: "Bearer",
        expires_in: state.access_ttl_secs,
    }))
}

async fn logout() -> Json<ApiResp<&'static str>> {
    // W1: stateless logout — client discards tokens.
    // W7+: blacklist refresh tokens / rotate.
    ApiResp::ok("ok")
}

fn token_resp(state: &AppState, user: &UserRow) -> AppResult<TokenResp> {
    let access = issue_access(&state.jwt_secret, user.id, state.access_ttl_secs)?;
    let refresh_t = issue_refresh(&state.jwt_secret, user.id, state.refresh_ttl_secs)?;
    Ok(TokenResp {
        access_token: access,
        refresh_token: refresh_t,
        token_type: "Bearer",
        expires_in: state.access_ttl_secs,
        user: public_view(user),
    })
}

pub fn public_view(u: &UserRow) -> UserPublic {
    UserPublic {
        id: u.id,
        phone: u.phone.clone(),
        username: u.username.clone(),
        nickname: u.nickname.clone(),
        avatar_url: u.avatar_url.clone(),
        needs_map_setup: u.needs_map_setup(),
    }
}
