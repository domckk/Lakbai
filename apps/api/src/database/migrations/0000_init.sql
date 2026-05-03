-- Trail Quest — initial schema
-- Requires Postgres 16 + PostGIS 3.4 (postgis/postgis:16-3.4 docker image).

CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS citext;
CREATE EXTENSION IF NOT EXISTS pgcrypto;  -- gen_random_uuid

-- =========================
-- USERS
-- =========================
CREATE TABLE IF NOT EXISTS users (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email           CITEXT UNIQUE NOT NULL,
  username        VARCHAR(32) UNIQUE NOT NULL,
  display_name    VARCHAR(64),
  avatar_url      TEXT,
  password_hash   TEXT,
  xp_total        INTEGER NOT NULL DEFAULT 0,
  level           INTEGER NOT NULL DEFAULT 1,
  home_region     VARCHAR(64),
  role            VARCHAR(16) NOT NULL DEFAULT 'tourist',
  created_at      TIMESTAMPTZ DEFAULT now(),
  last_seen_at    TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS ix_users_xp ON users (xp_total DESC);

-- =========================
-- DESTINATIONS
-- =========================
CREATE TABLE IF NOT EXISTS destinations (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug            VARCHAR(64) UNIQUE NOT NULL,
  name            VARCHAR(128) NOT NULL,
  region          VARCHAR(64),
  country_code    CHAR(2) NOT NULL DEFAULT 'PH',
  bounds          GEOGRAPHY(POLYGON, 4326),
  hero_image_url  TEXT,
  description     TEXT,
  is_active       BOOLEAN DEFAULT TRUE
);

-- =========================
-- PARTNERS
-- =========================
CREATE TABLE IF NOT EXISTS partners (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name              VARCHAR(128) NOT NULL,
  category          VARCHAR(32),
  destination_id    UUID REFERENCES destinations(id) ON DELETE SET NULL,
  geo_point         GEOGRAPHY(POINT, 4326),
  contact_email     CITEXT,
  subscription_tier VARCHAR(16) DEFAULT 'free',
  is_verified       BOOLEAN DEFAULT FALSE,
  created_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_partners_geo ON partners USING GIST (geo_point);

-- =========================
-- PASSPORTS / STAMPS
-- =========================
CREATE TABLE IF NOT EXISTS passports (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  destination_id  UUID NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
  title           VARCHAR(128) NOT NULL,
  theme_color     VARCHAR(7),
  cover_url       TEXT,
  total_stamps    SMALLINT NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS stamps (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  passport_id     UUID NOT NULL REFERENCES passports(id) ON DELETE CASCADE,
  name            VARCHAR(64) NOT NULL,
  art_url         TEXT,
  rarity          VARCHAR(16) DEFAULT 'common'
);

-- =========================
-- QUESTS / CHECKPOINTS
-- =========================
CREATE TABLE IF NOT EXISTS quests (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  destination_id    UUID NOT NULL REFERENCES destinations(id) ON DELETE CASCADE,
  title             VARCHAR(128) NOT NULL,
  summary           TEXT,
  difficulty        SMALLINT NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 5),
  est_duration_min  INTEGER,
  xp_reward         INTEGER NOT NULL DEFAULT 0,
  quest_type        VARCHAR(32) DEFAULT 'landmark',
  starts_at         TIMESTAMPTZ,
  ends_at           TIMESTAMPTZ,
  is_premium        BOOLEAN DEFAULT FALSE,
  partner_id        UUID REFERENCES partners(id) ON DELETE SET NULL,
  cover_image_url   TEXT,
  created_at        TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_quests_dest ON quests (destination_id);

CREATE TABLE IF NOT EXISTS checkpoints (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  quest_id         UUID NOT NULL REFERENCES quests(id) ON DELETE CASCADE,
  sort_order       SMALLINT NOT NULL,
  title            VARCHAR(128) NOT NULL,
  description      TEXT,
  validation_type  VARCHAR(16) NOT NULL DEFAULT 'gps',
  geo_point        GEOGRAPHY(POINT, 4326),
  geo_radius_m     INTEGER DEFAULT 50,
  qr_secret        TEXT,
  trivia_payload   JSONB,
  xp_reward        INTEGER NOT NULL DEFAULT 10,
  stamp_id         UUID REFERENCES stamps(id) ON DELETE SET NULL
);
CREATE INDEX IF NOT EXISTS ix_checkpoints_geo ON checkpoints USING GIST (geo_point);
CREATE INDEX IF NOT EXISTS ix_checkpoints_quest ON checkpoints (quest_id);

-- =========================
-- USER PROGRESS
-- =========================
CREATE TABLE IF NOT EXISTS user_quests (
  user_id       UUID REFERENCES users(id) ON DELETE CASCADE,
  quest_id      UUID REFERENCES quests(id) ON DELETE CASCADE,
  status        VARCHAR(16) DEFAULT 'in_progress',
  started_at    TIMESTAMPTZ DEFAULT now(),
  completed_at  TIMESTAMPTZ,
  PRIMARY KEY (user_id, quest_id)
);

CREATE TABLE IF NOT EXISTS checkpoint_visits (
  id                 BIGSERIAL PRIMARY KEY,
  user_id            UUID NOT NULL,
  checkpoint_id      UUID NOT NULL,
  visited_at         TIMESTAMPTZ DEFAULT now(),
  device_lat         DOUBLE PRECISION,
  device_lng         DOUBLE PRECISION,
  device_accuracy_m  REAL,
  validation_method  VARCHAR(16),
  is_valid           BOOLEAN DEFAULT TRUE,
  flagged_reason     VARCHAR(64),
  CONSTRAINT uq_visit_per_user_checkpoint UNIQUE (user_id, checkpoint_id)
);
CREATE INDEX IF NOT EXISTS ix_visits_user_time ON checkpoint_visits (user_id, visited_at DESC);

CREATE TABLE IF NOT EXISTS user_stamps (
  user_id     UUID NOT NULL,
  stamp_id    UUID NOT NULL,
  earned_at   TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, stamp_id)
);

-- =========================
-- REWARDS
-- =========================
CREATE TABLE IF NOT EXISTS rewards (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  partner_id         UUID REFERENCES partners(id) ON DELETE CASCADE,
  title              VARCHAR(128) NOT NULL,
  description        TEXT,
  reward_type        VARCHAR(16) DEFAULT 'discount',
  value_pct          SMALLINT,
  cost_xp            INTEGER DEFAULT 0,
  required_quest_id  UUID REFERENCES quests(id) ON DELETE SET NULL,
  stock_remaining    INTEGER,
  expires_at         TIMESTAMPTZ,
  created_at         TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_rewards (
  id               BIGSERIAL PRIMARY KEY,
  user_id          UUID NOT NULL,
  reward_id        UUID NOT NULL,
  redemption_code  VARCHAR(16) UNIQUE NOT NULL,
  status           VARCHAR(16) DEFAULT 'issued',
  issued_at        TIMESTAMPTZ DEFAULT now(),
  redeemed_at      TIMESTAMPTZ
);

-- =========================
-- AUTH
-- =========================
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash   TEXT NOT NULL,
  expires_at   TIMESTAMPTZ NOT NULL,
  revoked_at   TIMESTAMPTZ,
  created_at   TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX IF NOT EXISTS ix_refresh_tokens_user ON refresh_tokens (user_id);
