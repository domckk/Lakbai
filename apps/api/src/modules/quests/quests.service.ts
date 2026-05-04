import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { and, asc, eq, sql } from 'drizzle-orm';
import { DRIZZLE, type Db } from '../../database/database.module';
import { checkpoints, destinations, quests, userQuests } from '../../database/schema';

interface QuestQuery {
  destinationSlug?: string;
  type?: string;
  difficulty?: number;
}

@Injectable()
export class QuestsService {
  constructor(@Inject(DRIZZLE) private readonly db: Db) {}

  async list(q: QuestQuery) {
    const filters = [] as ReturnType<typeof eq>[];
    if (q.destinationSlug) {
      const [dest] = await this.db
        .select({ id: destinations.id })
        .from(destinations)
        .where(eq(destinations.slug, q.destinationSlug))
        .limit(1);
      if (!dest) return [];
      filters.push(eq(quests.destinationId, dest.id));
    }
    if (q.type) filters.push(eq(quests.questType, q.type));
    if (q.difficulty) filters.push(eq(quests.difficulty, q.difficulty));

    return this.db
      .select()
      .from(quests)
      .where(filters.length ? and(...filters) : undefined)
      .orderBy(asc(quests.difficulty));
  }

  async findById(id: string, userId?: string) {
    const [quest] = await this.db.select().from(quests).where(eq(quests.id, id)).limit(1);
    if (!quest) throw new NotFoundException('Quest not found');

    const [cps, uqRows] = await Promise.all([
      this.db
        .select({
          id: checkpoints.id,
          sortOrder: checkpoints.sortOrder,
          title: checkpoints.title,
          description: checkpoints.description,
          validationType: checkpoints.validationType,
          geoRadiusM: checkpoints.geoRadiusM,
          xpReward: checkpoints.xpReward,
          lat: sql<number>`ST_Y(${checkpoints.geoPoint}::geometry)`,
          lng: sql<number>`ST_X(${checkpoints.geoPoint}::geometry)`,
        })
        .from(checkpoints)
        .where(eq(checkpoints.questId, id))
        .orderBy(asc(checkpoints.sortOrder)),

      userId
        ? this.db
            .select({ status: userQuests.status })
            .from(userQuests)
            .where(and(eq(userQuests.questId, id), eq(userQuests.userId, userId)))
            .limit(1)
        : Promise.resolve([] as { status: string }[]),
    ]);

    const userQuestStatus = (uqRows as { status: string }[])[0]?.status ?? null;
    return { ...quest, checkpoints: cps, userQuestStatus };
  }

  async start(userId: string, questId: string) {
    await this.findById(questId);
    await this.db
      .insert(userQuests)
      .values({ userId, questId, status: 'in_progress' })
      .onConflictDoNothing();
    return { questId, status: 'in_progress' };
  }
}
