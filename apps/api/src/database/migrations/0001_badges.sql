-- Trail Quest — badges system

CREATE TABLE IF NOT EXISTS badges (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  key              VARCHAR(64) UNIQUE NOT NULL,
  name             VARCHAR(128) NOT NULL,
  description      TEXT,
  icon             VARCHAR(16) NOT NULL,
  tier             VARCHAR(16) NOT NULL DEFAULT 'bronze',
  condition_type   VARCHAR(32) NOT NULL,
  condition_value  INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS user_badges (
  user_id   UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  badge_id  UUID NOT NULL REFERENCES badges(id) ON DELETE CASCADE,
  earned_at TIMESTAMPTZ DEFAULT now(),
  PRIMARY KEY (user_id, badge_id)
);

CREATE INDEX IF NOT EXISTS ix_user_badges_user ON user_badges (user_id);

-- Seed badge definitions
INSERT INTO badges (key, name, description, icon, tier, condition_type, condition_value) VALUES
  ('first_steps',       'First Steps',        'Scan your very first checkpoint',              '👣', 'bronze',    'first_checkin',     1),
  ('trail_blazer',      'Trail Blazer',       'Complete 10 checkpoints',                      '🔥', 'bronze',    'checkpoints_total', 10),
  ('explorer',          'Explorer',           'Complete 25 checkpoints',                      '🧭', 'silver',    'checkpoints_total', 25),
  ('quest_starter',     'Quest Starter',      'Complete your first quest',                    '⚡', 'bronze',    'quests_completed',  1),
  ('quest_master',      'Quest Master',       'Complete 5 quests',                            '🏆', 'gold',      'quests_completed',  5),
  ('stamp_collector',   'Stamp Collector',    'Collect 3 stamps in your passport',            '📮', 'bronze',    'stamps_collected',  3),
  ('ilocos_explorer',   'Ilocos Explorer',    'Complete the Ilocos Norte Heritage Passport',  '🌊', 'silver',    'stamps_collected',  5),
  ('rising_explorer',   'Rising Explorer',    'Reach Level 5',                               '📈', 'silver',    'level_reached',     5),
  ('seasoned_traveler', 'Seasoned Traveler',  'Reach Level 10',                              '🎖️','gold',      'level_reached',     10),
  ('xp_hunter',         'XP Hunter',          'Accumulate 500 total XP',                     '⭐', 'bronze',    'xp_total',          500)
ON CONFLICT (key) DO NOTHING;
