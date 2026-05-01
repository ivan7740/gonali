use axum::{
    extract::{Path, Query, State},
    routing::get,
    Extension, Json, Router,
};
use tracing::{info, instrument};

use crate::{
    dto::{
        common::ApiResp,
        moment::{build_moment_view, CreateMomentReq, MomentView, MomentsQuery},
        post::MediaView,
    },
    error::{AppError, AppResult},
    service::{moment_repo, post_repo, team_repo},
    state::AppState,
    util::jwt::Claims,
};

/// Mounted under `/api/v1/teams/:team_id/moments`.
pub fn team_scoped() -> Router<AppState> {
    Router::new().route("/", get(list).post(create))
}

#[instrument(skip(state))]
async fn list(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(team_id): Path<i64>,
    Query(q): Query<MomentsQuery>,
) -> AppResult<Json<ApiResp<Vec<MomentView>>>> {
    if team_repo::role_of(&state.db, team_id, claims.sub)
        .await?
        .is_none()
    {
        return Err(AppError::NotFound("team".into()));
    }
    let rows = moment_repo::list_team(&state.db, team_id, q.since).await?;
    let mut out = Vec::with_capacity(rows.len());
    for row in rows {
        let media_rows = post_repo::media_for(&state.db, "moment", row.id).await?;
        let media: Vec<MediaView> = media_rows.iter().map(MediaView::from).collect();
        out.push(build_moment_view(row, media));
    }
    Ok(ApiResp::ok(out))
}

#[instrument(skip(state, body))]
async fn create(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(team_id): Path<i64>,
    Json(body): Json<CreateMomentReq>,
) -> AppResult<Json<ApiResp<MomentView>>> {
    if team_repo::role_of(&state.db, team_id, claims.sub)
        .await?
        .is_none()
    {
        return Err(AppError::NotFound("team".into()));
    }
    let content = body
        .content
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty());
    if content.is_none() && body.media_ids.is_empty() {
        return Err(AppError::validation("moment must have content or media"));
    }
    let row = moment_repo::insert(&state.db, team_id, claims.sub, content).await?;
    if !body.media_ids.is_empty() {
        sqlx::query(
            "UPDATE media_files SET owner_type = 'moment', owner_id = $1
             WHERE id = ANY($2::BIGINT[]) AND owner_type = 'pending'",
        )
        .bind(row.id)
        .bind(&body.media_ids)
        .execute(&state.db)
        .await?;
    }

    // Re-fetch joined view + media for the response.
    let joined = moment_repo::list_team(&state.db, team_id, None)
        .await?
        .into_iter()
        .find(|r| r.id == row.id)
        .ok_or_else(|| AppError::Internal("moment vanished after insert".into()))?;
    let media_rows = post_repo::media_for(&state.db, "moment", row.id).await?;
    let media: Vec<MediaView> = media_rows.iter().map(MediaView::from).collect();
    info!(team_id, moment_id = row.id, "moment created");
    Ok(ApiResp::ok(build_moment_view(joined, media)))
}
