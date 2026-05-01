use argon2::{
    password_hash::{rand_core::OsRng, PasswordHash, PasswordHasher, PasswordVerifier, SaltString},
    Argon2,
};

use crate::error::{AppError, AppResult};

pub fn hash(plain: &str) -> AppResult<String> {
    let salt = SaltString::generate(&mut OsRng);
    let argon = Argon2::default();
    let phc = argon.hash_password(plain.as_bytes(), &salt)?.to_string();
    Ok(phc)
}

pub fn verify(plain: &str, phc: &str) -> bool {
    let parsed = match PasswordHash::new(phc) {
        Ok(p) => p,
        Err(_) => return false,
    };
    Argon2::default()
        .verify_password(plain.as_bytes(), &parsed)
        .is_ok()
}

#[allow(dead_code)]
pub fn verify_strict(plain: &str, phc: &str) -> AppResult<()> {
    let parsed = PasswordHash::new(phc)?;
    Argon2::default()
        .verify_password(plain.as_bytes(), &parsed)
        .map_err(|_| AppError::InvalidCredentials)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hash_then_verify() {
        let h = hash("Pa$$w0rd").unwrap();
        assert!(verify("Pa$$w0rd", &h));
    }

    #[test]
    fn verify_wrong() {
        let h = hash("Pa$$w0rd").unwrap();
        assert!(!verify("wrong", &h));
    }

    #[test]
    fn verify_garbage_hash() {
        assert!(!verify("anything", "not-a-phc-string"));
    }
}
