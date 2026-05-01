use axum::Json;
use serde::Serialize;

#[derive(Serialize)]
pub struct ApiResp<T> {
    pub code: i32,
    pub msg: &'static str,
    pub data: T,
}

impl<T: Serialize> ApiResp<T> {
    pub fn ok(data: T) -> Json<Self> {
        Json(Self {
            code: 0,
            msg: "ok",
            data,
        })
    }
}
