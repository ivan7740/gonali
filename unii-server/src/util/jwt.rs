use chrono::Utc;
use jsonwebtoken::{decode, encode, DecodingKey, EncodingKey, Header, Validation};
use serde::{Deserialize, Serialize};

use crate::error::{AppError, AppResult};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Claims {
    pub sub: i64,
    pub exp: usize,
    pub iat: usize,
    pub typ: TokenType,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum TokenType {
    Access,
    Refresh,
}

pub fn issue_access(secret: &str, uid: i64, ttl_secs: i64) -> AppResult<String> {
    issue(secret, uid, ttl_secs, TokenType::Access)
}

pub fn issue_refresh(secret: &str, uid: i64, ttl_secs: i64) -> AppResult<String> {
    issue(secret, uid, ttl_secs, TokenType::Refresh)
}

fn issue(secret: &str, uid: i64, ttl_secs: i64, typ: TokenType) -> AppResult<String> {
    let now = Utc::now().timestamp();
    let exp_i = now.saturating_add(ttl_secs);
    let exp = if exp_i < 0 { 0_usize } else { exp_i as usize };
    let claims = Claims {
        sub: uid,
        exp,
        iat: now as usize,
        typ,
    };
    let token = encode(
        &Header::default(),
        &claims,
        &EncodingKey::from_secret(secret.as_bytes()),
    )?;
    Ok(token)
}

pub fn decode_token(secret: &str, token: &str) -> AppResult<Claims> {
    let data = decode::<Claims>(
        token,
        &DecodingKey::from_secret(secret.as_bytes()),
        &Validation::default(),
    )?;
    Ok(data.claims)
}

pub fn require_type(claims: &Claims, expect: TokenType) -> AppResult<()> {
    if claims.typ != expect {
        return Err(AppError::Unauthorized);
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    const SECRET: &str = "test-secret-test-secret-test-secret-1234";

    #[test]
    fn issue_then_decode() {
        let t = issue_access(SECRET, 42, 60).unwrap();
        let c = decode_token(SECRET, &t).unwrap();
        assert_eq!(c.sub, 42);
        assert_eq!(c.typ, TokenType::Access);
    }

    #[test]
    fn decode_expired() {
        // jsonwebtoken's default Validation has 60s leeway; push well past it.
        let t = issue_access(SECRET, 42, -300).unwrap();
        assert!(decode_token(SECRET, &t).is_err());
    }

    #[test]
    fn decode_tampered() {
        let mut t = issue_access(SECRET, 42, 60).unwrap();
        // flip last char
        let last = t.pop().unwrap();
        let next = if last == 'a' { 'b' } else { 'a' };
        t.push(next);
        assert!(decode_token(SECRET, &t).is_err());
    }

    #[test]
    fn require_type_mismatch() {
        let t = issue_refresh(SECRET, 1, 60).unwrap();
        let c = decode_token(SECRET, &t).unwrap();
        assert!(require_type(&c, TokenType::Access).is_err());
    }
}
