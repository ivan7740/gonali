use axum::{
    extract::{Request, State},
    middleware::Next,
    response::Response,
};

use crate::{
    error::{AppError, AppResult},
    state::AppState,
    util::jwt::{decode_token, require_type, Claims, TokenType},
};

pub async fn auth_mw(
    State(state): State<AppState>,
    mut req: Request,
    next: Next,
) -> AppResult<Response> {
    let token = req
        .headers()
        .get("authorization")
        .and_then(|v| v.to_str().ok())
        .and_then(|s| s.strip_prefix("Bearer "))
        .ok_or(AppError::Unauthorized)?;

    let claims = decode_token(&state.jwt_secret, token).map_err(|_| AppError::Unauthorized)?;
    require_type(&claims, TokenType::Access).map_err(|_| AppError::Unauthorized)?;

    req.extensions_mut().insert::<Claims>(claims);
    Ok(next.run(req).await)
}
