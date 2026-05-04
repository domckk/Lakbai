-- ============================================================
-- Seed: Ilocos Norte — Heritage Passport
--
-- 5 quests at famous Ilocos Norte landmarks.
-- Each quest has 1–2 checkpoints and awards a passport stamp
-- on the final checkpoint.
--
-- Passport has 5 stamps — all show as locked in the app until
-- the user physically visits each location and checks in.
--
-- Safe to re-run. Run via Supabase SQL editor or psql.
-- ============================================================

-- ── 1. Destination ───────────────────────────────────────────────────────
INSERT INTO destinations (slug, name, region, country_code, description, is_active)
VALUES (
  'ilocos-norte',
  'Ilocos Norte',
  'Ilocos Norte',
  'PH',
  'A province of dramatic coastlines, Spanish colonial churches, towering wind turbines, and living heritage. Home to the UNESCO-listed Paoay Church and the world-famous Bangui Wind Farm.',
  true
)
ON CONFLICT (slug) DO UPDATE
  SET name        = EXCLUDED.name,
      description = EXCLUDED.description,
      is_active   = EXCLUDED.is_active;

-- ── 2. Passport ──────────────────────────────────────────────────────────
INSERT INTO passports (destination_id, title, theme_color, total_stamps)
SELECT d.id, 'Ilocos Norte Heritage Passport', '#1A3A5C', 0
FROM destinations d
WHERE d.slug = 'ilocos-norte'
  AND NOT EXISTS (
    SELECT 1 FROM passports p
    JOIN destinations d2 ON p.destination_id = d2.id
    WHERE d2.slug = 'ilocos-norte'
  );

-- ── 3. Stamps (5 total) ───────────────────────────────────────────────────
INSERT INTO stamps (passport_id, name, rarity)
SELECT p.id, 'Wind Chaser', 'common'
FROM passports p JOIN destinations d ON p.destination_id = d.id
WHERE d.slug = 'ilocos-norte'
  AND NOT EXISTS (SELECT 1 FROM stamps s WHERE s.passport_id = p.id AND s.name = 'Wind Chaser');

INSERT INTO stamps (passport_id, name, rarity)
SELECT p.id, 'Heritage Guardian', 'uncommon'
FROM passports p JOIN destinations d ON p.destination_id = d.id
WHERE d.slug = 'ilocos-norte'
  AND NOT EXISTS (SELECT 1 FROM stamps s WHERE s.passport_id = p.id AND s.name = 'Heritage Guardian');

INSERT INTO stamps (passport_id, name, rarity)
SELECT p.id, 'Rock Whisperer', 'uncommon'
FROM passports p JOIN destinations d ON p.destination_id = d.id
WHERE d.slug = 'ilocos-norte'
  AND NOT EXISTS (SELECT 1 FROM stamps s WHERE s.passport_id = p.id AND s.name = 'Rock Whisperer');

INSERT INTO stamps (passport_id, name, rarity)
SELECT p.id, 'Blue Lagoon Drifter', 'rare'
FROM passports p JOIN destinations d ON p.destination_id = d.id
WHERE d.slug = 'ilocos-norte'
  AND NOT EXISTS (SELECT 1 FROM stamps s WHERE s.passport_id = p.id AND s.name = 'Blue Lagoon Drifter');

INSERT INTO stamps (passport_id, name, rarity)
SELECT p.id, 'Ilocos Ancestor', 'epic'
FROM passports p JOIN destinations d ON p.destination_id = d.id
WHERE d.slug = 'ilocos-norte'
  AND NOT EXISTS (SELECT 1 FROM stamps s WHERE s.passport_id = p.id AND s.name = 'Ilocos Ancestor');

-- Sync total_stamps count
UPDATE passports
SET    total_stamps = (SELECT COUNT(*) FROM stamps s WHERE s.passport_id = passports.id)
FROM   destinations d
WHERE  passports.destination_id = d.id AND d.slug = 'ilocos-norte';


-- ════════════════════════════════════════════════════════════════════════
-- QUEST 1 — Bangui Wind Farm  (1 ★ | adventure | 175 XP)
-- 18.5297° N, 120.4447° E — northwestern tip of Ilocos Norte
-- ════════════════════════════════════════════════════════════════════════
INSERT INTO quests (destination_id, title, summary, difficulty, est_duration_min, xp_reward, quest_type)
SELECT d.id,
  'Bangui Wind Farm Challenge',
  'Stand beneath 20 giant wind turbines lining the South China Sea coast. One of the most iconic sights in the Philippines — and an engineering marvel of the north.',
  1, 20, 100, 'adventure'
FROM destinations d
WHERE d.slug = 'ilocos-norte'
  AND NOT EXISTS (
    SELECT 1 FROM quests q JOIN destinations d2 ON q.destination_id = d2.id
    WHERE d2.slug = 'ilocos-norte' AND q.title = 'Bangui Wind Farm Challenge'
  );

-- Checkpoint — awards "Wind Chaser" stamp
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward, stamp_id)
SELECT q.id, 1,
  'Bangui Wind Farm',
  'The 20 giant turbines of the Bangui Wind Farm stretch 11 km along the shore of the South China Sea. Feel the northern winds — you''ve earned the Wind Chaser stamp!',
  'gps', ST_SetSRID(ST_MakePoint(120.4447, 18.5297), 4326)::geography, 800, 75,
  s.id
FROM quests q
JOIN destinations d ON q.destination_id = d.id
JOIN passports p    ON p.destination_id = d.id
JOIN stamps s       ON s.passport_id = p.id AND s.name = 'Wind Chaser'
WHERE d.slug = 'ilocos-norte' AND q.title = 'Bangui Wind Farm Challenge'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 1);


-- ════════════════════════════════════════════════════════════════════════
-- QUEST 2 — Paoay Church  (2 ★ | heritage | 300 XP)
-- 18.0633° N, 120.5328° E — Paoay, Ilocos Norte
-- ════════════════════════════════════════════════════════════════════════
INSERT INTO quests (destination_id, title, summary, difficulty, est_duration_min, xp_reward, quest_type)
SELECT d.id,
  'Paoay Church Pilgrimage',
  'Visit the UNESCO World Heritage–listed Saint Augustine Church of Paoay, built in 1694. Its earthquake Baroque architecture has survived centuries of history.',
  2, 30, 150, 'heritage'
FROM destinations d
WHERE d.slug = 'ilocos-norte'
  AND NOT EXISTS (
    SELECT 1 FROM quests q JOIN destinations d2 ON q.destination_id = d2.id
    WHERE d2.slug = 'ilocos-norte' AND q.title = 'Paoay Church Pilgrimage'
  );

-- Checkpoint 1 — Church grounds
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward)
SELECT q.id, 1,
  'Saint Augustine Church Grounds',
  'Built in 1694 and declared a UNESCO World Heritage Site in 1993, the Paoay Church is a masterpiece of Philippine colonial architecture. Massive coral-stone buttresses hold up walls that have outlasted earthquakes and wars.',
  'gps', ST_SetSRID(ST_MakePoint(120.5320, 18.0630), 4326)::geography, 300, 75
FROM quests q JOIN destinations d ON q.destination_id = d.id
WHERE d.slug = 'ilocos-norte' AND q.title = 'Paoay Church Pilgrimage'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 1);

-- Checkpoint 2 — Bell Tower  (awards "Heritage Guardian" stamp)
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward, stamp_id)
SELECT q.id, 2,
  'Paoay Church Bell Tower',
  'The detached bell tower once served as a watchtower and military observation post. Completing this heritage walk earns you the Heritage Guardian stamp.',
  'gps', ST_SetSRID(ST_MakePoint(120.5328, 18.0633), 4326)::geography, 300, 75,
  s.id
FROM quests q
JOIN destinations d ON q.destination_id = d.id
JOIN passports p    ON p.destination_id = d.id
JOIN stamps s       ON s.passport_id = p.id AND s.name = 'Heritage Guardian'
WHERE d.slug = 'ilocos-norte' AND q.title = 'Paoay Church Pilgrimage'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 2);


-- ════════════════════════════════════════════════════════════════════════
-- QUEST 3 — Kapurpurawan Rock Formation  (2 ★ | nature | 275 XP)
-- 18.3528° N, 120.4019° E — Burgos, Ilocos Norte
-- ════════════════════════════════════════════════════════════════════════
INSERT INTO quests (destination_id, title, summary, difficulty, est_duration_min, xp_reward, quest_type)
SELECT d.id,
  'Kapurpurawan Rock Trail',
  'Trek to the stunning white rock formation sculpted by wind and waves on the northern coast. One of the most photogenic natural wonders of Ilocos Norte.',
  2, 25, 125, 'nature'
FROM destinations d
WHERE d.slug = 'ilocos-norte'
  AND NOT EXISTS (
    SELECT 1 FROM quests q JOIN destinations d2 ON q.destination_id = d2.id
    WHERE d2.slug = 'ilocos-norte' AND q.title = 'Kapurpurawan Rock Trail'
  );

-- Checkpoint — awards "Rock Whisperer" stamp
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward, stamp_id)
SELECT q.id, 1,
  'Kapurpurawan Rock Formation',
  '"Kapurpurawan" means "white" in Ilocano — a fitting name for these bleached limestone rocks carved by centuries of sea spray. You''ve earned the Rock Whisperer stamp.',
  'gps', ST_SetSRID(ST_MakePoint(120.4019, 18.3528), 4326)::geography, 500, 150,
  s.id
FROM quests q
JOIN destinations d ON q.destination_id = d.id
JOIN passports p    ON p.destination_id = d.id
JOIN stamps s       ON s.passport_id = p.id AND s.name = 'Rock Whisperer'
WHERE d.slug = 'ilocos-norte' AND q.title = 'Kapurpurawan Rock Trail'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 1);


-- ════════════════════════════════════════════════════════════════════════
-- QUEST 4 — Pagudpud  (3 ★ | adventure | 425 XP)
-- 18.5427° N, 120.7936° E — Pagudpud, Ilocos Norte
-- ════════════════════════════════════════════════════════════════════════
INSERT INTO quests (destination_id, title, summary, difficulty, est_duration_min, xp_reward, quest_type)
SELECT d.id,
  'Pagudpud Paradise Quest',
  'Reach the northernmost beach destination in Luzon — Pagudpud, where the turquoise Saud Beach meets the Patapat Viaduct and lush mountain scenery.',
  3, 40, 200, 'adventure'
FROM destinations d
WHERE d.slug = 'ilocos-norte'
  AND NOT EXISTS (
    SELECT 1 FROM quests q JOIN destinations d2 ON q.destination_id = d2.id
    WHERE d2.slug = 'ilocos-norte' AND q.title = 'Pagudpud Paradise Quest'
  );

-- Checkpoint 1 — Saud Beach
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward)
SELECT q.id, 1,
  'Saud Beach',
  'The powdery white sands of Saud Beach stretch along Pagudpud''s coast with crystal-clear water. Known as the "Boracay of the North."',
  'gps', ST_SetSRID(ST_MakePoint(120.7936, 18.5427), 4326)::geography, 600, 100
FROM quests q JOIN destinations d ON q.destination_id = d.id
WHERE d.slug = 'ilocos-norte' AND q.title = 'Pagudpud Paradise Quest'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 1);

-- Checkpoint 2 — Patapat Viaduct  (awards "Blue Lagoon Drifter" stamp)
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward, stamp_id)
SELECT q.id, 2,
  'Patapat Viaduct',
  'The Patapat Viaduct hugs the mountainside above the South China Sea — one of the most scenic drives in the Philippines. Completing this earns the Blue Lagoon Drifter stamp.',
  'gps', ST_SetSRID(ST_MakePoint(120.8053, 18.5553), 4326)::geography, 800, 125,
  s.id
FROM quests q
JOIN destinations d ON q.destination_id = d.id
JOIN passports p    ON p.destination_id = d.id
JOIN stamps s       ON s.passport_id = p.id AND s.name = 'Blue Lagoon Drifter'
WHERE d.slug = 'ilocos-norte' AND q.title = 'Pagudpud Paradise Quest'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 2);


-- ════════════════════════════════════════════════════════════════════════
-- QUEST 5 — Laoag Sinking Bell Tower  (2 ★ | heritage | 350 XP)
-- 18.1989° N, 120.5922° E — Laoag City
-- ════════════════════════════════════════════════════════════════════════
INSERT INTO quests (destination_id, title, summary, difficulty, est_duration_min, xp_reward, quest_type)
SELECT d.id,
  'Laoag Heritage Walk',
  'Explore Laoag City, the capital of Ilocos Norte. Visit the iconic sinking bell tower and the Saint William Cathedral — centuries of colonial and religious history in one walk.',
  2, 35, 175, 'heritage'
FROM destinations d
WHERE d.slug = 'ilocos-norte'
  AND NOT EXISTS (
    SELECT 1 FROM quests q JOIN destinations d2 ON q.destination_id = d2.id
    WHERE d2.slug = 'ilocos-norte' AND q.title = 'Laoag Heritage Walk'
  );

-- Checkpoint 1 — Saint William Cathedral
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward)
SELECT q.id, 1,
  'Saint William Cathedral',
  'Constructed in the 18th century, this cathedral is the seat of the Roman Catholic Diocese of Laoag and one of the oldest churches in the Philippines.',
  'gps', ST_SetSRID(ST_MakePoint(120.5929, 18.1981), 4326)::geography, 250, 75
FROM quests q JOIN destinations d ON q.destination_id = d.id
WHERE d.slug = 'ilocos-norte' AND q.title = 'Laoag Heritage Walk'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 1);

-- Checkpoint 2 — Sinking Bell Tower  (awards "Ilocos Ancestor" stamp)
INSERT INTO checkpoints (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, xp_reward, stamp_id)
SELECT q.id, 2,
  'Laoag Sinking Bell Tower',
  'Built in 1612, this bell tower stands apart from its cathedral and has been slowly sinking into the ground for centuries. Finishing this walk earns the legendary Ilocos Ancestor stamp.',
  'gps', ST_SetSRID(ST_MakePoint(120.5922, 18.1989), 4326)::geography, 250, 100,
  s.id
FROM quests q
JOIN destinations d ON q.destination_id = d.id
JOIN passports p    ON p.destination_id = d.id
JOIN stamps s       ON s.passport_id = p.id AND s.name = 'Ilocos Ancestor'
WHERE d.slug = 'ilocos-norte' AND q.title = 'Laoag Heritage Walk'
  AND NOT EXISTS (SELECT 1 FROM checkpoints c WHERE c.quest_id = q.id AND c.sort_order = 2);


-- ── Final stamp count sync ────────────────────────────────────────────────
UPDATE passports
SET    total_stamps = (SELECT COUNT(*) FROM stamps s WHERE s.passport_id = passports.id)
FROM   destinations d
WHERE  passports.destination_id = d.id AND d.slug = 'ilocos-norte';


-- ── Summary ───────────────────────────────────────────────────────────────
-- Quest 1 · Bangui Wind Farm Challenge →  100 + 75  =  175 XP | Wind Chaser (common)
-- Quest 2 · Paoay Church Pilgrimage    →  150 + 150 =  300 XP | Heritage Guardian (uncommon)
-- Quest 3 · Kapurpurawan Rock Trail    →  125 + 150 =  275 XP | Rock Whisperer (uncommon)
-- Quest 4 · Pagudpud Paradise Quest    →  200 + 225 =  425 XP | Blue Lagoon Drifter (rare)
-- Quest 5 · Laoag Heritage Walk        →  175 + 175 =  350 XP | Ilocos Ancestor (epic)
--                                                  Total: 1 525 XP + 5 passport stamps
-- ─────────────────────────────────────────────────────────────────────────
