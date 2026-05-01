use axum::{
    extract::{Multipart, State},
    routing::{get, post, put},
    Extension, Json, Router,
};
use tracing::{info, instrument};
use uuid::Uuid;

use crate::{
    dto::{
        common::ApiResp,
        user::{
            is_plausible_email, is_valid_gender, is_valid_language, is_valid_map_engine,
            is_valid_theme, ChangePasswordReq, UpdateProfileReq, UpdateSettingsReq, UserProfile,
        },
    },
    error::{AppError, AppResult},
    service::user_repo,
    state::AppState,
    util::{jwt::Claims, password},
};

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/me", get(me).put(update_me).delete(delete_me))
        .route("/me/settings", put(update_settings))
        .route("/me/password", post(change_password))
        .route("/me/avatar", post(upload_avatar))
}

#[instrument(skip(state))]
async fn me(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> AppResult<Json<ApiResp<UserProfile>>> {
    let user = user_repo::find_by_id(&state.db, claims.sub)
        .await?
        .ok_or_else(|| AppError::NotFound("user".into()))?;
    Ok(ApiResp::ok(UserProfile::from(&user)))
}

#[instrument(skip(state, body))]
async fn update_me(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<UpdateProfileReq>,
) -> AppResult<Json<ApiResp<UserProfile>>> {
    if let Some(u) = body.username.as_deref() {
        let trimmed = u.trim();
        if trimmed.len() < 2 || trimmed.len() > 50 {
            return Err(AppError::validation("username must be 2-50 chars"));
        }
        if let Some(other) = user_repo::find_by_username(&state.db, trimmed).await? {
            if other.id != claims.sub {
                return Err(AppError::conflict("username already taken"));
            }
        }
    }
    if let Some(e) = body.email.as_deref() {
        if !e.is_empty() && !is_plausible_email(e) {
            return Err(AppError::validation("invalid email"));
        }
    }
    if let Some(g) = body.gender {
        if !is_valid_gender(g) {
            return Err(AppError::validation("gender must be 0/1/2"));
        }
    }
    if let Some(b) = body.birthday {
        if b > chrono::Utc::now().date_naive() {
            return Err(AppError::validation("birthday cannot be in the future"));
        }
    }

    let updated = user_repo::update_profile(&state.db, claims.sub, &body).await?;
    info!(user_id = updated.id, "profile updated");
    Ok(ApiResp::ok(UserProfile::from(&updated)))
}

#[instrument(skip(state, body))]
async fn update_settings(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<UpdateSettingsReq>,
) -> AppResult<Json<ApiResp<UserProfile>>> {
    if let Some(t) = body.theme.as_deref() {
        if !is_valid_theme(t) {
            return Err(AppError::validation("theme must be system/light/dark"));
        }
    }
    if let Some(l) = body.language.as_deref() {
        if !is_valid_language(l) {
            return Err(AppError::validation("language must be zh/en"));
        }
    }
    if let Some(m) = body.map_engine.as_deref() {
        if !is_valid_map_engine(m) {
            return Err(AppError::validation("map_engine must be amap/osm"));
        }
    }
    let updated = user_repo::update_settings(&state.db, claims.sub, &body).await?;
    info!(user_id = updated.id, "settings updated");
    Ok(ApiResp::ok(UserProfile::from(&updated)))
}

#[instrument(skip(state, body))]
async fn change_password(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<ChangePasswordReq>,
) -> AppResult<Json<ApiResp<&'static str>>> {
    if body.new_password.len() < 8 || body.new_password.len() > 64 {
        return Err(AppError::validation("new_password must be 8-64 chars"));
    }
    let user = user_repo::find_by_id(&state.db, claims.sub)
        .await?
        .ok_or_else(|| AppError::NotFound("user".into()))?;
    if !password::verify(&body.old_password, &user.password_hash) {
        return Err(AppError::InvalidCredentials);
    }
    let phc = password::hash(&body.new_password)?;
    user_repo::update_password(&state.db, claims.sub, &phc).await?;
    info!(user_id = claims.sub, "password changed");
    Ok(ApiResp::ok("ok"))
}

#[instrument(skip(state))]
async fn delete_me(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> AppResult<Json<ApiResp<&'static str>>> {
    let n = user_repo::delete(&state.db, claims.sub).await?;
    if n == 0 {
        return Err(AppError::NotFound("user".into()));
    }
    info!(user_id = claims.sub, "account deleted");
    Ok(ApiResp::ok("ok"))
}

#[instrument(skip(state, multipart))]
async fn upload_avatar(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    mut multipart: Multipart,
) -> AppResult<Json<ApiResp<UserProfile>>> {
    let mut bytes: Option<Vec<u8>> = None;
    let mut ext: Option<String> = None;

    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| AppError::validation(format!("multipart error: {e}")))?
    {
        if field.name() == Some("file") {
            // Pick extension from filename, then content-type, defaulting to bin.
            let inferred = field
                .file_name()
                .and_then(|n| n.rsplit_once('.').map(|(_, e)| e.to_ascii_lowercase()))
                .or_else(|| {
                    field.content_type().and_then(|ct| {
                        mime_guess::get_mime_extensions_str(ct)
                            .and_then(|exts| exts.first().map(|s| (*s).to_string()))
                    })
                })
                .unwrap_or_else(|| "bin".to_string());
            ext = Some(sanitize_ext(&inferred));
            bytes = Some(
                field
                    .bytes()
                    .await
                    .map_err(|e| AppError::validation(format!("file read failed: {e}")))?
                    .to_vec(),
            );
        }
    }

    let bytes = bytes.ok_or_else(|| AppError::validation("missing 'file' part"))?;
    let ext = ext.unwrap_or_else(|| "bin".into());
    let filename = format!("avatar-{}-{}.{ext}", claims.sub, Uuid::new_v4());

    let path = state.upload_dir.join(&filename);
    tokio::fs::write(&path, &bytes)
        .await
        .map_err(|e| AppError::Internal(format!("write avatar: {e}")))?;

    let url = format!("{}/uploads/{}", state.public_base_url, filename);
    let updated = user_repo::update_avatar(&state.db, claims.sub, &url).await?;
    info!(user_id = claims.sub, %url, "avatar uploaded");
    Ok(ApiResp::ok(UserProfile::from(&updated)))
}

fn sanitize_ext(raw: &str) -> String {
    let cleaned: String = raw
        .chars()
        .filter(|c| c.is_ascii_alphanumeric())
        .take(8)
        .collect();
    if cleaned.is_empty() {
        "bin".into()
    } else {
        cleaned.to_ascii_lowercase()
    }
}
