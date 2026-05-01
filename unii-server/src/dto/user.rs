use chrono::NaiveDate;
use serde::{Deserialize, Serialize};

use crate::model::user::UserRow;

/// Full profile snapshot returned by GET/PUT /me.
#[derive(Debug, Serialize)]
pub struct UserProfile {
    pub id: i64,
    pub phone: String,
    pub username: String,
    pub nickname: Option<String>,
    pub avatar_url: Option<String>,
    pub email: Option<String>,
    pub city: Option<String>,
    pub occupation: Option<String>,
    pub gender: Option<i16>,
    pub birthday: Option<NaiveDate>,
    pub theme: Option<String>,
    pub language: Option<String>,
    pub map_engine: Option<String>,
    pub location_share_enabled: Option<bool>,
    pub needs_map_setup: bool,
}

impl From<&UserRow> for UserProfile {
    fn from(u: &UserRow) -> Self {
        Self {
            id: u.id,
            phone: u.phone.clone(),
            username: u.username.clone(),
            nickname: u.nickname.clone(),
            avatar_url: u.avatar_url.clone(),
            email: u.email.clone(),
            city: u.city.clone(),
            occupation: u.occupation.clone(),
            gender: u.gender,
            birthday: u.birthday,
            theme: u.theme.clone(),
            language: u.language.clone(),
            map_engine: u.map_engine.clone(),
            location_share_enabled: u.location_share_enabled,
            needs_map_setup: u.needs_map_setup(),
        }
    }
}

/// Partial profile update. All fields optional; null/missing leaves DB value unchanged.
#[derive(Debug, Default, Deserialize)]
pub struct UpdateProfileReq {
    pub username: Option<String>,
    pub nickname: Option<String>,
    pub email: Option<String>,
    pub city: Option<String>,
    pub occupation: Option<String>,
    pub gender: Option<i16>,
    pub birthday: Option<NaiveDate>,
}

#[derive(Debug, Default, Deserialize)]
pub struct UpdateSettingsReq {
    pub theme: Option<String>,
    pub language: Option<String>,
    pub map_engine: Option<String>,
    pub location_share_enabled: Option<bool>,
}

#[derive(Debug, Deserialize)]
pub struct ChangePasswordReq {
    pub old_password: String,
    pub new_password: String,
}

pub fn is_valid_theme(s: &str) -> bool {
    matches!(s, "system" | "light" | "dark")
}

pub fn is_valid_language(s: &str) -> bool {
    matches!(s, "zh" | "en")
}

pub fn is_valid_map_engine(s: &str) -> bool {
    matches!(s, "amap" | "osm")
}

pub fn is_valid_gender(g: i16) -> bool {
    matches!(g, 0..=2)
}

/// Loose RFC-5322 sanity check — reject obvious garbage but don't try to be exhaustive.
pub fn is_plausible_email(s: &str) -> bool {
    let bytes = s.as_bytes();
    if bytes.is_empty() || bytes.len() > 100 {
        return false;
    }
    let at = match s.find('@') {
        Some(i) => i,
        None => return false,
    };
    if at == 0 || at == s.len() - 1 {
        return false;
    }
    let domain = &s[at + 1..];
    domain.contains('.') && !domain.starts_with('.') && !domain.ends_with('.')
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn theme_values() {
        assert!(is_valid_theme("system"));
        assert!(is_valid_theme("dark"));
        assert!(!is_valid_theme("neon"));
    }

    #[test]
    fn email_plausibility() {
        assert!(is_plausible_email("a@b.co"));
        assert!(is_plausible_email("foo.bar+1@example.com"));
        assert!(!is_plausible_email("nodomain"));
        assert!(!is_plausible_email("@nope.com"));
        assert!(!is_plausible_email("a@b"));
        assert!(!is_plausible_email("a@.com"));
    }

    #[test]
    fn map_engine_values() {
        assert!(is_valid_map_engine("amap"));
        assert!(is_valid_map_engine("osm"));
        assert!(!is_valid_map_engine("google"));
    }
}
