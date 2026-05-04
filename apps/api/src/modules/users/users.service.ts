import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { eq } from 'drizzle-orm';
import { DRIZZLE, type Db } from '../../database/database.module';
import { users, destinations } from '../../database/schema';
import { xpForNextLevel, levelFromXp } from '../progression/xp.util';

@Injectable()
export class UsersService {
  constructor(@Inject(DRIZZLE) private readonly db: Db) {}

  async findById(id: string) {
    const [row] = await this.db
      .select({
        user: users,
        activeDest: {
          id: destinations.id,
          slug: destinations.slug,
          name: destinations.name,
        },
      })
      .from(users)
      .leftJoin(destinations, eq(users.activeDestinationId, destinations.id))
      .where(eq(users.id, id))
      .limit(1);

    if (!row) throw new NotFoundException('User not found');
    const { user, activeDest } = row;
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
      activeDestination: activeDest?.id ? activeDest : null,
    };
  }

  async updateProfile(
    id: string,
    patch: {
      displayName?: string;
      homeRegion?: string;
      avatarUrl?: string;
      activeDestinationId?: string | null;
    },
  ) {
    const [updated] = await this.db
      .update(users)
      .set(patch)
      .where(eq(users.id, id))
      .returning();
    if (!updated) throw new NotFoundException('User not found');
    return this.findById(id);
  }
}
