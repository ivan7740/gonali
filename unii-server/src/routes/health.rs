use axum::Json;

use crate::dto::common::ApiResp;

pub async fn healthz() -> Json<ApiResp<&'static str>> {
    ApiResp::ok("healthy")
}
