import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import { DRIZZLE, type Db } from '../../database/database.module';
import { users } from '../../database/schema';
import { xpForNextLevel, levelFromXp } from '../progression/xp.util';

@Injectable()
export class UsersService {
  constructor(@Inject(DRIZZLE) private readonly db: Db) {}

  async findById(id: string) {
    const [user] = await this.db.select().from(users).where(eq(users.id, id)).limit(1);
    if (!user) throw new NotFoundException('User not found');
    const lvl = levelFromXp(user.xpTotal);
    return {
      id: user.id,
      email: user.email,
      username: user.username,
      displayName: user.displayName,
      avatarUrl: user.avatarUrl,
      xpTotal: user.xpTotal,
      level: lvl,
      xpForNextLevel: xpForNextLevel(lvl),
      role: user.role,
      homeRegion: user.homeRegion,
      createdAt: user.createdAt,
    };
  }

  async updateProfile(id: string, patch: { displayName?: string; homeRegion?: string; avatarUrl?: string }) {
    const [updated] = await this.db.update(users).set(patch).where(eq(users.id, id)).returning();
    if (!updated) throw new NotFoundException('User not found');
    return this.findById(id);
  }
}
