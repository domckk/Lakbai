import { BadRequestException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import { and, eq, sql } from 'drizzle-orm';
import { randomBytes } from 'node:crypto';
import { DRIZZLE, type Db } from '../../database/database.module';
import { rewards, userRewards, userQuests } from '../../database/schema';

@Injectable()
export class RewardsService {
  constructor(@Inject(DRIZZLE) private readonly db: Db) {}

  /** Rewards available to the current user — unlocked or unrestricted. */
  async availableForUser(userId: string) {
    const rows = await this.db.execute<{
      id: string;
      title: string;
      description: string | null;
      reward_type: string;
      value_pct: number | null;
      partner_id: string | null;
      required_quest_id: string | null;
      unlocked: boolean;
    }>(sql`
      SELECT r.id, r.title, r.description, r.reward_type, r.value_pct, r.partner_id, r.required_quest_id,
             (r.required_quest_id IS NULL
              OR EXISTS (
                SELECT 1 FROM ${userQuests} uq
                WHERE uq.user_id = ${userId} AND uq.quest_id = r.required_quest_id AND uq.status = 'completed'
              )
             ) AS unlocked
      FROM ${rewards} r
      WHERE r.expires_at IS NULL OR r.expires_at > now()
      ORDER BY unlocked DESC, r.created_at DESC
    `);
    return rows.rows;
  }

  /** Wallet view — already-issued vouchers. */
  async wallet(userId: string) {
    const rows = await this.db.execute<{
      id: number;
      reward_id: string;
      title: string;
      description: string | null;
      redemption_code: string;
      status: string;
      issued_at: Date;
    }>(sql`
      SELECT ur.id, ur.reward_id, r.title, r.description, ur.redemption_code, ur.status, ur.issued_at
      FROM ${userRewards} ur
      JOIN ${rewards} r ON r.id = ur.reward_id
      WHERE ur.user_id = ${userId}
      ORDER BY ur.issued_at DESC
    `);
    return rows.rows;
  }

  async redeem(userId: string, rewardId: string) {
    const [reward] = await this.db.select().from(rewards).where(eq(rewards.id, rewardId)).limit(1);
    if (!reward) throw new NotFoundException('Reward not found');

    if (reward.requiredQuestId) {
      const [q] = await this.db
        .select()
        .from(userQuests)
        .where(
          and(
            eq(userQuests.userId, userId),
            eq(userQuests.questId, reward.requiredQuestId),
            eq(userQuests.status, 'completed'),
          ),
        )
        .limit(1);
      if (!q) throw new BadRequestException('Reward locked — required quest not completed');
    }

    const [existing] = await this.db
      .select()
      .from(userRewards)
      .where(and(eq(userRewards.userId, userId), eq(userRewards.rewardId, rewardId)))
      .limit(1);
    if (existing) return existing;

    const code = randomBytes(6).toString('hex').toUpperCase();
    const [issued] = await this.db
      .insert(userRewards)
      .values({ userId, rewardId, redemptionCode: code })
      .returning();
    return issued;
  }
}
