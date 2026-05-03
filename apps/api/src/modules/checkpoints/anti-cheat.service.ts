import { Inject, Injectable } from '@nestjs/common';
import { desc, eq } from 'drizzle-orm';
import Redis from 'ioredis';
import { DRIZZLE, type Db } from '../../database/database.module';
import { REDIS } from '../../redis/redis.module';
import { checkpointVisits } from '../../database/schema';

export interface CheatSignal {
  flag: boolean;
  reason?: string;
}

interface EvalInput {
  userId: string;
  lat: number;
  lng: number;
  accuracyM: number;
  clientTs?: number;
}

@Injectable()
export class AntiCheatService {
  constructor(
    @Inject(DRIZZLE) private readonly db: Db,
    @Inject(REDIS) private readonly redis: Redis,
  ) {}

  async evaluate(input: EvalInput): Promise<CheatSignal> {
    // 1. Accuracy gate (handled here as belt-and-suspenders alongside DTO validator).
    if (input.accuracyM > 35) return { flag: true, reason: 'LOW_ACCURACY' };

    // 2. Rate limit — max 60 valid check-ins per user per rolling 24h window.
    const rateKey = `cheat:rate:${input.userId}`;
    const count = await this.redis.incr(rateKey);
    if (count === 1) await this.redis.expire(rateKey, 24 * 60 * 60);
    if (count > 60) return { flag: true, reason: 'RATE_LIMIT' };

    // 3. Velocity check — compare against last visit.
    const [last] = await this.db
      .select({
        lat: checkpointVisits.deviceLat,
        lng: checkpointVisits.deviceLng,
        at: checkpointVisits.visitedAt,
      })
      .from(checkpointVisits)
      .where(eq(checkpointVisits.userId, input.userId))
      .orderBy(desc(checkpointVisits.visitedAt))
      .limit(1);

    if (last?.lat != null && last?.lng != null && last.at) {
      const meters = haversine(last.lat, last.lng, input.lat, input.lng);
      const seconds = Math.max(1, (Date.now() - new Date(last.at).getTime()) / 1000);
      const kmh = (meters / seconds) * 3.6;
      if (kmh > 200) return { flag: true, reason: 'IMPOSSIBLE_VELOCITY' };
    }

    // 4. Client clock sanity: ±10 min from server.
    if (input.clientTs && Math.abs(Date.now() - input.clientTs) > 10 * 60 * 1000) {
      return { flag: true, reason: 'CLOCK_SKEW' };
    }

    return { flag: false };
  }
}

function haversine(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6_371_000;
  const toRad = (x: number) => (x * Math.PI) / 180;
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  return 2 * R * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}
