use axum::{
    extract::{Path, State},
    routing::{get, post},
    Extension, Json, Router,
};
use tracing::{info, instrument};

use crate::{
    dto::{
        activity::{ActivityView, CreateActivityReq, UpdateActivityReq},
        common::ApiResp,
        team::is_valid_visibility,
    },
    error::{AppError, AppResult},
    service::{activity_repo, team_repo},
    state::AppState,
    util::jwt::Claims,
};

/// Routes mounted under `/api/v1/teams/:id/activities` (create + list).
pub fn team_scoped() -> Router<AppState> {
    Router::new().route("/", post(create).get(list))
}

/// Routes mounted under `/api/v1/activities/:id` (detail/update/delete).
pub fn standalone() -> Router<AppState> {
    Router::new().route("/:id", get(detail).put(update).delete(remove))
}

#[instrument(skip(state, body))]
async fn create(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(team_id): Path<i64>,
    Json(body): Json<CreateActivityReq>,
) -> AppResult<Json<ApiResp<ActivityView>>> {
    if team_repo::role_of(&state.db, team_id, claims.sub)
        .await?
        .is_none()
    {
        return Err(AppError::NotFound("team".into()));
    }
    if body.title.trim().is_empty() || body.title.chars().count() > 100 {
        return Err(AppError::validation("title must be 1-100 chars"));
    }
    if !body.location.is_valid() {
        return Err(AppError::validation("invalid location"));
    }
    if !is_valid_visibility(&body.visibility) {
        return Err(AppError::validation("visibility must be public/private"));
    }
    if let (Some(s), Some(e)) = (body.start_time, body.end_time) {
        if e < s {
            return Err(AppError::validation("end_time before start_time"));
        }
    }

    let row = activity_repo::insert(&state.db, team_id, claims.sub, &body).await?;
    info!(team_id, activity_id = row.id, "activity created");
    Ok(ApiResp::ok(row.into()))
}

#[instrument(skip(state))]
async fn list(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(team_id): Path<i64>,
) -> AppResult<Json<ApiResp<Vec<ActivityView>>>> {
    if team_repo::role_of(&state.db, team_id, claims.sub)
        .await?
        .is_none()
    {
        return Err(AppError::NotFound("team".into()));
    }
    let rows = activity_repo::list_by_team(&state.db, team_id).await?;
    Ok(ApiResp::ok(rows.into_iter().map(Into::into).collect()))
}

#[instrument(skip(state))]
async fn detail(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<i64>,
) -> AppResult<Json<ApiResp<ActivityView>>> {
    let row = activity_repo::find_by_id(&state.db, id)
        .await?
        .ok_or_else(|| AppError::NotFound("activity".into()))?;
    if team_repo::role_of(&state.db, row.team_id, claims.sub)
        .await?
        .is_none()
    {
        return Err(AppError::NotFound("activity".into()));
    }
    Ok(ApiResp::ok(row.into()))
}

#[instrument(skip(state, body))]
async fn update(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<i64>,
    Json(body): Json<UpdateActivityReq>,
) -> AppResult<Json<ApiResp<ActivityView>>> {
    let row = activity_repo::find_by_id(&state.db, id)
        .await?
        .ok_or_else(|| AppError::NotFound("activity".into()))?;
    let team = team_repo::find_by_id(&state.db, row.team_id)
        .await?
        .ok_or_else(|| AppError::NotFound("team".into()))?;
    if claims.sub != row.creator_id && claims.sub != team.owner_id {
        return Err(AppError::Unauthorized);
    }
    if let Some(t) = body.title.as_deref() {
        if t.trim().is_empty() || t.chars().count() > 100 {
            return Err(AppError::validation("title must be 1-100 chars"));
        }
    }
    if let Some(loc) = body.location {
        if !loc.is_valid() {
            return Err(AppError::validation("invalid location"));
        }
    }
    if let Some(v) = body.visibility.as_deref() {
        if !is_valid_visibility(v) {
            return Err(AppError::validation("visibility must be public/private"));
        }
    }
    let updated = activity_repo::update(&state.db, id, &body).await?;
    Ok(ApiResp::ok(updated.into()))
}

#[instrument(skip(state))]
async fn remove(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<i64>,
) -> AppResult<Json<ApiResp<&'static str>>> {
    let row = activity_repo::find_by_id(&state.db, id)
        .await?
        .ok_or_else(|| AppError::NotFound("activity".into()))?;
    let team = team_repo::find_by_id(&state.db, row.team_id)
        .await?
        .ok_or_else(|| AppError::NotFound("team".into()))?;
    if claims.sub != row.creator_id && claims.sub != team.owner_id {
        return Err(AppError::Unauthorized);
    }
    activity_repo::delete(&state.db, id).await?;
    info!(activity_id = id, "activity deleted");
    Ok(ApiResp::ok("ok"))
}
