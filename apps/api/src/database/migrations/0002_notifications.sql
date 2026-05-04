-- Trail Quest — notifications system

CREATE TABLE IF NOT EXISTS notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type       VARCHAR(32) NOT NULL,
  title      VARCHAR(128) NOT NULL,
  body       TEXT NOT NULL,
  icon       VARCHAR(8),
  is_read    BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE INDEX IF NOT EXISTS ix_notifications_user   ON notifications (user_id);
CREATE INDEX IF NOT EXISTS ix_notifications_unread ON notifications (user_id, is_read) WHERE is_read = false;
