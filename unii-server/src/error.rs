use axum::{
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use serde_json::json;
use thiserror::Error;

#[derive(Debug, Error)]
pub enum AppError {
    #[error("invalid credentials")]
    InvalidCredentials,
    #[error("unauthorized")]
    Unauthorized,
    #[error("not found: {0}")]
    NotFound(String),
    #[error("validation: {0}")]
    Validation(String),
    #[error("conflict: {0}")]
    Conflict(String),
    #[error(transparent)]
    Sqlx(#[from] sqlx::Error),
    #[error(transparent)]
    Jwt(#[from] jsonwebtoken::errors::Error),
    #[error("password hashing failed: {0}")]
    Argon(String),
    #[error("internal: {0}")]
    Internal(String),
}

impl From<argon2::password_hash::Error> for AppError {
    fn from(e: argon2::password_hash::Error) -> Self {
        Self::Argon(e.to_string())
    }
}

impl AppError {
    pub fn validation(msg: impl Into<String>) -> Self {
        Self::Validation(msg.into())
    }
    pub fn conflict(msg: impl Into<String>) -> Self {
        Self::Conflict(msg.into())
    }
}

impl IntoResponse for AppError {
    fn into_response(self) -> Response {
        let (status, code, msg) = match &self {
            AppError::InvalidCredentials => (StatusCode::UNAUTHORIZED, 1001, self.to_string()),
            AppError::Unauthorized => (StatusCode::UNAUTHORIZED, 1002, self.to_string()),
            AppError::NotFound(_) => (StatusCode::NOT_FOUND, 1003, self.to_string()),
            AppError::Validation(_) => (StatusCode::BAD_REQUEST, 1004, self.to_string()),
            AppError::Conflict(_) => (StatusCode::CONFLICT, 1005, self.to_string()),
            _ => {
                tracing::error!(error = ?self, "internal error");
                (
                    StatusCode::INTERNAL_SERVER_ERROR,
                    5000,
                    "internal error".to_string(),
                )
            }
        };
        (
            status,
            Json(json!({ "code": code, "msg": msg, "data": null })),
        )
            .into_response()
    }
}

pub type AppResult<T> = std::result::Result<T, AppError>;
