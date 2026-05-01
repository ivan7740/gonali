-- W3 schema: teams, team_members, activities. Activities use PostGIS GEOGRAPHY
-- (already enabled in 0001) so spatial queries in W4+ can be added later.

CREATE TABLE teams (
    id           BIGSERIAL PRIMARY KEY,
    name         VARCHAR(50) NOT NULL,
    avatar_url   TEXT,
    description  TEXT,
    invite_code  CHAR(6) UNIQUE NOT NULL,
    owner_id     BIGINT NOT NULL REFERENCES users(id),
    member_limit INT NOT NULL DEFAULT 30,
    created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_teams_owner ON teams(owner_id);

CREATE TABLE team_members (
    team_id    BIGINT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role       SMALLINT NOT NULL DEFAULT 0, -- 0 member, 1 owner
    joined_at  TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (team_id, user_id)
);

CREATE INDEX idx_team_members_user ON team_members(user_id);

CREATE TABLE activities (
    id            BIGSERIAL PRIMARY KEY,
    team_id       BIGINT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    creator_id    BIGINT NOT NULL REFERENCES users(id),
    title         VARCHAR(100) NOT NULL,
    location      GEOGRAPHY(Point, 4326) NOT NULL,
    location_name VARCHAR(200),
    start_time    TIMESTAMPTZ,
    end_time      TIMESTAMPTZ,
    content       TEXT,
    notice        TEXT,
    visibility    VARCHAR(10) NOT NULL,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_activities_team ON activities(team_id);
CREATE INDEX idx_activities_location ON activities USING GIST(location);
