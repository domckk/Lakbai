import { BadRequestException, Inject, Injectable, NotFoundException } from '@nestjs/common';
import { and, asc, eq, sql } from 'drizzle-orm';
import { DRIZZLE, type Db } from '../../database/database.module';
import { checkpointVisits, checkpoints, quests, userQuests, userStamps } from '../../database/schema';
import { QrService } from './qr.service';
import { AntiCheatService } from './anti-cheat.service';
import { ProgressionService } from '../progression/progression.service';
import type { CheckInDto } from './dto';

export interface CheckInResult {
  valid: boolean;
  reason?: string;
  xp_awarded?: number;
  stamp?: { id: string; name: string; rarity: string; artUrl: string | null };
  level_up?: { from: number; to: number };
  badges_unlocked?: { id: string; name: string }[];
  quest_complete?: boolean;
  next_checkpoint?: { id: string; title: string };
}

@Injectable()
export class CheckpointsService {
  constructor(
    @Inject(DRIZZLE) private readonly db: Db,
    private readonly qr: QrService,
    private readonly antiCheat: AntiCheatService,
    private readonly progression: ProgressionService,
  ) {}

  async checkIn(userId: string, checkpointId: string, dto: CheckInDto): Promise<CheckInResult> {
    const [cp] = await this.db
      .select()
      .from(checkpoints)
      .where(eq(checkpoints.id, checkpointId))
      .limit(1);
    if (!cp) throw new NotFoundException('Checkpoint not found');

    // 1. Already visited? (idempotent — return previous success)
    const [existing] = await this.db
      .select()
      .from(checkpointVisits)
      .where(and(eq(checkpointVisits.userId, userId), eq(checkpointVisits.checkpointId, checkpointId)))
      .limit(1);
    if (existing?.isValid) {
      return { valid: true, reason: 'ALREADY_VISITED' };
    }

    // 2. GPS proximity check via PostGIS ST_DWithin.
    const radius = cp.geoRadiusM ?? 50;
    const within = await this.db.execute<{ ok: boolean }>(sql`
      SELECT ST_DWithin(
        ${checkpoints.geoPoint},
        ST_SetSRID(ST_MakePoint(${dto.lng}, ${dto.lat}), 4326)::geography,
        ${radius}
      ) AS ok
      FROM ${checkpoints} WHERE ${checkpoints.id} = ${checkpointId}
    `);
    if (!within.rows[0]?.ok) {
      await this.recordFailedVisit(userId, checkpointId, dto, 'OUT_OF_RANGE');
      return { valid: false, reason: 'OUT_OF_RANGE' };
    }

    // 3. QR verification when required.
    if ((cp.validationType ?? 'gps').includes('qr')) {
      if (!dto.qr_token || !cp.qrSecret) {
        return { valid: false, reason: 'QR_REQUIRED' };
      }
      if (!this.qr.verify(dto.qr_token, cp.id, cp.qrSecret)) {
        await this.recordFailedVisit(userId, checkpointId, dto, 'QR_INVALID');
        return { valid: false, reason: 'QR_INVALID' };
      }
    }

    // 4. Anti-cheat heuristics.
    const cheat = await this.antiCheat.evaluate({
      userId,
      lat: dto.lat,
      lng: dto.lng,
      accuracyM: dto.accuracy_m,
      clientTs: dto.client_ts,
    });
    if (cheat.flag) {
      await this.recordFailedVisit(userId, checkpointId, dto, cheat.reason ?? 'CHEAT');
      return { valid: false, reason: cheat.reason };
    }

    // 5. Persist + award. Single transaction.
    const result = await this.db.transaction(async (tx) => {
      await tx.insert(checkpointVisits).values({
        userId,
        checkpointId,
        deviceLat: dto.lat,
        deviceLng: dto.lng,
        deviceAccuracyM: dto.accuracy_m,
        validationMethod: cp.validationType,
        isValid: true,
      });

      // ensure user_quests row exists
      await tx
        .insert(userQuests)
        .values({ userId, questId: cp.questId, status: 'in_progress' })
        .onConflictDoNothing();

      if (cp.stampId) {
        await tx.insert(userStamps).values({ userId, stampId: cp.stampId }).onConflictDoNothing();
      }

      const events = await this.progression.awardCheckpoint(tx, userId, cp);
      return events;
    });

    return { valid: true, ...result };
  }

  private async recordFailedVisit(userId: string, checkpointId: string, dto: CheckInDto, reason: string) {
    await this.db
      .insert(checkpointVisits)
      .values({
        userId,
        checkpointId,
        deviceLat: dto.lat,
        deviceLng: dto.lng,
        deviceAccuracyM: dto.accuracy_m,
        validationMethod: 'gps',
        isValid: false,
        flaggedReason: reason,
      })
      .onConflictDoNothing();
  }

  async listForQuest(questId: string) {
    return this.db
      .select()
      .from(checkpoints)
      .where(eq(checkpoints.questId, questId))
      .orderBy(asc(checkpoints.sortOrder));
  }

  /** Generate a fresh QR token for a checkpoint (used by partner devices/posters). */
  async issueQrToken(checkpointId: string) {
    const [cp] = await this.db
      .select({ id: checkpoints.id, secret: checkpoints.qrSecret })
      .from(checkpoints)
      .where(eq(checkpoints.id, checkpointId))
      .limit(1);
    if (!cp || !cp.secret) throw new BadRequestException('Checkpoint has no QR configured');
    return { token: this.qr.generate(cp.id, cp.secret), ttlSec: 120 };
  }
}
