-- W6: team moments + 1:1 chat conversations/messages with read marks.

CREATE TABLE moments (
    id         BIGSERIAL PRIMARY KEY,
    team_id    BIGINT NOT NULL REFERENCES teams(id) ON DELETE CASCADE,
    author_id  BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content    TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_moments_team_time ON moments(team_id, created_at DESC);

CREATE TABLE chat_conversations (
    id              BIGSERIAL PRIMARY KEY,
    user_a_id       BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    user_b_id       BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    last_message_id BIGINT,
    updated_at      TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE (user_a_id, user_b_id),
    CHECK (user_a_id < user_b_id)
);

CREATE TABLE chat_messages (
    id              BIGSERIAL PRIMARY KEY,
    conversation_id BIGINT NOT NULL REFERENCES chat_conversations(id) ON DELETE CASCADE,
    sender_id       BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    msg_type        VARCHAR(10) NOT NULL,
    content         TEXT,
    media_url       TEXT,
    duration        INT,
    is_recalled     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX idx_chat_msg_conv_time ON chat_messages(conversation_id, created_at DESC);

CREATE TABLE chat_read_marks (
    conversation_id  BIGINT NOT NULL,
    user_id          BIGINT NOT NULL,
    last_read_msg_id BIGINT NOT NULL,
    PRIMARY KEY (conversation_id, user_id)
);
