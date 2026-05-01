use std::time::Duration;

use axum::{
    extract::{Path, Query, State},
    routing::{get, post},
    Extension, Json, Router,
};
use tokio::time::{sleep, Instant};
use tracing::{info, instrument};

use crate::{
    dto::{
        chat::{
            is_valid_msg_type, ConversationView, MessageView, MessagesQuery, SendMessageReq,
            StartConversationResp,
        },
        common::ApiResp,
    },
    error::{AppError, AppResult},
    service::{chat_repo, user_repo},
    state::AppState,
    util::jwt::Claims,
};

const RECALL_WINDOW_SECS: i64 = 120;
const LONG_POLL_TOTAL: Duration = Duration::from_secs(25);
const LONG_POLL_TICK: Duration = Duration::from_millis(800);
const MESSAGE_PAGE: i64 = 100;

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/conversations", get(list_conversations))
        .route("/conversations/:id/messages", get(messages).post(send))
        .route("/conversations/:id/read", post(mark_read))
        .route("/messages/:id/recall", post(recall))
        .route("/:user_id/start", post(start))
}

#[instrument(skip(state))]
async fn list_conversations(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> AppResult<Json<ApiResp<Vec<ConversationView>>>> {
    let rows = chat_repo::list_for_user(&state.db, claims.sub).await?;
    Ok(ApiResp::ok(rows.into_iter().map(Into::into).collect()))
}

#[instrument(skip(state))]
async fn start(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(user_id): Path<i64>,
) -> AppResult<Json<ApiResp<StartConversationResp>>> {
    if user_id == claims.sub {
        return Err(AppError::validation("cannot chat with yourself"));
    }
    if user_repo::find_by_id(&state.db, user_id).await?.is_none() {
        return Err(AppError::NotFound("user".into()));
    }
    let conv = chat_repo::get_or_create(&state.db, claims.sub, user_id).await?;
    Ok(ApiResp::ok(StartConversationResp {
        id: conv.id,
        other_user_id: user_id,
    }))
}

#[instrument(skip(state))]
async fn messages(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<i64>,
    Query(q): Query<MessagesQuery>,
) -> AppResult<Json<ApiResp<Vec<MessageView>>>> {
    let conv = chat_repo::find_conversation(&state.db, id)
        .await?
        .ok_or_else(|| AppError::NotFound("conversation".into()))?;
    if !chat_repo::is_participant(&conv, claims.sub) {
        return Err(AppError::NotFound("conversation".into()));
    }

    let initial = chat_repo::list_messages_after(&state.db, id, q.since_id, MESSAGE_PAGE).await?;
    if !q.wait || !initial.is_empty() {
        return Ok(ApiResp::ok(initial.into_iter().map(Into::into).collect()));
    }

    // Long-poll: idle until a new message lands or the budget runs out.
    let deadline = Instant::now() + LONG_POLL_TOTAL;
    while Instant::now() < deadline {
        sleep(LONG_POLL_TICK).await;
        let rows = chat_repo::list_messages_after(&state.db, id, q.since_id, MESSAGE_PAGE).await?;
        if !rows.is_empty() {
            return Ok(ApiResp::ok(rows.into_iter().map(Into::into).collect()));
        }
    }
    Ok(ApiResp::ok(Vec::new()))
}

#[instrument(skip(state, body))]
async fn send(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<i64>,
    Json(body): Json<SendMessageReq>,
) -> AppResult<Json<ApiResp<MessageView>>> {
    let conv = chat_repo::find_conversation(&state.db, id)
        .await?
        .ok_or_else(|| AppError::NotFound("conversation".into()))?;
    if !chat_repo::is_participant(&conv, claims.sub) {
        return Err(AppError::NotFound("conversation".into()));
    }
    if !is_valid_msg_type(&body.msg_type) {
        return Err(AppError::validation(
            "msg_type must be text/image/audio/video",
        ));
    }
    if body.msg_type == "text" {
        let c = body.content.as_deref().unwrap_or("").trim();
        if c.is_empty() || c.chars().count() > 2000 {
            return Err(AppError::validation("text content must be 1-2000 chars"));
        }
    } else if body.media_url.as_deref().unwrap_or("").is_empty() {
        return Err(AppError::validation("media_url required for non-text"));
    }

    let row = chat_repo::insert_message(
        &state.db,
        id,
        claims.sub,
        &body.msg_type,
        body.content.as_deref(),
        body.media_url.as_deref(),
        body.duration,
    )
    .await?;
    info!(
        message_id = row.id,
        conversation_id = id,
        "chat message sent"
    );
    Ok(ApiResp::ok(row.into()))
}

#[instrument(skip(state))]
async fn mark_read(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<i64>,
) -> AppResult<Json<ApiResp<&'static str>>> {
    let conv = chat_repo::find_conversation(&state.db, id)
        .await?
        .ok_or_else(|| AppError::NotFound("conversation".into()))?;
    if !chat_repo::is_participant(&conv, claims.sub) {
        return Err(AppError::NotFound("conversation".into()));
    }
    if let Some(last) = conv.last_message_id {
        chat_repo::mark_read(&state.db, id, claims.sub, last).await?;
    }
    Ok(ApiResp::ok("ok"))
}

#[instrument(skip(state))]
async fn recall(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<i64>,
) -> AppResult<Json<ApiResp<MessageView>>> {
    let msg = chat_repo::find_message(&state.db, id)
        .await?
        .ok_or_else(|| AppError::NotFound("message".into()))?;
    if msg.sender_id != claims.sub {
        return Err(AppError::Unauthorized);
    }
    if msg.is_recalled {
        return Err(AppError::validation("already recalled"));
    }
    let created = msg
        .created_at
        .ok_or_else(|| AppError::Internal("message has no timestamp".into()))?;
    let age = (chrono::Utc::now() - created).num_seconds();
    if age > RECALL_WINDOW_SECS {
        return Err(AppError::validation("recall window expired"));
    }
    chat_repo::mark_recalled(&state.db, id).await?;
    let mut updated = msg;
    updated.is_recalled = true;
    Ok(ApiResp::ok(updated.into()))
}
