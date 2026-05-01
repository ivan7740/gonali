use serde::{Deserialize, Serialize};

use crate::model::team::{TeamMemberWithUser, TeamRow};

#[derive(Debug, Deserialize)]
pub struct CreateTeamReq {
    pub name: String,
    pub description: Option<String>,
    pub avatar_url: Option<String>,
    pub member_limit: Option<i32>,
}

#[derive(Debug, Deserialize)]
pub struct JoinTeamReq {
    pub invite_code: String,
}

#[derive(Debug, Deserialize)]
pub struct TransferOwnerReq {
    pub new_owner_id: i64,
}

#[derive(Debug, Serialize)]
pub struct TeamView {
    pub id: i64,
    pub name: String,
    pub avatar_url: Option<String>,
    pub description: Option<String>,
    pub invite_code: String,
    pub owner_id: i64,
    pub member_limit: i32,
    pub member_count: i64,
    pub my_role: Option<i16>,
}

impl TeamView {
    pub fn build(row: &TeamRow, member_count: i64, my_role: Option<i16>) -> Self {
        Self {
            id: row.id,
            name: row.name.clone(),
            avatar_url: row.avatar_url.clone(),
            description: row.description.clone(),
            invite_code: row.invite_code.clone(),
            owner_id: row.owner_id,
            member_limit: row.member_limit,
            member_count,
            my_role,
        }
    }
}

#[derive(Debug, Serialize)]
pub struct MemberView {
    pub user_id: i64,
    pub role: i16,
    pub username: String,
    pub nickname: Option<String>,
    pub avatar_url: Option<String>,
    pub joined_at: Option<chrono::DateTime<chrono::Utc>>,
}

impl From<TeamMemberWithUser> for MemberView {
    fn from(m: TeamMemberWithUser) -> Self {
        Self {
            user_id: m.user_id,
            role: m.role,
            username: m.username,
            nickname: m.nickname,
            avatar_url: m.avatar_url,
            joined_at: m.joined_at,
        }
    }
}

pub fn is_valid_visibility(v: &str) -> bool {
    matches!(v, "public" | "private")
}

pub fn validate_name(s: &str) -> bool {
    let t = s.trim();
    !t.is_empty() && t.chars().count() <= 50
}
