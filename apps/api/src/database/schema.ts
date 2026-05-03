/**
 * Drizzle schema mirrors the SQL in migrations/0000_init.sql.
 * PostGIS columns (geography/POINT/LINESTRING/POLYGON) are not first-class in
 * drizzle yet — we type them as `customType<string>` and access them via raw
 * SQL fragments where geographic operations are needed.
 */
import { sql } from 'drizzle-orm';
import {
  pgTable,
  uuid,
  varchar,
  text,
  integer,
  smallint,
  boolean,
  timestamp,
  bigserial,
  primaryKey,
  unique,
  index,
  customType,
  jsonb,
  doublePrecision,
  real,
} from 'drizzle-orm/pg-core';

const geography = customType<{ data: string; driverData: string }>({
  dataType() {
    return 'geography';
  },
});

const citext = customType<{ data: string; driverData: string }>({
  dataType() {
    return 'citext';
  },
});

export const users = pgTable(
  'users',
  {
    id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
    email: citext('email').notNull().unique(),
    username: varchar('username', { length: 32 }).notNull().unique(),
    displayName: varchar('display_name', { length: 64 }),
    avatarUrl: text('avatar_url'),
    passwordHash: text('password_hash'),
    xpTotal: integer('xp_total').notNull().default(0),
    level: integer('level').notNull().default(1),
    homeRegion: varchar('home_region', { length: 64 }),
    role: varchar('role', { length: 16 }).notNull().default('tourist'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
    lastSeenAt: timestamp('last_seen_at', { withTimezone: true }),
  },
  (t) => ({
    xpIdx: index('ix_users_xp').on(t.xpTotal),
  }),
);

export const destinations = pgTable('destinations', {
  id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
  slug: varchar('slug', { length: 64 }).notNull().unique(),
  name: varchar('name', { length: 128 }).notNull(),
  region: varchar('region', { length: 64 }),
  countryCode: varchar('country_code', { length: 2 }).notNull().default('PH'),
  bounds: geography('bounds'),
  heroImageUrl: text('hero_image_url'),
  description: text('description'),
  isActive: boolean('is_active').default(true),
});

export const partners = pgTable('partners', {
  id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
  name: varchar('name', { length: 128 }).notNull(),
  category: varchar('category', { length: 32 }),
  destinationId: uuid('destination_id').references(() => destinations.id, { onDelete: 'set null' }),
  geoPoint: geography('geo_point'),
  contactEmail: citext('contact_email'),
  subscriptionTier: varchar('subscription_tier', { length: 16 }).default('free'),
  isVerified: boolean('is_verified').default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
});

export const passportsTable = pgTable('passports', {
  id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
  destinationId: uuid('destination_id')
    .references(() => destinations.id, { onDelete: 'cascade' })
    .notNull(),
  title: varchar('title', { length: 128 }).notNull(),
  themeColor: varchar('theme_color', { length: 7 }),
  coverUrl: text('cover_url'),
  totalStamps: smallint('total_stamps').notNull().default(0),
});

export const stamps = pgTable('stamps', {
  id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
  passportId: uuid('passport_id')
    .references(() => passportsTable.id, { onDelete: 'cascade' })
    .notNull(),
  name: varchar('name', { length: 64 }).notNull(),
  artUrl: text('art_url'),
  rarity: varchar('rarity', { length: 16 }).default('common'),
});

export const quests = pgTable(
  'quests',
  {
    id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
    destinationId: uuid('destination_id')
      .references(() => destinations.id, { onDelete: 'cascade' })
      .notNull(),
    title: varchar('title', { length: 128 }).notNull(),
    summary: text('summary'),
    difficulty: smallint('difficulty').notNull().default(1),
    estDurationMin: integer('est_duration_min'),
    xpReward: integer('xp_reward').notNull().default(0),
    questType: varchar('quest_type', { length: 32 }).default('landmark'),
    startsAt: timestamp('starts_at', { withTimezone: true }),
    endsAt: timestamp('ends_at', { withTimezone: true }),
    isPremium: boolean('is_premium').default(false),
    partnerId: uuid('partner_id').references(() => partners.id, { onDelete: 'set null' }),
    coverImageUrl: text('cover_image_url'),
    createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
  },
  (t) => ({
    destIdx: index('ix_quests_dest').on(t.destinationId),
  }),
);

export const checkpoints = pgTable('checkpoints', {
  id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
  questId: uuid('quest_id')
    .references(() => quests.id, { onDelete: 'cascade' })
    .notNull(),
  sortOrder: smallint('sort_order').notNull(),
  title: varchar('title', { length: 128 }).notNull(),
  description: text('description'),
  validationType: varchar('validation_type', { length: 16 }).notNull().default('gps'),
  geoPoint: geography('geo_point'),
  geoRadiusM: integer('geo_radius_m').default(50),
  qrSecret: text('qr_secret'),
  triviaPayload: jsonb('trivia_payload'),
  xpReward: integer('xp_reward').notNull().default(10),
  stampId: uuid('stamp_id').references(() => stamps.id, { onDelete: 'set null' }),
});

export const userQuests = pgTable(
  'user_quests',
  {
    userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
    questId: uuid('quest_id').references(() => quests.id, { onDelete: 'cascade' }).notNull(),
    status: varchar('status', { length: 16 }).default('in_progress'),
    startedAt: timestamp('started_at', { withTimezone: true }).defaultNow(),
    completedAt: timestamp('completed_at', { withTimezone: true }),
  },
  (t) => ({ pk: primaryKey({ columns: [t.userId, t.questId] }) }),
);

export const checkpointVisits = pgTable(
  'checkpoint_visits',
  {
    id: bigserial('id', { mode: 'number' }).primaryKey(),
    userId: uuid('user_id').notNull(),
    checkpointId: uuid('checkpoint_id').notNull(),
    visitedAt: timestamp('visited_at', { withTimezone: true }).defaultNow(),
    deviceLat: doublePrecision('device_lat'),
    deviceLng: doublePrecision('device_lng'),
    deviceAccuracyM: real('device_accuracy_m'),
    validationMethod: varchar('validation_method', { length: 16 }),
    isValid: boolean('is_valid').default(true),
    flaggedReason: varchar('flagged_reason', { length: 64 }),
  },
  (t) => ({ uniq: unique('uq_visit_per_user_checkpoint').on(t.userId, t.checkpointId) }),
);

export const userStamps = pgTable(
  'user_stamps',
  {
    userId: uuid('user_id').notNull(),
    stampId: uuid('stamp_id').notNull(),
    earnedAt: timestamp('earned_at', { withTimezone: true }).defaultNow(),
  },
  (t) => ({ pk: primaryKey({ columns: [t.userId, t.stampId] }) }),
);

export const rewards = pgTable('rewards', {
  id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
  partnerId: uuid('partner_id').references(() => partners.id, { onDelete: 'cascade' }),
  title: varchar('title', { length: 128 }).notNull(),
  description: text('description'),
  rewardType: varchar('reward_type', { length: 16 }).default('discount'),
  valuePct: smallint('value_pct'),
  costXp: integer('cost_xp').default(0),
  requiredQuestId: uuid('required_quest_id').references(() => quests.id, { onDelete: 'set null' }),
  stockRemaining: integer('stock_remaining'),
  expiresAt: timestamp('expires_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
});

export const userRewards = pgTable('user_rewards', {
  id: bigserial('id', { mode: 'number' }).primaryKey(),
  userId: uuid('user_id').notNull(),
  rewardId: uuid('reward_id').notNull(),
  redemptionCode: varchar('redemption_code', { length: 16 }).notNull().unique(),
  status: varchar('status', { length: 16 }).default('issued'),
  issuedAt: timestamp('issued_at', { withTimezone: true }).defaultNow(),
  redeemedAt: timestamp('redeemed_at', { withTimezone: true }),
});

export const badges = pgTable('badges', {
  id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
  key: varchar('key', { length: 64 }).notNull().unique(),
  name: varchar('name', { length: 128 }).notNull(),
  description: text('description'),
  icon: varchar('icon', { length: 16 }).notNull(),
  tier: varchar('tier', { length: 16 }).notNull().default('bronze'),
  conditionType: varchar('condition_type', { length: 32 }).notNull(),
  conditionValue: integer('condition_value').notNull().default(1),
});

export const userBadges = pgTable(
  'user_badges',
  {
    userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
    badgeId: uuid('badge_id').references(() => badges.id, { onDelete: 'cascade' }).notNull(),
    earnedAt: timestamp('earned_at', { withTimezone: true }).defaultNow(),
  },
  (t) => ({ pk: primaryKey({ columns: [t.userId, t.badgeId] }) }),
);

export const refreshTokens = pgTable('refresh_tokens', {
  id: uuid('id').primaryKey().default(sql`gen_random_uuid()`),
  userId: uuid('user_id').references(() => users.id, { onDelete: 'cascade' }).notNull(),
  tokenHash: text('token_hash').notNull(),
  expiresAt: timestamp('expires_at', { withTimezone: true }).notNull(),
  revokedAt: timestamp('revoked_at', { withTimezone: true }),
  createdAt: timestamp('created_at', { withTimezone: true }).defaultNow(),
});
