import { Inject, Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import { eq, and, isNull, gt } from 'drizzle-orm';
import argon2 from 'argon2';
import { randomBytes, createHash } from 'node:crypto';

const ARGON2_OPTS = {
  type: argon2.argon2id,
  memoryCost: 19456, // 19 MiB — OWASP-recommended minimum, down from 64 MiB default
  timeCost: 2,
  parallelism: 1,
} as const;
import { DRIZZLE, type Db } from '../../database/database.module';
import { users, refreshTokens } from '../../database/schema';
import type { RegisterDto, LoginDto } from './dto';

interface JwtPayload {
  sub: string;
  email: string;
  role: 'tourist' | 'partner' | 'lgu_admin' | 'staff';
}

@Injectable()
export class AuthService {
  constructor(
    @Inject(DRIZZLE) private readonly db: Db,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.db.select().from(users).where(eq(users.email, dto.email)).limit(1);
    if (existing.length) throw new ConflictException('Email already registered');

    const passwordHash = await argon2.hash(dto.password, ARGON2_OPTS);
    const [user] = await this.db
      .insert(users)
      .values({
        email: dto.email,
        username: dto.username,
        displayName: dto.username,
        passwordHash,
      })
      .returning();
    return this.issueTokens(user.id, user.email, user.role as JwtPayload['role']);
  }

  async login(dto: LoginDto) {
    const [user] = await this.db.select().from(users).where(eq(users.email, dto.email)).limit(1);
    if (!user || !user.passwordHash) throw new UnauthorizedException('Invalid credentials');
    const ok = await argon2.verify(user.passwordHash, dto.password);
    if (!ok) throw new UnauthorizedException('Invalid credentials');
    await this.db.update(users).set({ lastSeenAt: new Date() }).where(eq(users.id, user.id));
    return this.issueTokens(user.id, user.email, user.role as JwtPayload['role']);
  }

  async logout(refreshToken: string) {
    const tokenHash = this.hashToken(refreshToken);
    await this.db
      .update(refreshTokens)
      .set({ revokedAt: new Date() })
      .where(and(eq(refreshTokens.tokenHash, tokenHash), isNull(refreshTokens.revokedAt)));
  }

  async refresh(refreshToken: string) {
    const tokenHash = this.hashToken(refreshToken);
    const [row] = await this.db
      .select()
      .from(refreshTokens)
      .where(
        and(
          eq(refreshTokens.tokenHash, tokenHash),
          isNull(refreshTokens.revokedAt),
          gt(refreshTokens.expiresAt, new Date()),
        ),
      )
      .limit(1);
    if (!row) throw new UnauthorizedException('Invalid refresh token');

    await this.db.update(refreshTokens).set({ revokedAt: new Date() }).where(eq(refreshTokens.id, row.id));
    const [user] = await this.db.select().from(users).where(eq(users.id, row.userId)).limit(1);
    if (!user) throw new UnauthorizedException();
    return this.issueTokens(user.id, user.email, user.role as JwtPayload['role']);
  }

  private async issueTokens(userId: string, email: string, role: JwtPayload['role']) {
    const payload: JwtPayload = { sub: userId, email, role };
    const accessToken = await this.jwt.signAsync(payload);
    const refreshToken = randomBytes(48).toString('base64url');
    const ttlDays = this.parseDays(this.config.get<string>('JWT_REFRESH_TTL') ?? '30d');
    const expiresAt = new Date(Date.now() + ttlDays * 24 * 60 * 60 * 1000);

    await this.db.insert(refreshTokens).values({
      userId,
      tokenHash: this.hashToken(refreshToken),
      expiresAt,
    });

    return { accessToken, refreshToken, user: { id: userId, email, role } };
  }

  private hashToken(token: string): string {
    return createHash('sha256').update(token).digest('hex');
  }

  private parseDays(s: string): number {
    const m = s.match(/^(\d+)d$/);
    return m ? parseInt(m[1], 10) : 30;
  }
}
