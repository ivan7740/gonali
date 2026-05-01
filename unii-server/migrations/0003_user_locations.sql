-- W4: user real-time locations.
--
-- One row per user — UPSERT on report, no history kept (plan §9 privacy).

CREATE TABLE user_locations (
    user_id    BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    location   GEOGRAPHY(Point, 4326) NOT NULL,
    accuracy   REAL,
    speed      REAL,
    bearing    REAL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_user_locations_geo ON user_locations USING GIST(location);
