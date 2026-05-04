import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { eq, and, sql } from 'drizzle-orm';
import { DRIZZLE, type Db } from '../../database/database.module';
import { destinations, quests } from '../../database/schema';

@Injectable()
export class DestinationsService {
  constructor(@Inject(DRIZZLE) private readonly db: Db) {}

  async list() {
    const rows = await this.db.execute<{
      id: string; slug: string; name: string; region: string | null;
      country_code: string; description: string | null;
      hero_image_url: string | null; is_active: boolean;
      lat: number | null; lng: number | null; quest_count: string;
    }>(sql`
      SELECT d.id, d.slug, d.name, d.region, d.country_code, d.description,
             d.hero_image_url, d.is_active,
             ST_Y(ST_Centroid(d.bounds::geometry)) AS lat,
             ST_X(ST_Centroid(d.bounds::geometry)) AS lng,
             COUNT(q.id) AS quest_count
      FROM ${destinations} d
      LEFT JOIN ${quests} q ON q.destination_id = d.id
      WHERE d.is_active = true
      GROUP BY d.id
      ORDER BY d.name
    `);
    return rows.rows.map((r) => ({
      id: r.id, slug: r.slug, name: r.name, region: r.region,
      countryCode: r.country_code, description: r.description,
      heroImageUrl: r.hero_image_url, isActive: r.is_active,
      lat: r.lat, lng: r.lng,
      questCount: Number(r.quest_count),
    }));
  }

  async findBySlug(slug: string) {
    const [dest] = await this.db
      .select()
      .from(destinations)
      .where(and(eq(destinations.slug, slug), eq(destinations.isActive, true)))
      .limit(1);
    if (!dest) throw new NotFoundException('Destination not found');
    const featured = await this.db
      .select({
        id: quests.id,
        title: quests.title,
        summary: quests.summary,
        difficulty: quests.difficulty,
        estDurationMin: quests.estDurationMin,
        xpReward: quests.xpReward,
        questType: quests.questType,
        coverImageUrl: quests.coverImageUrl,
      })
      .from(quests)
      .where(eq(quests.destinationId, dest.id))
      .limit(8);
    return { ...dest, featuredQuests: featured };
  }
}
