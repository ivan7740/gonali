use std::{env, path::PathBuf};

use anyhow::{anyhow, Context, Result};

#[derive(Debug, Clone)]
pub struct Config {
    pub database_url: String,
    pub jwt_secret: String,
    pub port: u16,
    pub access_ttl_secs: i64,
    pub refresh_ttl_secs: i64,
    pub upload_dir: PathBuf,
    pub public_base_url: String,
}

const PLACEHOLDER_SECRET: &str = "replace_me_with_a_64_byte_hex_string";

impl Config {
    pub fn from_env() -> Result<Self> {
        let database_url = env::var("DATABASE_URL").context("DATABASE_URL is required")?;
        let jwt_secret = env::var("JWT_SECRET").context("JWT_SECRET is required")?;
        if jwt_secret == PLACEHOLDER_SECRET {
            return Err(anyhow!(
                "JWT_SECRET is the placeholder value; generate one with `openssl rand -hex 64`"
            ));
        }
        if jwt_secret.len() < 32 {
            return Err(anyhow!("JWT_SECRET must be at least 32 chars"));
        }

        let port = env::var("SERVER_PORT")
            .ok()
            .and_then(|s| s.parse().ok())
            .unwrap_or(8080);

        let upload_dir = env::var("UPLOAD_DIR")
            .map(PathBuf::from)
            .unwrap_or_else(|_| PathBuf::from("./uploads"));

        let public_base_url =
            env::var("PUBLIC_BASE_URL").unwrap_or_else(|_| format!("http://localhost:{port}"));

        Ok(Self {
            database_url,
            jwt_secret,
            port,
            access_ttl_secs: 2 * 60 * 60,        // 2h
            refresh_ttl_secs: 30 * 24 * 60 * 60, // 30d
            upload_dir,
            public_base_url,
        })
    }
}
