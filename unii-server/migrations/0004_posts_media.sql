-- W5: discover (posts) + media + likes + comments.
--
-- `posts.post_type`: 0 = 动态 (user post), 1 = 活动 (synced activity announcement).
-- `media_files.owner_type`: post | moment | message | activity.

CREATE TABLE posts (
    id            BIGSERIAL PRIMARY KEY,
    author_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    team_id       BIGINT REFERENCES teams(id) ON DELETE SET NULL,
    activity_id   BIGINT REFERENCES activities(id) ON DELETE SET NULL,
    post_type     SMALLINT NOT NULL DEFAULT 0,
    title         VARCHAR(200),
    content       TEXT,
    visibility    VARCHAR(10) NOT NULL DEFAULT 'public',
    like_count    INT NOT NULL DEFAULT 0,
    comment_count INT NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_posts_visibility_created ON posts(visibility, created_at DESC);
CREATE INDEX idx_posts_author ON posts(author_id);

CREATE TABLE media_files (
    id            BIGSERIAL PRIMARY KEY,
    owner_type    VARCHAR(20) NOT NULL,
    owner_id      BIGINT NOT NULL,
    media_type    VARCHAR(10) NOT NULL,
    url           TEXT NOT NULL,
    thumbnail_url TEXT,
    duration      INT,
    size_bytes    BIGINT,
    sort_order    SMALLINT DEFAULT 0,
    created_at    TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_media_owner ON media_files(owner_type, owner_id);

CREATE TABLE post_likes (
    post_id    BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (post_id, user_id)
);

CREATE TABLE post_comments (
    id         BIGSERIAL PRIMARY KEY,
    post_id    BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id    BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_id  BIGINT REFERENCES post_comments(id) ON DELETE CASCADE,
    content    TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_post_comments_post ON post_comments(post_id, created_at);
