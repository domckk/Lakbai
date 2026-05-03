import { Inject, Injectable } from '@nestjs/common';
import { and, eq, sql } from 'drizzle-orm';
import Redis from 'ioredis';
import { DRIZZLE, type Db } from '../../database/database.module';
import { REDIS } from '../../redis/redis.module';
import {
  checkpoints,
  checkpointVisits,
  quests,
  stamps,
  userQuests,
  users,
} from '../../database/schema';
import { levelFromXp } from './xp.util';
import { BadgesService } from '../badges/badges.service';

type Tx = Parameters<Parameters<Db['transaction']>[0]>[0];

interface CheckpointRow {
  id: string;
  questId: string;
  xpReward: number;
  stampId: string | null;
}

@Injectable()
export class ProgressionService {
  constructor(
    @Inject(DRIZZLE) private readonly db: Db,
    @Inject(REDIS) private readonly redis: Redis,
    private readonly badgesService: BadgesService,
  ) {}

  async awardCheckpoint(tx: Tx, userId: string, cp: CheckpointRow) {
    const [{ xpBefore, levelBefore }] = await tx
      .select({ xpBefore: users.xpTotal, levelBefore: users.level })
      .from(users)
      .where(eq(users.id, userId));

    const xpAwarded = cp.xpReward;
    const xpAfter = xpBefore + xpAwarded;
    const levelAfter = levelFromXp(xpAfter);

    await tx
      .update(users)
      .set({ xpTotal: xpAfter, level: levelAfter })
      .where(eq(users.id, userId));

    // Update Redis leaderboards (global all-time, weekly).
    const week = isoWeekKey(new Date());
    await this.redis
      .pipeline()
      .zincrby('lb:global:alltime', xpAwarded, userId)
      .zincrby(`lb:global:weekly:${week}`, xpAwarded, userId)
      .expire(`lb:global:weekly:${week}`, 14 * 24 * 60 * 60)
      .exec();

    // Stamp metadata.
    let stamp: { id: string; name: string; rarity: string; artUrl: string | null } | undefined;
    if (cp.stampId) {
      const [s] = await tx
        .select({ id: stamps.id, name: stamps.name, rarity: stamps.rarity, artUrl: stamps.artUrl })
        .from(stamps)
        .where(eq(stamps.id, cp.stampId));
      if (s) stamp = { id: s.id, name: s.name, rarity: s.rarity ?? 'common', artUrl: s.artUrl };
    }

    // Check quest completion: did the user just visit the last checkpoint?
    const totalCps = await tx
      .select({ n: sql<number>`count(*)::int` })
      .from(checkpoints)
      .where(eq(checkpoints.questId, cp.questId));
    const visitedCps = await tx
      .select({ n: sql<number>`count(*)::int` })
      .from(checkpointVisits)
      .innerJoin(checkpoints, eq(checkpointVisits.checkpointId, checkpoints.id))
      .where(
        and(
          eq(checkpointVisits.userId, userId),
          eq(checkpointVisits.isValid, true),
          eq(checkpoints.questId, cp.questId),
        ),
      );

    const total = totalCps[0]?.n ?? 0;
    const visited = visitedCps[0]?.n ?? 0;
    let questComplete = false;
    let questBonusXp = 0;
    if (total > 0 && visited >= total) {
      questComplete = true;
      await tx
        .update(userQuests)
        .set({ status: 'completed', completedAt: new Date() })
        .where(and(eq(userQuests.userId, userId), eq(userQuests.questId, cp.questId)));

      const [q] = await tx
        .select({ xp: quests.xpReward })
        .from(quests)
        .where(eq(quests.id, cp.questId));
      if (q?.xp) {
        questBonusXp = q.xp;
        await tx
          .update(users)
          .set({ xpTotal: xpAfter + questBonusXp, level: levelFromXp(xpAfter + questBonusXp) })
          .where(eq(users.id, userId));
      }
    }

    // Find next checkpoint in sort order.
    const next = await tx
      .select({ id: checkpoints.id, title: checkpoints.title, sortOrder: checkpoints.sortOrder })
      .from(checkpoints)
      .where(eq(checkpoints.questId, cp.questId))
      .orderBy(checkpoints.sortOrder);
    const visitedIds = new Set(
      (
        await tx
          .select({ id: checkpointVisits.checkpointId })
          .from(checkpointVisits)
          .where(and(eq(checkpointVisits.userId, userId), eq(checkpointVisits.isValid, true)))
      ).map((r) => r.id),
    );
    const nextCp = next.find((c) => !visitedIds.has(c.id));

    const xpFinal = xpAfter + questBonusXp;
    const levelFinal = levelFromXp(xpFinal);
    const badgesUnlocked = await this.badgesService.checkAndAward(tx, userId, xpFinal, levelFinal);

    return {
      xp_awarded: xpAwarded,
      stamp,
      level_up: levelFinal > levelBefore ? { from: levelBefore, to: levelFinal } : undefined,
      quest_complete: questComplete,
      next_checkpoint: nextCp ? { id: nextCp.id, title: nextCp.title } : undefined,
      badges_unlocked: badgesUnlocked,
    };
  }
}

function isoWeekKey(d: Date): string {
  const date = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
  const dayNum = (date.getUTCDay() + 6) % 7;
  date.setUTCDate(date.getUTCDate() - dayNum + 3);
  const firstThursday = new Date(Date.UTC(date.getUTCFullYear(), 0, 4));
  const week =
    1 + Math.round(((date.getTime() - firstThursday.getTime()) / 86_400_000 - 3) / 7);
  return `${date.getUTCFullYear()}W${String(week).padStart(2, '0')}`;
}
