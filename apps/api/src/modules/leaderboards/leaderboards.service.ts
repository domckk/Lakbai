import { Inject, Injectable } from '@nestjs/common';
import { inArray } from 'drizzle-orm';
import Redis from 'ioredis';
import { REDIS } from '../../redis/redis.module';
import { DRIZZLE, type Db } from '../../database/database.module';
import { users } from '../../database/schema';

@Injectable()
export class LeaderboardsService {
  constructor(
    @Inject(REDIS) private readonly redis: Redis,
    @Inject(DRIZZLE) private readonly db: Db,
  ) {}

  /** scope: 'global' | 'weekly' | 'destination:<slug>' */
  async top(scope: string, limit = 50) {
    const key = this.keyFor(scope);
    const raw = await this.redis.zrevrange(key, 0, limit - 1, 'WITHSCORES');
    const entries: { userId: string; score: number }[] = [];
    for (let i = 0; i < raw.length; i += 2) {
      entries.push({ userId: raw[i], score: Number(raw[i + 1]) });
    }
    if (entries.length === 0) return [];

    const userRows = await this.db
      .select({
        id: users.id,
        username: users.username,
        displayName: users.displayName,
        avatarUrl: users.avatarUrl,
        level: users.level,
      })
      .from(users)
      .where(inArray(users.id, entries.map((e) => e.userId)));
    const byId = new Map(userRows.map((u) => [u.id, u]));

    return entries.map((e, i) => ({
      rank: i + 1,
      score: e.score,
      user: byId.get(e.userId) ?? { id: e.userId, username: 'unknown' },
    }));
  }

  private keyFor(scope: string): string {
    if (scope === 'global') return 'lb:global:alltime';
    if (scope === 'weekly') return `lb:global:weekly:${isoWeekKey(new Date())}`;
    if (scope.startsWith('destination:')) return `lb:dest:${scope.slice('destination:'.length)}:alltime`;
    return 'lb:global:alltime';
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
