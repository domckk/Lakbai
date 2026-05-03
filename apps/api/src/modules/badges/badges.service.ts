import { Inject, Injectable } from '@nestjs/common';
import { and, eq, sql } from 'drizzle-orm';
import { DRIZZLE, type Db } from '../../database/database.module';
import {
  badges,
  userBadges,
  checkpointVisits,
  userQuests,
  userStamps,
} from '../../database/schema';

type Tx = Parameters<Parameters<Db['transaction']>[0]>[0];

@Injectable()
export class BadgesService {
  constructor(@Inject(DRIZZLE) private readonly db: Db) {}

  findAll() {
    return this.db.select().from(badges).orderBy(badges.name);
  }

  async forUser(userId: string) {
    const rows = await this.db.execute<{
      id: string;
      key: string;
      name: string;
      description: string | null;
      icon: string;
      tier: string;
      earned_at: Date | null;
    }>(sql`
      SELECT b.id, b.key, b.name, b.description, b.icon, b.tier,
             ub.earned_at
      FROM   ${badges} b
      LEFT JOIN ${userBadges} ub
             ON ub.badge_id = b.id AND ub.user_id = ${userId}
      ORDER BY ub.earned_at DESC NULLS LAST, b.name
    `);
    return rows.rows;
  }

  async checkAndAward(
    tx: Tx,
    userId: string,
    userXp: number,
    userLevel: number,
  ): Promise<Array<{ id: string; key: string; name: string; icon: string; tier: string }>> {
    const unearned = await tx
      .select()
      .from(badges)
      .where(
        sql`${badges.id} NOT IN (
          SELECT badge_id FROM user_badges WHERE user_id = ${userId}
        )`,
      );

    if (unearned.length === 0) return [];

    const stats: Record<string, number> = {
      level_reached: userLevel,
      xp_total: userXp,
    };

    if (unearned.some((b) => b.conditionType === 'first_checkin' || b.conditionType === 'checkpoints_total')) {
      const [{ n }] = await tx
        .select({ n: sql<number>`count(*)::int` })
        .from(checkpointVisits)
        .where(and(eq(checkpointVisits.userId, userId), eq(checkpointVisits.isValid, true)));
      stats['first_checkin'] = n;
      stats['checkpoints_total'] = n;
    }

    if (unearned.some((b) => b.conditionType === 'quests_completed')) {
      const [{ n }] = await tx
        .select({ n: sql<number>`count(*)::int` })
        .from(userQuests)
        .where(and(eq(userQuests.userId, userId), eq(userQuests.status, 'completed')));
      stats['quests_completed'] = n;
    }

    if (unearned.some((b) => b.conditionType === 'stamps_collected')) {
      const [{ n }] = await tx
        .select({ n: sql<number>`count(*)::int` })
        .from(userStamps)
        .where(eq(userStamps.userId, userId));
      stats['stamps_collected'] = n;
    }

    const awarded: Array<{ id: string; key: string; name: string; icon: string; tier: string }> = [];

    for (const badge of unearned) {
      const stat = stats[badge.conditionType] ?? 0;
      if (stat >= badge.conditionValue) {
        await tx.insert(userBadges).values({ userId, badgeId: badge.id }).onConflictDoNothing();
        awarded.push({ id: badge.id, key: badge.key, name: badge.name, icon: badge.icon, tier: badge.tier });
      }
    }

    return awarded;
  }
}
