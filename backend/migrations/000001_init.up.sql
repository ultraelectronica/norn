-- Norn initial schema. See docs/DATA_MODEL.md.
-- Forward-only migrations managed by golang-migrate.

CREATE EXTENSION IF NOT EXISTS "pgcrypto";  -- gen_random_uuid()

CREATE TABLE users (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    email       citext UNIQUE NOT NULL,
    cognito_sub text UNIQUE NOT NULL,        -- JWT 'sub' claim
    created_at  timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE providers (
    id       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name     text NOT NULL,                  -- openrouter, openai, anthropic, ollama...
    base_url text NOT NULL,
    kind     text NOT NULL CHECK (kind IN ('openrouter', 'openai_compat', 'anthropic'))
);

CREATE TABLE user_provider_keys (
    user_id        uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider_id    uuid NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
    ciphertext_key bytea   NOT NULL,         -- KMS-encrypted; plaintext never stored
    label          text    NOT NULL,
    created_at     timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, provider_id)
);

CREATE TABLE conversations (
    id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title       text NOT NULL,
    provider_id uuid NOT NULL REFERENCES providers(id),
    model_id    text NOT NULL,
    created_at  timestamptz NOT NULL DEFAULT now(),
    updated_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX conversations_user_updated_idx ON conversations (user_id, updated_at DESC);

CREATE TABLE messages (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id uuid NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role            text NOT NULL CHECK (role IN ('system', 'user', 'assistant')),
    content         text NOT NULL,
    tokens_in       int  NOT NULL DEFAULT 0,
    tokens_out      int  NOT NULL DEFAULT 0,
    created_at      timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX messages_conversation_idx ON messages (conversation_id, created_at);

CREATE TABLE usage (
    user_id        uuid   NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    period         date   NOT NULL,           -- day granularity
    tokens_in      bigint NOT NULL DEFAULT 0,
    tokens_out     bigint NOT NULL DEFAULT 0,
    request_count  int    NOT NULL DEFAULT 0,
    updated_at     timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, period)
);

CREATE TABLE models_cache (
    provider_id     uuid NOT NULL REFERENCES providers(id) ON DELETE CASCADE,
    model_id        text NOT NULL,
    name            text NOT NULL,
    context_window  int  NOT NULL DEFAULT 0,
    is_free         boolean NOT NULL DEFAULT false,
    updated_at      timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (provider_id, model_id)
);

-- Seed the provider catalog.
INSERT INTO providers (name, base_url, kind) VALUES
    ('openrouter', 'https://openrouter.ai/api/v1', 'openrouter'),
    ('openai',     'https://api.openai.com/v1',    'openai_compat'),
    ('anthropic',  'https://api.anthropic.com',    'anthropic'),
    ('ollama',     'http://localhost:11434/v1',    'openai_compat');

-- citext needs the extension too.
CREATE EXTENSION IF NOT EXISTS "citext";
