/**
 * Ilocos Norte MVP seed — 1 destination, 5 quests, checkpoints, 1 partner, 1 reward.
 * Run with: pnpm db:seed
 */
import 'dotenv/config';
import { Pool } from 'pg';

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

async function main() {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // ─── Destination ─────────────────────────────────────────────────────────
    const { rows: [dest] } = await client.query<{ id: string }>(`
      INSERT INTO destinations (slug, name, region, country_code, hero_image_url, description, is_active)
      VALUES ('ilocos-norte', 'Ilocos Norte', 'Region I', 'PH',
              '/images/ilocos-norte.jpg',
              'The northernmost province of the Philippines, home to centuries-old Spanish colonial churches, windswept sand dunes, Bangui windmills, and the pristine beaches of Pagudpud.',
              true)
      ON CONFLICT (slug) DO UPDATE SET
        description = EXCLUDED.description,
        hero_image_url = EXCLUDED.hero_image_url
      RETURNING id
    `);
    const destId = dest.id;
    console.log('✓ destination:', destId);

    // ─── Clear existing quests (checkpoints cascade) ─────────────────────────
    await client.query(`DELETE FROM quests WHERE destination_id = $1`, [destId]);
    console.log('✓ cleared old quests');

    // ─── Passport ────────────────────────────────────────────────────────────
    const { rows: [existingPassport] } = await client.query<{ id: string }>(
      `SELECT id FROM passports WHERE destination_id = $1 LIMIT 1`, [destId]
    );
    let passportId = existingPassport?.id;

    if (!passportId) {
      const { rows: [passport] } = await client.query<{ id: string }>(`
        INSERT INTO passports (destination_id, title, theme_color, cover_url, total_stamps)
        VALUES ($1, 'Heritage', '#8B4513', '/images/heritage.jpg', 5)
        RETURNING id
      `, [destId]);
      passportId = passport?.id;
    } else {
      await client.query(
        `UPDATE passports SET title = 'Heritage', cover_url = '/images/heritage.jpg' WHERE id = $1`,
        [passportId],
      );
    }

    // ─── Stamps ──────────────────────────────────────────────────────────────
    const stampDefs = [
      { name: 'Paoay Church Sentinel',      rarity: 'epic'      },
      { name: 'Windmill Chaser',             rarity: 'rare'      },
      { name: 'Cape Bojeador Keeper',        rarity: 'common'    },
      { name: 'North Palace Explorer',       rarity: 'rare'      },
      { name: 'Sinking Tower Legend',        rarity: 'legendary' },
    ];
    const stampIds: string[] = [];
    if (passportId) {
      await client.query(`DELETE FROM stamps WHERE passport_id = $1`, [passportId]);
      for (const s of stampDefs) {
        const { rows: [row] } = await client.query<{ id: string }>(`
          INSERT INTO stamps (passport_id, name, rarity) VALUES ($1, $2, $3) RETURNING id
        `, [passportId, s.name, s.rarity]);
        if (row) stampIds.push(row.id);
      }
    }
    console.log('✓ stamps:', stampIds.length);

    // ─── Quests ──────────────────────────────────────────────────────────────
    interface CpSeed {
      title: string; description: string; lat: number; lng: number;
      type: string; radius: number; xp: number; stampIdx?: number;
    }
    interface QuestSeed {
      title: string; summary: string; difficulty: number; est: number;
      xp: number; type: string; cover: string; checkpoints: CpSeed[];
    }

    const questSeeds: QuestSeed[] = [
      // ══ PAGUDPUD ══════════════════════════════════════════════════════════
      {
        title: 'Pagudpud: The Blue North',
        summary: 'Explore the "Boracay of the North" — white-sand beaches, a hidden lagoon, a jungle waterfall, a sea cave, and the dramatic Patapat Viaduct.',
        difficulty: 2, est: 210, xp: 480, type: 'nature', cover: '/images/pagudpud.jpg',
        checkpoints: [
          {
            title: 'Saud Beach',
            description: 'Two kilometers of white powdery sand and crystal-clear water — Pagudpud\'s most famous beach.',
            lat: 18.5455, lng: 120.7889, type: 'gps', radius: 120, xp: 70,
          },
          {
            title: 'Blue Lagoon',
            description: 'A sheltered cove with striking blue-green water, quieter and more intimate than Saud Beach.',
            lat: 18.5389, lng: 120.7820, type: 'gps', radius: 100, xp: 80,
          },
          {
            title: 'Kabigan Falls',
            description: 'A 30-meter waterfall hidden behind a 20-minute trek through rice fields and coconut groves.',
            lat: 18.5169, lng: 120.7531, type: 'gps_qr', radius: 100, xp: 80,
          },
          {
            title: 'Bantay Abot Cave',
            description: 'A natural hollow arch rock formation rising from the sea in Balaoi — you can walk straight through it.',
            lat: 18.4897, lng: 120.8204, type: 'gps_qr', radius: 80, xp: 70,
          },
          {
            title: 'Patapat Viaduct',
            description: 'The longest viaduct in the Philippines, clinging to mountain cliffs high above the South China Sea.',
            lat: 18.5558, lng: 120.7767, type: 'gps', radius: 100, xp: 60,
          },
        ],
      },

      // ══ BANGUI ════════════════════════════════════════════════════════════
      {
        title: 'Bangui: The Windmill Shore',
        summary: 'Walk the full length of the Bangui Windmill Row — the first wind farm in Southeast Asia, 20 turbines lined along the South China Sea.',
        difficulty: 1, est: 60, xp: 260, type: 'adventure', cover: '/images/bangui.jpg',
        checkpoints: [
          {
            title: 'Bangui Windmill Row — South End',
            description: 'Start of the 20-turbine row. The first wind farm in Southeast Asia, built in 2005 along the Bangui coastline.',
            lat: 18.5230, lng: 120.4578, type: 'gps_qr', radius: 100, xp: 70, stampIdx: 1,
          },
          {
            title: 'Windmill Row — Midpoint',
            description: 'Roughly turbine #10. Feel the full Amihan winds off the Pacific. The best photo spot along the row.',
            lat: 18.5380, lng: 120.4600, type: 'gps', radius: 100, xp: 50,
          },
          {
            title: 'Bangui Windmill Row — North End',
            description: 'The final turbine at the northern tip. Turn back and take in the full row stretching down the coast.',
            lat: 18.5530, lng: 120.4620, type: 'gps', radius: 100, xp: 60,
          },
          {
            title: 'Bangui Beachfront',
            description: 'The black-sand beach beside the windmills where locals fish at dusk. Catch the turbines spinning at golden hour.',
            lat: 18.5320, lng: 120.4560, type: 'gps', radius: 120, xp: 40,
          },
        ],
      },

      // ══ BURGOS ════════════════════════════════════════════════════════════
      {
        title: 'Burgos: Cape & Rock Trail',
        summary: 'Climb a 19th-century Spanish lighthouse, walk through the largest wind farm in the Philippines, and discover white rock formations carved by the sea.',
        difficulty: 2, est: 120, xp: 350, type: 'adventure', cover: '/images/kapurpurawan.jpg',
        checkpoints: [
          {
            title: 'Cape Bojeador Lighthouse',
            description: 'One of the oldest lighthouses in the Philippines, built by the Spanish in 1892. Climb the octagonal tower for sweeping coastal views.',
            lat: 18.4909, lng: 120.5065, type: 'gps_qr', radius: 60, xp: 80, stampIdx: 2,
          },
          {
            title: 'Burgos Wind Farm',
            description: 'The largest wind farm in the Philippines — 87 turbines across the Burgos hills. A different scale from Bangui\'s coastal row.',
            lat: 18.4975, lng: 120.5100, type: 'gps', radius: 120, xp: 70,
          },
          {
            title: 'Kapurpurawan Rock Formation',
            description: 'Brilliant white limestone rocks sculpted by wind and sea. Walk right up to them at low tide — a surreal landscape.',
            lat: 18.4847, lng: 120.5118, type: 'gps_qr', radius: 80, xp: 80,
          },
        ],
      },

      // ══ PAOAY — Heritage ══════════════════════════════════════════════════
      {
        title: 'Paoay: Church & Palace',
        summary: 'The two crown jewels of Paoay — a UNESCO Baroque church built in 1704 and a presidential palace overlooking a volcanic crater lake.',
        difficulty: 1, est: 90, xp: 300, type: 'heritage', cover: '/images/paoay-church.jpg',
        checkpoints: [
          {
            title: 'Paoay Church (UNESCO)',
            description: 'One of the finest Baroque churches in Asia, a UNESCO World Heritage Site. Built in 1704 with massive earthquake-resistant buttresses.',
            lat: 18.0638, lng: 120.5265, type: 'gps_qr', radius: 80, xp: 100, stampIdx: 0,
          },
          {
            title: 'Paoay Church Convent & Grounds',
            description: 'Explore the restored convent and coral-stone courtyard surrounding the church. Notice the 70 buttresses that make it unique.',
            lat: 18.0635, lng: 120.5270, type: 'gps', radius: 60, xp: 60,
          },
          {
            title: 'Malacañang of the North',
            description: 'Northern summer palace of the Marcos family, perched above Paoay Lake. Now a public museum with original furnishings.',
            lat: 18.0384, lng: 120.5319, type: 'gps_qr', radius: 70, xp: 90, stampIdx: 3,
          },
        ],
      },

      // ══ PAOAY — Adventure ═════════════════════════════════════════════════
      {
        title: 'Paoay: Coastal Dunes Ride',
        summary: 'Sand, sea, and silence — ride or board across Paoay\'s coastal dunes, then rest by the mirror-calm waters of Paoay Lake.',
        difficulty: 3, est: 120, xp: 360, type: 'adventure', cover: '/images/paoay-sand_dunes.jpg',
        checkpoints: [
          {
            title: 'Paoay Sand Dunes — Entry',
            description: 'Register at the dune entrance and rent an ATV or sandboard. The dunes stretch for kilometers along Paoay\'s coastline.',
            lat: 18.0620, lng: 120.4900, type: 'gps_qr', radius: 100, xp: 70,
          },
          {
            title: 'Paoay Sand Dunes — Ridgeline',
            description: 'The highest point of the Paoay dunes, with views of both the South China Sea and the flat agricultural plains behind.',
            lat: 18.0603, lng: 120.4860, type: 'gps', radius: 120, xp: 80,
          },
          {
            title: 'Suba Sand Dunes',
            description: 'The quieter dunes of Suba, farther down the coast — less visited, better for sunset, and unobstructed sea views.',
            lat: 18.0580, lng: 120.4850, type: 'gps', radius: 120, xp: 70,
          },
          {
            title: 'Paoay Lake Viewpoint',
            description: 'The cool-down stop. Paoay Lake sits in a volcanic crater, ringed by rice paddies and coconut palms. Perfect after the dunes.',
            lat: 18.0405, lng: 120.5325, type: 'gps', radius: 80, xp: 60,
          },
        ],
      },

      // ══ LAOAG CITY — Landmark ═════════════════════════════════════════════
      {
        title: 'Laoag: Colonial Heart',
        summary: 'The historic core of Ilocos Norte\'s capital — a 17th-century sinking bell tower, a grand colonial cathedral, and the provincial museum.',
        difficulty: 1, est: 90, xp: 300, type: 'landmark', cover: '/images/capitol.webp',
        checkpoints: [
          {
            title: 'Sinking Bell Tower',
            description: 'The iconic free-standing bell tower that has slowly sunk into the earth since 1612. Built of coral stone, a symbol of Laoag City.',
            lat: 18.1993, lng: 120.5968, type: 'gps_qr', radius: 50, xp: 90, stampIdx: 4,
          },
          {
            title: 'St. William\'s Cathedral',
            description: 'The grand 18th-century cathedral dedicated to St. William the Hermit. Seat of the Diocese of Laoag — right beside the bell tower.',
            lat: 18.1970, lng: 120.5934, type: 'gps', radius: 60, xp: 70,
          },
          {
            title: 'Museo Ilocos Norte',
            description: 'The provincial museum in a restored colonial building, documenting Ilocos Norte\'s history from pre-colonial times to the modern era.',
            lat: 18.1987, lng: 120.5920, type: 'gps_qr', radius: 60, xp: 70,
          },
        ],
      },

      // ══ LAOAG CITY — Adventure ════════════════════════════════════════════
      {
        title: 'Laoag: La Paz Dunes Challenge',
        summary: 'Conquer the largest sand dunes in Asia — sandboard down the face, climb to the summit ridge, and chase the sunset from the highest point.',
        difficulty: 4, est: 150, xp: 440, type: 'adventure', cover: '/images/laoag-sand_dunes.jpg',
        checkpoints: [
          {
            title: 'La Paz Dunes — Entry Gate',
            description: 'Register and rent a sandboard (₱150) or book a 4×4 desert ride. The dunes start just beyond the gate.',
            lat: 18.1561, lng: 120.4722, type: 'gps_qr', radius: 80, xp: 70,
          },
          {
            title: 'La Paz Dunes — Summit Ridge',
            description: 'The highest point of the dunes. Panoramic views of the South China Sea on one side, Laoag City on the other.',
            lat: 18.1502, lng: 120.4651, type: 'gps', radius: 100, xp: 100,
          },
          {
            title: 'Sandboard Run',
            description: 'Complete one full sandboard descent from the ridge. The steepest and longest run is near the second marker.',
            lat: 18.1488, lng: 120.4639, type: 'gps', radius: 120, xp: 80,
          },
          {
            title: 'Sunset Vantage Point',
            description: 'The western-facing ridge where the sun drops directly into the South China Sea. Stay for the full sunset.',
            lat: 18.1520, lng: 120.4610, type: 'gps', radius: 100, xp: 90,
          },
        ],
      },

      // ══ BATAC — Food ══════════════════════════════════════════════════════
      {
        title: 'Batac: Ilocano Food Trail',
        summary: 'Eat your way through Batac — the empanada capital of Ilocos Norte. Crispy empanada, garlicky longganisa, and fall-off-the-bone bagnet.',
        difficulty: 1, est: 90, xp: 240, type: 'food', cover: '/images/batac-riverside.jpg',
        checkpoints: [
          {
            title: 'Batac Riverside Empanadahan',
            description: 'The most famous empanada strip in Ilocos Norte along the Batac riverside. Crispy shell, longganisa filling, served with sukang Iloko.',
            lat: 18.0553, lng: 120.5645, type: 'qr', radius: 40, xp: 80,
          },
          {
            title: 'Evangeline\'s Restaurant',
            description: 'A Batac institution. Dinengdeng, pinakbet, and what many locals insist is the best bagnet (deep-fried pork belly) in the province.',
            lat: 18.0560, lng: 120.5670, type: 'qr', radius: 30, xp: 80,
          },
          {
            title: 'Batac Public Market',
            description: 'Pick up Laoag longganisa, fresh burnay pots, and native delicacies at the Batac market — a real slice of everyday Ilocano life.',
            lat: 18.0545, lng: 120.5630, type: 'qr', radius: 50, xp: 60,
          },
        ],
      },

      // ══ BADOC — Cultural ══════════════════════════════════════════════════
      {
        title: 'Badoc: The Luna Legacy',
        summary: 'Step into the world of Juan Luna — national hero and painter of "Spoliarium." Visit his restored birthplace and the centuries-old Badoc Church.',
        difficulty: 1, est: 60, xp: 220, type: 'cultural', cover: '/images/luna-legacy.jpg',
        checkpoints: [
          {
            title: 'Juan Luna Shrine',
            description: 'Birthplace of Juan Luna (1857–1899), painter of Spoliarium — the most celebrated Filipino painting. A beautifully restored ancestral house.',
            lat: 17.9231, lng: 120.4771, type: 'gps_qr', radius: 70, xp: 90,
          },
          {
            title: 'Badoc Church (Nuestra Señora de la Asunción)',
            description: 'One of the oldest churches in Ilocos Norte, built in the 17th century. The Luna family was baptized here. Quiet, ornate, and often overlooked.',
            lat: 17.9238, lng: 120.4780, type: 'gps', radius: 60, xp: 70,
          },
        ],
      },
    ];

    for (let qi = 0; qi < questSeeds.length; qi++) {
      const q = questSeeds[qi];
      const { rows: [quest] } = await client.query<{ id: string }>(`
        INSERT INTO quests (destination_id, title, summary, difficulty, est_duration_min, xp_reward, quest_type, cover_image_url)
        VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING id
      `, [destId, q.title, q.summary, q.difficulty, q.est, q.xp, q.type, q.cover]);

      const questId = quest.id;

      for (let ci = 0; ci < q.checkpoints.length; ci++) {
        const cp = q.checkpoints[ci];
        const stampId = cp.stampIdx !== undefined ? (stampIds[cp.stampIdx] ?? null) : null;
        const qrSecret = cp.type.includes('qr') ? require('crypto').randomBytes(16).toString('hex') : null;
        await client.query(`
          INSERT INTO checkpoints
            (quest_id, sort_order, title, description, validation_type, geo_point, geo_radius_m, qr_secret, xp_reward, stamp_id)
          VALUES
            ($1, $2, $3, $4, $5, ST_SetSRID(ST_MakePoint($6, $7), 4326)::geography, $8, $9, $10, $11)
        `, [questId, ci + 1, cp.title, cp.description, cp.type, cp.lng, cp.lat, cp.radius, qrSecret, cp.xp, stampId]);
      }
      console.log(`✓ quest: "${q.title}" (${q.checkpoints.length} checkpoints)`);
    }

    // ─── Partner + Reward ─────────────────────────────────────────────────────
    await client.query(`DELETE FROM partners WHERE destination_id = $1`, [destId]);

    const { rows: [partner] } = await client.query<{ id: string }>(`
      INSERT INTO partners (name, category, destination_id, geo_point, contact_email, subscription_tier, is_verified)
      VALUES (
        'Herencia Cafe Paoay', 'restaurant', $1,
        ST_SetSRID(ST_MakePoint(120.5270, 18.0620), 4326)::geography,
        'hello@herenciacafe.ph', 'standard', true
      )
      RETURNING id
    `, [destId]);

    if (partner) {
      const crawlQuest = await client.query<{ id: string }>(
        `SELECT id FROM quests WHERE title = 'Batac: Ilocano Food Trail' LIMIT 1`
      );
      const crawlQuestId = crawlQuest.rows[0]?.id ?? null;
      await client.query(`
        INSERT INTO rewards (partner_id, title, description, reward_type, value_pct, required_quest_id)
        VALUES ($1, '15% off your bill at Herencia Cafe', 'Show this voucher at checkout. Valid Mon–Sat.', 'discount', 15, $2)
      `, [partner.id, crawlQuestId]);
      console.log('✓ partner + reward seeded');
    }

    await client.query('COMMIT');
    console.log('\n🎉 Ilocos Norte seed complete!');
  } catch (err) {
    await client.query('ROLLBACK');
    console.error('Seed failed:', err);
    throw err;
  } finally {
    client.release();
    await pool.end();
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
