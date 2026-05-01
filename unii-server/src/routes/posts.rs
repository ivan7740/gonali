use axum::{
    extract::{Path, Query, State},
    routing::{get, post},
    Extension, Json, Router,
};
use tracing::{info, instrument};

use crate::{
    dto::{
        common::ApiResp,
        post::{
            build_post_view, build_post_view_from_row, CommentView, CreateCommentReq,
            CreatePostReq, FeedQuery, LikeToggleResp, MediaView, PostView,
        },
        team::is_valid_visibility,
    },
    error::{AppError, AppResult},
    service::{post_repo, user_repo},
    state::AppState,
    util::jwt::Claims,
};

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/", post(create).get(feed))
        .route("/:id", get(detail))
        .route("/:id/like", post(toggle_like))
        .route("/:id/comments", get(list_comments).post(create_comment))
}

#[instrument(skip(state, body))]
async fn create(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<CreatePostReq>,
) -> AppResult<Json<ApiResp<PostView>>> {
    if !is_valid_visibility(&body.visibility) {
        return Err(AppError::validation("visibility must be public/private"));
    }
    let title = body
        .title
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty());
    let content = body
        .content
        .as_deref()
        .map(str::trim)
        .filter(|s| !s.is_empty());
    if title.is_none() && content.is_none() && body.media_ids.is_empty() {
        return Err(AppError::validation(
            "post must have title, content, or media",
        ));
    }

    let post_row = post_repo::insert_post(
        &state.db,
        claims.sub,
        body.team_id,
        title,
        content,
        &body.visibility,
    )
    .await?;
    if !body.media_ids.is_empty() {
        post_repo::attach_media_to_post(&state.db, post_row.id, &body.media_ids).await?;
    }

    let media_rows = post_repo::media_for(&state.db, "post", post_row.id).await?;
    let media: Vec<MediaView> = media_rows.iter().map(MediaView::from).collect();
    let user = user_repo::find_by_id(&state.db, claims.sub)
        .await?
        .ok_or_else(|| AppError::NotFound("user".into()))?;

    info!(post_id = post_row.id, "post created");
    Ok(ApiResp::ok(build_post_view_from_row(
        &post_row,
        user.username,
        user.nickname,
        user.avatar_url,
        media,
        false,
    )))
}

#[instrument(skip(state))]
async fn feed(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Query(q): Query<FeedQuery>,
) -> AppResult<Json<ApiResp<Vec<PostView>>>> {
    let limit = q.limit.unwrap_or(20).clamp(1, 50);
    let rows = post_repo::list_public_feed(&state.db, q.before_id, limit).await?;
    let post_ids: Vec<i64> = rows.iter().map(|r| r.id).collect();
    let likes = post_repo::liked_set(&state.db, &post_ids, claims.sub).await?;

    let mut out = Vec::with_capacity(rows.len());
    for row in rows {
        let media_rows = post_repo::media_for(&state.db, "post", row.id).await?;
        let media: Vec<MediaView> = media_rows.iter().map(MediaView::from).collect();
        let liked = likes.contains(&row.id);
        out.push(build_post_view(row, media, liked));
    }
    Ok(ApiResp::ok(out))
}

#[instrument(skip(state))]
async fn detail(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<i64>,
) -> AppResult<Json<ApiResp<PostView>>> {
    let row = post_repo::find_post_join(&state.db, id)
        .await?
        .ok_or_else(|| AppError::NotFound("post".into()))?;
    if row.visibility != "public" && row.author_id != claims.sub {
        return Err(AppError::NotFound("post".into()));
    }
    let media_rows = post_repo::media_for(&state.db, "post", id).await?;
    let media: Vec<MediaView> = media_rows.iter().map(MediaView::from).collect();
    let liked = post_repo::liked_by(&state.db, id, claims.sub).await?;
    Ok(ApiResp::ok(build_post_view(row, media, liked)))
}

#[instrument(skip(state))]
async fn toggle_like(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<i64>,
) -> AppResult<Json<ApiResp<LikeToggleResp>>> {
    if post_repo::find_post(&state.db, id).await?.is_none() {
        return Err(AppError::NotFound("post".into()));
    }
    let (liked, count) = post_repo::toggle_like(&state.db, id, claims.sub).await?;
    Ok(ApiResp::ok(LikeToggleResp {
        liked,
        like_count: count,
    }))
}

#[instrument(skip(state))]
async fn list_comments(
    State(state): State<AppState>,
    Extension(_claims): Extension<Claims>,
    Path(id): Path<i64>,
) -> AppResult<Json<ApiResp<Vec<CommentView>>>> {
    if post_repo::find_post(&state.db, id).await?.is_none() {
        return Err(AppError::NotFound("post".into()));
    }
    let rows = post_repo::list_comments(&state.db, id).await?;
    Ok(ApiResp::ok(rows.into_iter().map(Into::into).collect()))
}

#[instrument(skip(state, body))]
async fn create_comment(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<i64>,
    Json(body): Json<CreateCommentReq>,
) -> AppResult<Json<ApiResp<CommentView>>> {
    let content = body.content.trim();
    if content.is_empty() || content.chars().count() > 500 {
        return Err(AppError::validation("comment must be 1-500 chars"));
    }
    if post_repo::find_post(&state.db, id).await?.is_none() {
        return Err(AppError::NotFound("post".into()));
    }
    let row = post_repo::insert_comment(&state.db, id, claims.sub, body.parent_id, content).await?;
    let user = user_repo::find_by_id(&state.db, claims.sub)
        .await?
        .ok_or_else(|| AppError::NotFound("user".into()))?;
    Ok(ApiResp::ok(CommentView {
        id: row.id,
        post_id: row.post_id,
        user_id: row.user_id,
        username: user.username,
        nickname: user.nickname,
        avatar_url: user.avatar_url,
        parent_id: row.parent_id,
        content: row.content,
        created_at: row.created_at,
    }))
}
