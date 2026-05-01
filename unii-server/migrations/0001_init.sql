-- W1 initial schema: PostGIS extension + users table.
-- Subsequent tables (teams, activities, posts, ...) land in later migrations.

CREATE EXTENSION IF NOT EXISTS postgis;

CREATE TABLE users (
    id                       BIGSERIAL PRIMARY KEY,
    phone                    VARCHAR(20) UNIQUE NOT NULL,
    password_hash            TEXT NOT NULL,
    username                 VARCHAR(50) UNIQUE NOT NULL,
    nickname                 VARCHAR(50),
    avatar_url               TEXT,
    email                    VARCHAR(100),
    city                     VARCHAR(50),
    occupation               VARCHAR(50),
    gender                   SMALLINT,
    birthday                 DATE,
    theme                    VARCHAR(10) DEFAULT 'system',
    language                 VARCHAR(10) DEFAULT 'zh',
    map_engine               VARCHAR(10),
    location_share_enabled   BOOLEAN DEFAULT TRUE,
    created_at               TIMESTAMPTZ DEFAULT NOW(),
    updated_at               TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_username ON users(username);
