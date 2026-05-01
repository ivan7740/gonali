use serde::{Deserialize, Serialize};

#[derive(Debug, Deserialize)]
pub struct RegisterReq {
    pub phone: String,
    pub password: String,
    pub username: String,
}

#[derive(Debug, Deserialize)]
pub struct LoginReq {
    pub phone: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
pub struct RefreshReq {
    pub refresh_token: String,
}

#[derive(Debug, Serialize)]
pub struct TokenResp {
    pub access_token: String,
    pub refresh_token: String,
    pub token_type: &'static str,
    pub expires_in: i64,
    pub user: UserPublic,
}

#[derive(Debug, Serialize)]
pub struct AccessResp {
    pub access_token: String,
    pub token_type: &'static str,
    pub expires_in: i64,
}

#[derive(Debug, Serialize)]
pub struct UserPublic {
    pub id: i64,
    pub phone: String,
    pub username: String,
    pub nickname: Option<String>,
    pub avatar_url: Option<String>,
    pub needs_map_setup: bool,
}

/// `1[3-9]xxxxxxxxx` — mainland CN mobile.
pub fn is_valid_phone(s: &str) -> bool {
    let bytes = s.as_bytes();
    if bytes.len() != 11 || bytes[0] != b'1' || !(b'3'..=b'9').contains(&bytes[1]) {
        return false;
    }
    bytes[2..].iter().all(|c| c.is_ascii_digit())
}

/// ≥8 chars, contains at least one letter and one digit.
pub fn is_valid_password(s: &str) -> bool {
    if s.len() < 8 || s.len() > 64 {
        return false;
    }
    let has_letter = s.chars().any(|c| c.is_ascii_alphabetic());
    let has_digit = s.chars().any(|c| c.is_ascii_digit());
    has_letter && has_digit
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn phone_valid() {
        assert!(is_valid_phone("13800001111"));
        assert!(is_valid_phone("19999999999"));
    }

    #[test]
    fn phone_invalid() {
        assert!(!is_valid_phone(""));
        assert!(!is_valid_phone("12345678901"));
        assert!(!is_valid_phone("23800001111"));
        assert!(!is_valid_phone("138000011112"));
        assert!(!is_valid_phone("1380000111a"));
    }

    #[test]
    fn password_rules() {
        assert!(is_valid_password("Pa$$w0rd"));
        assert!(is_valid_password("abcd1234"));
        assert!(!is_valid_password("short1"));
        assert!(!is_valid_password("nodigitsxx"));
        assert!(!is_valid_password("12345678"));
    }
}
