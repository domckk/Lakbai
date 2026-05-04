import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { envValidationSchema } from './config/env.validation';
import { DatabaseModule } from './database/database.module';
import { RedisModule } from './redis/redis.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { DestinationsModule } from './modules/destinations/destinations.module';
import { QuestsModule } from './modules/quests/quests.module';
import { CheckpointsModule } from './modules/checkpoints/checkpoints.module';
import { PassportsModule } from './modules/passports/passports.module';
import { RewardsModule } from './modules/rewards/rewards.module';
import { LeaderboardsModule } from './modules/leaderboards/leaderboards.module';
import { ProgressionModule } from './modules/progression/progression.module';
import { BadgesModule } from './modules/badges/badges.module';
import { NotificationsModule } from './modules/notifications/notifications.module';
import { HealthController } from './health.controller';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      cache: true,
      validate: (env) => envValidationSchema.parse(env),
    }),
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 120 }]),
    DatabaseModule,
    RedisModule,
    AuthModule,
    UsersModule,
    DestinationsModule,
    QuestsModule,
    CheckpointsModule,
    PassportsModule,
    RewardsModule,
    LeaderboardsModule,
    ProgressionModule,
    BadgesModule,
    NotificationsModule,
  ],
  controllers: [HealthController],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_INTERCEPTOR, useClass: LoggingInterceptor },
  ],
})
export class AppModule {}
