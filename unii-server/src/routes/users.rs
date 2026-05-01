use axum::{extract::State, routing::get, Extension, Json, Router};

use crate::{
    dto::{auth::UserPublic, common::ApiResp},
    error::{AppError, AppResult},
    routes::auth::public_view,
    service::user_repo,
    state::AppState,
    util::jwt::Claims,
};

pub fn routes() -> Router<AppState> {
    Router::new().route("/me", get(me))
}

async fn me(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> AppResult<Json<ApiResp<UserPublic>>> {
    let user = user_repo::find_by_id(&state.db, claims.sub)
        .await?
        .ok_or_else(|| AppError::NotFound("user".into()))?;
    Ok(ApiResp::ok(public_view(&user)))
}
