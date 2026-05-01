use axum::{
    extract::{Path, State},
    routing::{delete, get, post},
    Extension, Json, Router,
};
use tracing::{info, instrument};

use crate::{
    dto::{
        common::ApiResp,
        team::{validate_name, CreateTeamReq, JoinTeamReq, MemberView, TeamView, TransferOwnerReq},
    },
    error::{AppError, AppResult},
    service::team_repo,
    state::AppState,
    util::{invite_code, jwt::Claims},
};

pub fn routes() -> Router<AppState> {
    Router::new()
        .route("/", post(create))
        .route("/mine", get(list_mine))
        .route("/join", post(join))
        .route("/:id", get(detail).delete(disband))
        .route("/:id/members", get(list_members))
        .route("/:id/members/me", delete(leave))
        .route("/:id/members/:uid", delete(kick))
        .route("/:id/transfer", post(transfer))
}

const OWNER_ROLE: i16 = 1;
const MEMBER_ROLE: i16 = 0;

#[instrument(skip(state, body))]
async fn create(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<CreateTeamReq>,
) -> AppResult<Json<ApiResp<TeamView>>> {
    if !validate_name(&body.name) {
        return Err(AppError::validation("name must be 1-50 chars"));
    }
    let limit = body.member_limit.unwrap_or(30);
    if !(2..=500).contains(&limit) {
        return Err(AppError::validation("member_limit must be 2-500"));
    }

    // Retry a few times in the unlikely event of an invite_code collision.
    let mut last_err: Option<sqlx::Error> = None;
    for _ in 0..5 {
        let code = invite_code::generate();
        match team_repo::insert_team(
            &state.db,
            claims.sub,
            body.name.trim(),
            body.description.as_deref(),
            body.avatar_url.as_deref(),
            &code,
            limit,
        )
        .await
        {
            Ok(team) => {
                team_repo::add_member(&state.db, team.id, claims.sub, OWNER_ROLE).await?;
                let count = team_repo::member_count(&state.db, team.id).await?;
                info!(team_id = team.id, owner_id = claims.sub, "team created");
                return Ok(ApiResp::ok(TeamView::build(&team, count, Some(OWNER_ROLE))));
            }
            Err(e) if is_unique_violation(&e) => {
                last_err = Some(e);
                continue;
            }
            Err(e) => return Err(e.into()),
        }
    }
    Err(last_err
        .map(AppError::Sqlx)
        .unwrap_or_else(|| AppError::Internal("invite_code collision".into())))
}

#[instrument(skip(state))]
async fn list_mine(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
) -> AppResult<Json<ApiResp<Vec<TeamView>>>> {
    let teams = team_repo::list_mine(&state.db, claims.sub).await?;
    let mut out = Vec::with_capacity(teams.len());
    for t in teams {
        let count = team_repo::member_count(&state.db, t.id).await?;
        let role = team_repo::role_of(&state.db, t.id, claims.sub).await?;
        out.push(TeamView::build(&t, count, role));
    }
    Ok(ApiResp::ok(out))
}

#[instrument(skip(state))]
async fn detail(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<i64>,
) -> AppResult<Json<ApiResp<TeamView>>> {
    let role = team_repo::role_of(&state.db, id, claims.sub).await?;
    if role.is_none() {
        return Err(AppError::NotFound("team".into()));
    }
    let team = team_repo::find_by_id(&state.db, id)
        .await?
        .ok_or_else(|| AppError::NotFound("team".into()))?;
    let count = team_repo::member_count(&state.db, id).await?;
    Ok(ApiResp::ok(TeamView::build(&team, count, role)))
}

#[instrument(skip(state, body))]
async fn join(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Json(body): Json<JoinTeamReq>,
) -> AppResult<Json<ApiResp<TeamView>>> {
    let code = body.invite_code.trim().to_uppercase();
    let team = team_repo::find_by_invite_code(&state.db, &code)
        .await?
        .ok_or_else(|| AppError::NotFound("invite code".into()))?;

    let count = team_repo::member_count(&state.db, team.id).await?;
    if count >= team.member_limit as i64 {
        return Err(AppError::conflict("team is full"));
    }
    if team_repo::role_of(&state.db, team.id, claims.sub)
        .await?
        .is_some()
    {
        return Err(AppError::conflict("already a member"));
    }
    team_repo::add_member(&state.db, team.id, claims.sub, MEMBER_ROLE).await?;
    let count = count + 1;
    info!(team_id = team.id, user_id = claims.sub, "joined team");
    Ok(ApiResp::ok(TeamView::build(
        &team,
        count,
        Some(MEMBER_ROLE),
    )))
}

#[instrument(skip(state))]
async fn list_members(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<i64>,
) -> AppResult<Json<ApiResp<Vec<MemberView>>>> {
    if team_repo::role_of(&state.db, id, claims.sub)
        .await?
        .is_none()
    {
        return Err(AppError::NotFound("team".into()));
    }
    let members = team_repo::list_members(&state.db, id).await?;
    Ok(ApiResp::ok(members.into_iter().map(Into::into).collect()))
}

#[instrument(skip(state))]
async fn leave(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<i64>,
) -> AppResult<Json<ApiResp<&'static str>>> {
    let team = team_repo::find_by_id(&state.db, id)
        .await?
        .ok_or_else(|| AppError::NotFound("team".into()))?;
    if team.owner_id == claims.sub {
        return Err(AppError::validation(
            "owner cannot leave; transfer ownership or disband instead",
        ));
    }
    let n = team_repo::remove_member(&state.db, id, claims.sub).await?;
    if n == 0 {
        return Err(AppError::NotFound("membership".into()));
    }
    Ok(ApiResp::ok("ok"))
}

#[instrument(skip(state))]
async fn kick(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path((id, uid)): Path<(i64, i64)>,
) -> AppResult<Json<ApiResp<&'static str>>> {
    let team = team_repo::find_by_id(&state.db, id)
        .await?
        .ok_or_else(|| AppError::NotFound("team".into()))?;
    if team.owner_id != claims.sub {
        return Err(AppError::Unauthorized);
    }
    if uid == team.owner_id {
        return Err(AppError::validation("cannot remove owner"));
    }
    let n = team_repo::remove_member(&state.db, id, uid).await?;
    if n == 0 {
        return Err(AppError::NotFound("membership".into()));
    }
    info!(team_id = id, user_id = uid, "member kicked");
    Ok(ApiResp::ok("ok"))
}

#[instrument(skip(state, body))]
async fn transfer(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<i64>,
    Json(body): Json<TransferOwnerReq>,
) -> AppResult<Json<ApiResp<&'static str>>> {
    let team = team_repo::find_by_id(&state.db, id)
        .await?
        .ok_or_else(|| AppError::NotFound("team".into()))?;
    if team.owner_id != claims.sub {
        return Err(AppError::Unauthorized);
    }
    if body.new_owner_id == claims.sub {
        return Err(AppError::validation("new owner is already current owner"));
    }
    if team_repo::role_of(&state.db, id, body.new_owner_id)
        .await?
        .is_none()
    {
        return Err(AppError::validation("new owner must be a team member"));
    }
    team_repo::transfer_owner(&state.db, id, body.new_owner_id).await?;
    info!(
        team_id = id,
        new_owner_id = body.new_owner_id,
        "ownership transferred"
    );
    Ok(ApiResp::ok("ok"))
}

#[instrument(skip(state))]
async fn disband(
    State(state): State<AppState>,
    Extension(claims): Extension<Claims>,
    Path(id): Path<i64>,
) -> AppResult<Json<ApiResp<&'static str>>> {
    let team = team_repo::find_by_id(&state.db, id)
        .await?
        .ok_or_else(|| AppError::NotFound("team".into()))?;
    if team.owner_id != claims.sub {
        return Err(AppError::Unauthorized);
    }
    team_repo::delete_team(&state.db, id).await?;
    info!(team_id = id, "team disbanded");
    Ok(ApiResp::ok("ok"))
}

fn is_unique_violation(e: &sqlx::Error) -> bool {
    if let sqlx::Error::Database(db) = e {
        // PostgreSQL unique_violation
        return db.code().as_deref() == Some("23505");
    }
    false
}
