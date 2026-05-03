/**
 * Lightweight SQL migration runner. We use raw SQL files (not drizzle-kit's
 * generated migrations) because PostGIS extension setup and geography columns
 * are simpler to express that way.
 */
import 'dotenv/config';
import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';
import { Pool } from 'pg';

const MIGRATIONS_DIR = join(__dirname, 'migrations');

async function main() {
  const url = process.env.DATABASE_URL;
  if (!url) throw new Error('DATABASE_URL not set');
  const pool = new Pool({ connectionString: url });

  await pool.query(`
    CREATE TABLE IF NOT EXISTS _migrations (
      name TEXT PRIMARY KEY,
      applied_at TIMESTAMPTZ DEFAULT now()
    );
  `);

  const applied = new Set(
    (await pool.query<{ name: string }>('SELECT name FROM _migrations')).rows.map((r) => r.name),
  );
  const files = readdirSync(MIGRATIONS_DIR)
    .filter((f) => f.endsWith('.sql'))
    .sort();

  for (const file of files) {
    if (applied.has(file)) {
      console.log(`✓ already applied: ${file}`);
      continue;
    }
    const sqlText = readFileSync(join(MIGRATIONS_DIR, file), 'utf8');
    console.log(`→ applying: ${file}`);
    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await client.query(sqlText);
      await client.query('INSERT INTO _migrations(name) VALUES ($1)', [file]);
      await client.query('COMMIT');
      console.log(`✓ applied:  ${file}`);
    } catch (err) {
      await client.query('ROLLBACK');
      console.error(`✗ failed:   ${file}`);
      throw err;
    } finally {
      client.release();
    }
  }

  await pool.end();
  console.log('migrations complete');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
