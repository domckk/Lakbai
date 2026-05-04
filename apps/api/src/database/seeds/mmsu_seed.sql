-- ============================================================
-- Seed: Mariano Marcos State University — Batac City, Ilocos Norte
--
-- 3 quests · 9 checkpoints total · 1 000 m GPS radius per checkpoint
-- 3 passport stamps linked to the final checkpoint of each quest
--
-- Safe to re-run: uses ON CONFLICT / NOT EXISTS guards throughout.
-- Run via Supabase SQL editor or psql.
-- ============================================================

-- ── 1. Destination ───────────────────────────────────────────────────────
INSERT INTO destinations (slug, name, region, country_code, description, is_active)
VALUES (
  'batac',
  'Batac City',
  'Ilocos Norte',
  'PH',
  'Home to the Marcos Museum, Mariano Marcos State University, and rich heritage sites in northern Ilocos Norte.',
  true
)
ON CONFLICT (slug) DO UPDATE
  SET name        = EXCLUDED.name,
      description = EXCLUDED.description,
      is_active   = EXCLUDED.is_active;

-- ── 2. Passport ──────────────────────────────────────────────────────────
INSERT INTO passports (destination_id, title, theme_color, total_stamps)
SELECT d.id, 'Batac City Passport', '#2E5A27', 0   -- total_stamps updated below
FROM destinations d
WHERE d.slug = 'batac'
  AND NOT EXISTS (
    SELECT 1 FROM passports p
    JOIN destinations d2 ON p.destination_id = d2.id
    WHERE d2.slug = 'batac'
  );

-- ── 3. Stamps ────────────────────────────────────────────────────────────
INSERT INTO stamps (passport_id, name, rarity)
SELECT p.id, 'MMSU Explorer', 'common'
FROM passports p JOIN destinations d ON p.destination_id = d.id
WHERE d.slug = 'batac'
  AND NOT EXISTS (SELECT 1 FROM stamps s WHERE s.passport_id = p.id AND s.name = 'MMSU Explorer');

INSERT INTO stamps (passport_id, name, rarity)
SELECT p.id, 'Academic Trailblazer', 'uncommon'
FROM passports p JOIN destinations d ON p.destination_id = d.id
WHERE d.slug = 'batac'
  AND NOT EXISTS (SELECT 1 FROM stamps s WHERE s.passport_id = p.id AND s.name = 'Academic Trailblazer');

INSERT INTO stamps (passport_id, name, rarity)
SELECT p.id, 'Founder''s Spirit', 'rare'
FROM passports p JOIN destinations d ON p.destination_id = d.id
WHERE d.slug = 'batac'
  AND NOT EXISTS (SELECT 1 FROM stamps s WHERE s.passport_id = p.id AND s.name = 'Founder''s Spirit');

-- Keep total_stamps accurate
UPDATE passports
SET    total_stamps = (SELECT COUNT(*) FROM stamps s WHERE s.passport_id = passports.id)
FROM   destinations d
WHERE  passports.destination_id = d.id AND d.slug = 'batac';


-- ════════════════════════════════════════════════════════════════════════
-- QUEST 1 — MMSU Campus Explorer  (1 ★ | landmark | 300 XP total)
-- ════════════════════════════════════════════════════════════════════════
INSERT INTO quests (destination_id, title, summary, difficulty, est_duration_min, xp_reward, quest_type)
SELECT d.id,
  'MMSU Campus Explorer',
  'Walk the grounds of Mariano Marcos State University — one of Ilocos Norte''s premier state universities. Hit three iconic spots on campus to complete this quest.',
  1, 20, 75, 'landmark'
FROM destinations d
WHERE d.slug = 'batac'
  AND NOT EXISTS (
    SELECT 1 FROM quests q JOIN destinations d2 ON q.destination_id = d2.id
    WHERE d2.slug = 'batac' AND q.title = 'MMSU Campus Explorer'
  );

-- Checkpoint 1-1 — Main Gate
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward)
SELECT q.id, 1,
  'MMSU Main Gate',
  'You''ve reached the main entrance of Mariano Marcos State University — established in 1978. Welcome!',
  'gps', ST_SetSRID(ST_MakePoint(120.5660, 18.0535), 4326)::geography, 1000, 75
FROM quests q JOIN destinations d ON q.destination_id = d.id
WHERE d.slug = 'batac' AND q.title = 'MMSU Campus Explorer'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 1);

-- Checkpoint 1-2 — Administration Building
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward)
SELECT q.id, 2,
  'MMSU Administration Building',
  'The heart of the university — where decisions are made. Check in at the administration area.',
  'gps', ST_SetSRID(ST_MakePoint(120.5663, 18.0558), 4326)::geography, 1000, 75
FROM quests q JOIN destinations d ON q.destination_id = d.id
WHERE d.slug = 'batac' AND q.title = 'MMSU Campus Explorer'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 2);

-- Checkpoint 1-3 — Campus Quadrangle  (awards "MMSU Explorer" stamp)
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward, stamp_id)
SELECT q.id, 3,
  'MMSU Campus Quadrangle',
  'The open quad where campus life happens. You''ve explored the heart of MMSU!',
  'gps', ST_SetSRID(ST_MakePoint(120.5670, 18.0570), 4326)::geography, 1000, 75,
  s.id
FROM quests q
JOIN destinations d ON q.destination_id = d.id
JOIN passports p    ON p.destination_id = d.id
JOIN stamps s       ON s.passport_id = p.id AND s.name = 'MMSU Explorer'
WHERE d.slug = 'batac' AND q.title = 'MMSU Campus Explorer'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 3);


-- ════════════════════════════════════════════════════════════════════════
-- QUEST 2 — MMSU Academic Trail  (2 ★ | cultural | 375 XP total)
-- ════════════════════════════════════════════════════════════════════════
INSERT INTO quests (destination_id, title, summary, difficulty, est_duration_min, xp_reward, quest_type)
SELECT d.id,
  'MMSU Academic Trail',
  'Trace the intellectual spine of MMSU — from the library stacks to the engineering workshops and research halls.',
  2, 30, 150, 'cultural'
FROM destinations d
WHERE d.slug = 'batac'
  AND NOT EXISTS (
    SELECT 1 FROM quests q JOIN destinations d2 ON q.destination_id = d2.id
    WHERE d2.slug = 'batac' AND q.title = 'MMSU Academic Trail'
  );

-- Checkpoint 2-1 — University Library
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward)
SELECT q.id, 1,
  'MMSU University Library',
  'Every great university rests on its library. Check in to earn your first academic stamp.',
  'gps', ST_SetSRID(ST_MakePoint(120.5650, 18.0555), 4326)::geography, 1000, 75
FROM quests q JOIN destinations d ON q.destination_id = d.id
WHERE d.slug = 'batac' AND q.title = 'MMSU Academic Trail'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 1);

-- Checkpoint 2-2 — College of Engineering
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward)
SELECT q.id, 2,
  'College of Engineering',
  'Where future engineers are forged. One of MMSU''s flagship colleges driving regional development.',
  'gps', ST_SetSRID(ST_MakePoint(120.5680, 18.0545), 4326)::geography, 1000, 75
FROM quests q JOIN destinations d ON q.destination_id = d.id
WHERE d.slug = 'batac' AND q.title = 'MMSU Academic Trail'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 2);

-- Checkpoint 2-3 — R&D Center  (awards "Academic Trailblazer" stamp)
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward, stamp_id)
SELECT q.id, 3,
  'Research & Development Center',
  'MMSU''s R&D hub drives breakthroughs in agriculture and renewable energy for Ilocos Norte.',
  'gps', ST_SetSRID(ST_MakePoint(120.5658, 18.0575), 4326)::geography, 1000, 75,
  s.id
FROM quests q
JOIN destinations d ON q.destination_id = d.id
JOIN passports p    ON p.destination_id = d.id
JOIN stamps s       ON s.passport_id = p.id AND s.name = 'Academic Trailblazer'
WHERE d.slug = 'batac' AND q.title = 'MMSU Academic Trail'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 3);


-- ════════════════════════════════════════════════════════════════════════
-- QUEST 3 — MMSU Founder's Walk  (3 ★ | heritage | 550 XP total)
-- ════════════════════════════════════════════════════════════════════════
INSERT INTO quests (destination_id, title, summary, difficulty, est_duration_min, xp_reward, quest_type)
SELECT d.id,
  'MMSU Founder''s Walk',
  'Honour the legacy of Mariano Marcos and the pioneers who built this institution. Visit the monument, gymnasium, and amphitheater.',
  3, 45, 250, 'heritage'
FROM destinations d
WHERE d.slug = 'batac'
  AND NOT EXISTS (
    SELECT 1 FROM quests q JOIN destinations d2 ON q.destination_id = d2.id
    WHERE d2.slug = 'batac' AND q.title = 'MMSU Founder''s Walk'
  );

-- Checkpoint 3-1 — Founder's Monument
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward)
SELECT q.id, 1,
  'Founder''s Monument',
  'Mariano Marcos — lawyer, soldier, and statesman — is honoured here. Pause and reflect.',
  'gps', ST_SetSRID(ST_MakePoint(120.5665, 18.0560), 4326)::geography, 1000, 100
FROM quests q JOIN destinations d ON q.destination_id = d.id
WHERE d.slug = 'batac' AND q.title = 'MMSU Founder''s Walk'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 1);

-- Checkpoint 3-2 — MMSU Gymnasium
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward)
SELECT q.id, 2,
  'MMSU Gymnasium',
  'Beyond academics, MMSU builds champions. Check in to represent your spirit.',
  'gps', ST_SetSRID(ST_MakePoint(120.5672, 18.0542), 4326)::geography, 1000, 100
FROM quests q JOIN destinations d ON q.destination_id = d.id
WHERE d.slug = 'batac' AND q.title = 'MMSU Founder''s Walk'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 2);

-- Checkpoint 3-3 — Amphitheater  (awards "Founder's Spirit" stamp)
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward, stamp_id)
SELECT q.id, 3,
  'MMSU Amphitheater',
  'Where the university community gathers. Standing here, you''ve walked in the footsteps of every MMSU graduate.',
  'gps', ST_SetSRID(ST_MakePoint(120.5645, 18.0565), 4326)::geography, 1000, 100,
  s.id
FROM quests q
JOIN destinations d ON q.destination_id = d.id
JOIN passports p    ON p.destination_id = d.id
JOIN stamps s       ON s.passport_id = p.id AND s.name = 'Founder''s Spirit'
WHERE d.slug = 'batac' AND q.title = 'MMSU Founder''s Walk'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 3);


-- ── Final: keep total_stamps accurate after all inserts ──────────────────
UPDATE passports
SET    total_stamps = (SELECT COUNT(*) FROM stamps s WHERE s.passport_id = passports.id)
FROM   destinations d
WHERE  passports.destination_id = d.id AND d.slug = 'batac';

-- ── Summary ──────────────────────────────────────────────────────────────
-- Quest 1 · MMSU Campus Explorer  →  75 + (75×3) =  300 XP | stamp: MMSU Explorer (common)
-- Quest 2 · MMSU Academic Trail   → 150 + (75×3) =  375 XP | stamp: Academic Trailblazer (uncommon)
-- Quest 3 · MMSU Founder's Walk   → 250 + (100×3)=  550 XP | stamp: Founder's Spirit (rare)
--                                                Total: 1 225 XP + 3 passport stamps
-- All checkpoints: validation_type = 'gps', geo_radius_m = 1 000 m
-- ─────────────────────────────────────────────────────────────────────────
