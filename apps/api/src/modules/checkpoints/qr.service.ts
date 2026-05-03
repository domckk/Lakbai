import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createHmac, timingSafeEqual } from 'node:crypto';

/**
 * QR token format:  v1.<epoch_minute>.<base64url(HMAC-SHA256(secret, checkpointId|epoch_minute))>
 * Tokens accepted within ±MAX_AGE_MIN of current minute.
 */
@Injectable()
export class QrService {
  private static readonly MAX_AGE_MIN = 2;

  constructor(private readonly config: ConfigService) {}

  generate(checkpointId: string, checkpointSecret: string): string {
    const epochMin = Math.floor(Date.now() / 60_000);
    const sig = this.sign(checkpointId, checkpointSecret, epochMin);
    return `v1.${epochMin}.${sig}`;
  }

  verify(token: string, checkpointId: string, checkpointSecret: string): boolean {
    if (!token) return false;
    const parts = token.split('.');
    if (parts.length !== 3 || parts[0] !== 'v1') return false;
    const epochMin = parseInt(parts[1], 10);
    if (!Number.isFinite(epochMin)) return false;

    const now = Math.floor(Date.now() / 60_000);
    if (Math.abs(now - epochMin) > QrService.MAX_AGE_MIN) return false;

    const expected = this.sign(checkpointId, checkpointSecret, epochMin);
    const a = Buffer.from(expected);
    const b = Buffer.from(parts[2]);
    if (a.length !== b.length) return false;
    return timingSafeEqual(a, b);
  }

  private sign(checkpointId: string, checkpointSecret: string, epochMin: number): string {
    const globalSecret = this.config.get<string>('QR_HMAC_SECRET') ?? '';
    const key = `${globalSecret}:${checkpointSecret}`;
    return createHmac('sha256', key).update(`${checkpointId}|${epochMin}`).digest('base64url');
  }
}
