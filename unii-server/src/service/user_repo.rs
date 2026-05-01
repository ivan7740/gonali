use sqlx::PgPool;

use crate::model::user::UserRow;

pub async fn find_by_phone(pool: &PgPool, phone: &str) -> sqlx::Result<Option<UserRow>> {
    sqlx::query_as::<_, UserRow>(
        r#"SELECT id, phone, password_hash, username, nickname, avatar_url, email,
                  city, occupation, gender, birthday, theme, language, map_engine,
                  location_share_enabled, created_at, updated_at
           FROM users WHERE phone = $1"#,
    )
    .bind(phone)
    .fetch_optional(pool)
    .await
}

pub async fn find_by_id(pool: &PgPool, id: i64) -> sqlx::Result<Option<UserRow>> {
    sqlx::query_as::<_, UserRow>(
        r#"SELECT id, phone, password_hash, username, nickname, avatar_url, email,
                  city, occupation, gender, birthday, theme, language, map_engine,
                  location_share_enabled, created_at, updated_at
           FROM users WHERE id = $1"#,
    )
    .bind(id)
    .fetch_optional(pool)
    .await
}

pub async fn find_by_username(pool: &PgPool, username: &str) -> sqlx::Result<Option<UserRow>> {
    sqlx::query_as::<_, UserRow>(
        r#"SELECT id, phone, password_hash, username, nickname, avatar_url, email,
                  city, occupation, gender, birthday, theme, language, map_engine,
                  location_share_enabled, created_at, updated_at
           FROM users WHERE username = $1"#,
    )
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
    sqlx::query_as::<_, UserRow>(
        r#"INSERT INTO users (phone, password_hash, username)
           VALUES ($1, $2, $3)
           RETURNING id, phone, password_hash, username, nickname, avatar_url, email,
                     city, occupation, gender, birthday, theme, language, map_engine,
                     location_share_enabled, created_at, updated_at"#,
    )
    .bind(phone)
    .bind(password_hash)
    .bind(username)
    .fetch_one(pool)
    .await
}
