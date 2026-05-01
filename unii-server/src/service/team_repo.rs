use sqlx::PgPool;

use crate::model::team::{TeamMemberWithUser, TeamRow};

const TEAM_COLS: &str =
    "id, name, avatar_url, description, invite_code, owner_id, member_limit, created_at";

pub async fn insert_team(
    pool: &PgPool,
    owner_id: i64,
    name: &str,
    description: Option<&str>,
    avatar_url: Option<&str>,
    invite_code: &str,
    member_limit: i32,
) -> sqlx::Result<TeamRow> {
    sqlx::query_as::<_, TeamRow>(&format!(
        "INSERT INTO teams (name, description, avatar_url, invite_code, owner_id, member_limit)
         VALUES ($1, $2, $3, $4, $5, $6)
         RETURNING {TEAM_COLS}"
    ))
    .bind(name)
    .bind(description)
    .bind(avatar_url)
    .bind(invite_code)
    .bind(owner_id)
    .bind(member_limit)
    .fetch_one(pool)
    .await
}

pub async fn add_member(pool: &PgPool, team_id: i64, user_id: i64, role: i16) -> sqlx::Result<()> {
    sqlx::query(
        "INSERT INTO team_members (team_id, user_id, role) VALUES ($1, $2, $3)
         ON CONFLICT DO NOTHING",
    )
    .bind(team_id)
    .bind(user_id)
    .bind(role)
    .execute(pool)
    .await?;
    Ok(())
}

pub async fn find_by_id(pool: &PgPool, id: i64) -> sqlx::Result<Option<TeamRow>> {
    sqlx::query_as::<_, TeamRow>(&format!("SELECT {TEAM_COLS} FROM teams WHERE id = $1"))
        .bind(id)
        .fetch_optional(pool)
        .await
}

pub async fn find_by_invite_code(pool: &PgPool, code: &str) -> sqlx::Result<Option<TeamRow>> {
    sqlx::query_as::<_, TeamRow>(&format!(
        "SELECT {TEAM_COLS} FROM teams WHERE invite_code = $1"
    ))
    .bind(code)
    .fetch_optional(pool)
    .await
}

pub async fn list_mine(pool: &PgPool, user_id: i64) -> sqlx::Result<Vec<TeamRow>> {
    sqlx::query_as::<_, TeamRow>(&format!(
        "SELECT {} FROM teams t \
         JOIN team_members m ON m.team_id = t.id \
         WHERE m.user_id = $1 \
         ORDER BY t.created_at DESC",
        TEAM_COLS
            .split(", ")
            .map(|c| format!("t.{c}"))
            .collect::<Vec<_>>()
            .join(", ")
    ))
    .bind(user_id)
    .fetch_all(pool)
    .await
}

pub async fn member_count(pool: &PgPool, team_id: i64) -> sqlx::Result<i64> {
    let row: (i64,) = sqlx::query_as("SELECT COUNT(*) FROM team_members WHERE team_id = $1")
        .bind(team_id)
        .fetch_one(pool)
        .await?;
    Ok(row.0)
}

pub async fn role_of(pool: &PgPool, team_id: i64, user_id: i64) -> sqlx::Result<Option<i16>> {
    let row: Option<(i16,)> =
        sqlx::query_as("SELECT role FROM team_members WHERE team_id = $1 AND user_id = $2")
            .bind(team_id)
            .bind(user_id)
            .fetch_optional(pool)
            .await?;
    Ok(row.map(|r| r.0))
}

pub async fn list_members(pool: &PgPool, team_id: i64) -> sqlx::Result<Vec<TeamMemberWithUser>> {
    sqlx::query_as::<_, TeamMemberWithUser>(
        "SELECT m.user_id, m.role, m.joined_at,
                u.username, u.nickname, u.avatar_url
         FROM team_members m
         JOIN users u ON u.id = m.user_id
         WHERE m.team_id = $1
         ORDER BY m.role DESC, m.joined_at ASC",
    )
    .bind(team_id)
    .fetch_all(pool)
    .await
}

pub async fn remove_member(pool: &PgPool, team_id: i64, user_id: i64) -> sqlx::Result<u64> {
    let res = sqlx::query("DELETE FROM team_members WHERE team_id = $1 AND user_id = $2")
        .bind(team_id)
        .bind(user_id)
        .execute(pool)
        .await?;
    Ok(res.rows_affected())
}

pub async fn delete_team(pool: &PgPool, id: i64) -> sqlx::Result<u64> {
    let res = sqlx::query("DELETE FROM teams WHERE id = $1")
        .bind(id)
        .execute(pool)
        .await?;
    Ok(res.rows_affected())
}

pub async fn transfer_owner(pool: &PgPool, team_id: i64, new_owner_id: i64) -> sqlx::Result<()> {
    let mut tx = pool.begin().await?;
    sqlx::query("UPDATE teams SET owner_id = $1 WHERE id = $2")
        .bind(new_owner_id)
        .bind(team_id)
        .execute(&mut *tx)
        .await?;
    sqlx::query(
        "UPDATE team_members SET role = CASE
            WHEN user_id = $1 THEN 1
            ELSE 0
         END
         WHERE team_id = $2",
    )
    .bind(new_owner_id)
    .bind(team_id)
    .execute(&mut *tx)
    .await?;
    tx.commit().await
}
