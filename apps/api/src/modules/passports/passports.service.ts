import { Inject, Injectable } from '@nestjs/common';
import { eq, sql } from 'drizzle-orm';
import { DRIZZLE, type Db } from '../../database/database.module';
import { checkpoints, passportsTable, stamps, userStamps } from '../../database/schema';

@Injectable()
export class PassportsService {
  constructor(@Inject(DRIZZLE) private readonly db: Db) {}

  /** All passports for a user, with completion percentages. */
  async listForUser(userId: string) {
    const rows = await this.db.execute<{
      passport_id: string;
      title: string;
      cover_url: string | null;
      theme_color: string | null;
      total_stamps: number;
      earned_stamps: number;
    }>(sql`
      SELECT p.id AS passport_id, p.title, p.cover_url, p.theme_color, p.total_stamps,
             COUNT(us.stamp_id)::int AS earned_stamps
      FROM ${passportsTable} p
      LEFT JOIN ${stamps} s ON s.passport_id = p.id
      LEFT JOIN ${userStamps} us ON us.stamp_id = s.id AND us.user_id = ${userId}
      GROUP BY p.id
      ORDER BY p.title
    `);
    return rows.rows.map((r) => ({
      id: r.passport_id,
      title: r.title,
      coverUrl: r.cover_url,
      themeColor: r.theme_color,
      totalStamps: r.total_stamps,
      earnedStamps: r.earned_stamps,
      completion: r.total_stamps > 0 ? r.earned_stamps / r.total_stamps : 0,
    }));
  }

  /** Detailed passport view: every stamp with earned/locked state. */
  async getPassportForUser(userId: string, passportId: string) {
    const [passport] = await this.db
      .select()
      .from(passportsTable)
      .where(eq(passportsTable.id, passportId))
      .limit(1);
    if (!passport) return null;

    const rows = await this.db.execute<{
      id: string;
      name: string;
      rarity: string | null;
      art_url: string | null;
      lat: number | null;
      lng: number | null;
    }>(sql`
      SELECT s.id, s.name, s.rarity, s.art_url,
             ST_Y(c.geo_point::geometry) AS lat,
             ST_X(c.geo_point::geometry) AS lng
      FROM ${stamps} s
      LEFT JOIN ${checkpoints} c ON c.stamp_id = s.id
      WHERE s.passport_id = ${passportId}
    `);
    const allStamps = rows.rows;

    const earned = await this.db
      .select({ stampId: userStamps.stampId, earnedAt: userStamps.earnedAt })
      .from(userStamps)
      .where(eq(userStamps.userId, userId));
    const earnedMap = new Map(earned.map((e) => [e.stampId, e.earnedAt]));

    return {
      ...passport,
      stamps: allStamps.map((s) => ({
        id: s.id,
        name: s.name,
        rarity: s.rarity,
        artUrl: s.art_url,
        lat: s.lat,
        lng: s.lng,
        earnedAt: earnedMap.get(s.id) ?? null,
      })),
    };
  }
}
