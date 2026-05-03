import { Controller, Get, Inject } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Pool } from 'pg';
import { PG_POOL } from './database/database.module';
import Redis from 'ioredis';
import { REDIS } from './redis/redis.module';

@ApiTags('system')
@Controller('health')
export class HealthController {
  constructor(
    @Inject(PG_POOL) private readonly pool: Pool,
    @Inject(REDIS) private readonly redis: Redis,
  ) {}

  @Get()
  async check() {
    const [{ now }] = (await this.pool.query<{ now: Date }>('SELECT now()')).rows;
    const pong = await this.redis.ping();
    return {
      status: 'ok',
      service: 'trailquest-api',
      version: '0.1.0',
      time: now,
      redis: pong === 'PONG' ? 'ok' : 'down',
    };
  }
}
