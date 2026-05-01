use axum::{
    extract::{Multipart, State},
    routing::post,
    Extension, Json, Router,
};
use tracing::{info, instrument};
use uuid::Uuid;

use crate::{
    dto::{
        common::ApiResp,
        media::{classify_media, UploadedMediaView},
    },
    error::{AppError, AppResult},
    service::media_repo,
    state::AppState,
    util::jwt::Claims,
};

pub fn routes() -> Router<AppState> {
    Router::new().route("/upload", post(upload))
}

#[instrument(skip(state, multipart))]
async fn upload(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    mut multipart: Multipart,
) -> AppResult<Json<ApiResp<UploadedMediaView>>> {
    let mut bytes: Option<Vec<u8>> = None;
    let mut ext: Option<String> = None;

    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| AppError::validation(format!("multipart error: {e}")))?
    {
        if field.name() == Some("file") {
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
    let media_type = classify_media(&ext);
    let filename = format!("media-{}-{}.{ext}", claims.sub, Uuid::new_v4());

    let path = state.upload_dir.join(&filename);
    let size = bytes.len() as i64;
    tokio::fs::write(&path, &bytes)
        .await
        .map_err(|e| AppError::Internal(format!("write media: {e}")))?;

    let url = format!("{}/uploads/{}", state.public_base_url, filename);
    let row =
        media_repo::insert_pending(&state.db, claims.sub, media_type, &url, Some(size)).await?;
    info!(media_id = row.id, %url, "media uploaded");
    Ok(ApiResp::ok(UploadedMediaView {
        id: row.id,
        media_type: row.media_type,
        url: row.url,
        size_bytes: row.size_bytes,
        created_at: row.created_at,
    }))
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
