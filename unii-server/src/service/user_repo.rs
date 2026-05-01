use chrono::NaiveDate;
use sqlx::PgPool;

use crate::{
    dto::user::{UpdateProfileReq, UpdateSettingsReq},
    model::user::UserRow,
};

const USER_COLS: &str = r#"id, phone, password_hash, username, nickname, avatar_url, email,
                  city, occupation, gender, birthday, theme, language, map_engine,
                  location_share_enabled, created_at, updated_at"#;

pub async fn find_by_phone(pool: &PgPool, phone: &str) -> sqlx::Result<Option<UserRow>> {
    sqlx::query_as::<_, UserRow>(&format!("SELECT {USER_COLS} FROM users WHERE phone = $1"))
        .bind(phone)
        .fetch_optional(pool)
        .await
}

pub async fn find_by_id(pool: &PgPool, id: i64) -> sqlx::Result<Option<UserRow>> {
    sqlx::query_as::<_, UserRow>(&format!("SELECT {USER_COLS} FROM users WHERE id = $1"))
        .bind(id)
        .fetch_optional(pool)
        .await
}

pub async fn find_by_username(pool: &PgPool, username: &str) -> sqlx::Result<Option<UserRow>> {
    sqlx::query_as::<_, UserRow>(&format!(
        "SELECT {USER_COLS} FROM users WHERE username = $1"
    ))
    .bind(username)
    .fetch_optional(pool)
    .await
}

pub async fn insert(
    pool: &PgPool,
    phone: &str,
    password_hash: &str,
    username: &str,
) -> sqlx::Result<UserRow> {
    sqlx::query_as::<_, UserRow>(&format!(
        "INSERT INTO users (phone, password_hash, username) VALUES ($1, $2, $3)
         RETURNING {USER_COLS}"
    ))
    .bind(phone)
    .bind(password_hash)
    .bind(username)
    .fetch_one(pool)
    .await
}

/// COALESCE-based partial update — fields with `Some(...)` overwrite, `None` keeps current.
pub async fn update_profile(
    pool: &PgPool,
    id: i64,
    req: &UpdateProfileReq,
) -> sqlx::Result<UserRow> {
    sqlx::query_as::<_, UserRow>(&format!(
        "UPDATE users SET
            username   = COALESCE($2, username),
            nickname   = COALESCE($3, nickname),
            email      = COALESCE($4, email),
            city       = COALESCE($5, city),
            occupation = COALESCE($6, occupation),
            gender     = COALESCE($7, gender),
            birthday   = COALESCE($8, birthday),
            updated_at = NOW()
         WHERE id = $1
         RETURNING {USER_COLS}"
    ))
    .bind(id)
    .bind(req.username.as_deref())
    .bind(req.nickname.as_deref())
    .bind(req.email.as_deref())
    .bind(req.city.as_deref())
    .bind(req.occupation.as_deref())
    .bind(req.gender)
    .bind::<Option<NaiveDate>>(req.birthday)
    .fetch_one(pool)
    .await
}

pub async fn update_settings(
    pool: &PgPool,
    id: i64,
    req: &UpdateSettingsReq,
) -> sqlx::Result<UserRow> {
    sqlx::query_as::<_, UserRow>(&format!(
        "UPDATE users SET
            theme                  = COALESCE($2, theme),
            language               = COALESCE($3, language),
            map_engine             = COALESCE($4, map_engine),
            location_share_enabled = COALESCE($5, location_share_enabled),
            updated_at             = NOW()
         WHERE id = $1
         RETURNING {USER_COLS}"
    ))
    .bind(id)
    .bind(req.theme.as_deref())
    .bind(req.language.as_deref())
    .bind(req.map_engine.as_deref())
    .bind(req.location_share_enabled)
    .fetch_one(pool)
    .await
}

pub async fn update_password(pool: &PgPool, id: i64, new_phc: &str) -> sqlx::Result<u64> {
    let res = sqlx::query("UPDATE users SET password_hash = $2, updated_at = NOW() WHERE id = $1")
        .bind(id)
        .bind(new_phc)
        .execute(pool)
        .await?;
    Ok(res.rows_affected())
}

pub async fn update_avatar(pool: &PgPool, id: i64, url: &str) -> sqlx::Result<UserRow> {
    sqlx::query_as::<_, UserRow>(&format!(
        "UPDATE users SET avatar_url = $2, updated_at = NOW() WHERE id = $1
         RETURNING {USER_COLS}"
    ))
    .bind(id)
    .bind(url)
    .fetch_one(pool)
    .await
}

pub async fn delete(pool: &PgPool, id: i64) -> sqlx::Result<u64> {
    let res = sqlx::query("DELETE FROM users WHERE id = $1")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(res.rows_affected())
}
