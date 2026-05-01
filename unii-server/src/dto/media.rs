use chrono::{DateTime, Utc};
use serde::Serialize;

/// Returned by POST /api/v1/media/upload.
#[derive(Debug, Serialize)]
pub struct UploadedMediaView {
    pub id: i64,
    pub media_type: String,
    pub url: String,
    pub size_bytes: Option<i64>,
    pub created_at: Option<DateTime<Utc>>,
}

pub fn classify_media(extension: &str) -> &'static str {
    let lower = extension.to_ascii_lowercase();
    match lower.as_str() {
        "jpg" | "jpeg" | "png" | "gif" | "webp" | "heic" => "image",
        "mp3" | "m4a" | "wav" | "aac" | "ogg" => "audio",
        "mp4" | "mov" | "webm" | "mkv" => "video",
        _ => "image", // default — keeps callers happy without exploding
    }
}
