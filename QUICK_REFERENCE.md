# Trail Quest - Quick Reference

## 🎯 Project Overview

Trail Quest is a **gamified digital tourism platform** that helps tourists explore destinations in Ilocos Norte while earning rewards and competing on leaderboards.

**Tech Stack**: NestJS | Next.js | Flutter | PostgreSQL | Redis | Tailwind | Zustand

## 🗂️ Folder Structure

```
TrailQuest/
├── apps/api/          NestJS backend
├── apps/web/          Next.js dashboard (Partner Portal)
├── mobile/            Flutter mobile app
├── packages/shared-types/  TypeScript types
```

## 🚀 Quick Commands

```bash
# Setup (first time)
pnpm install
pnpm db:up
pnpm db:migrate
pnpm db:seed

# Development
pnpm dev              # Run all apps
pnpm dev --filter web # Run only web

# Building
pnpm build            # Build all
pnpm build --filter @trailquest/api

# Database
pnpm db:reset         # Full reset

# Quality
pnpm lint
pnpm typecheck
pnpm test
```

## 📍 Access Points

| Service | URL | Notes |
|---------|-----|-------|
| API | http://localhost:4000 | Swagger docs at `/docs` |
| Web Dashboard | http://localhost:3001 | Partner portal |
| PostgreSQL | localhost:5432 | Docker service |
| Redis | localhost:6379 | Docker service |

## 🔐 Authentication

All API endpoints (except auth) require JWT token in header:
```
Authorization: Bearer <access_token>
```

**Token Flow**:
1. Register/Login → get `access_token` + `refresh_token`
2. Use `access_token` in requests
3. When expired, use `refresh_token` to get new `access_token`

## 📚 API Endpoints

**Auth**
- `POST /auth/register` - Create account
- `POST /auth/login` - Sign in
- `POST /auth/refresh` - Refresh token

**Destinations** (geo-indexed)
- `GET /destinations` - List all
- `POST /destinations` - Create
- `GET /destinations/:id` - Get details

**Quests**
- `GET /quests` - List all
- `POST /quests` - Create
- `GET /quests/:id` - Get with checkpoints

**Checkpoints** (check-in)
- `POST /checkpoints/checkin` - Record visit
- `POST /checkpoints/verify-qr` - Verify QR code

**Progression**
- `GET /passports/me` - Get user progress
- `GET /leaderboards/weekly` - Rankings

## 🗄️ Database

**Key Tables**:
- `users` - Tourist profiles
- `destinations` - Tourism locations (PostGIS geo-indexed)
- `quests` - Quest definitions
- `checkpoints` - Quest waypoints with QR codes
- `passports` - User progression & XP
- `rewards` - Reward definitions
- `leaderboards` - Cached rankings

**PostGIS Usage**:
```sql
-- Find destinations within 5km
SELECT * FROM destinations 
WHERE ST_DWithin(location, ST_Point(...), 5000);
```

## 📦 Shared Types

Located in `packages/shared-types/src/index.ts`:

```typescript
// User & Auth
User, Partner, UserRole, AuthResponse

// Destinations
Destination, DestinationCategory

// Quests
Quest, DifficultyLevel, Checkpoint, CheckpointCheckIn

// Progression
Passport, Badge, Reward, RewardType

// Leaderboards
LeaderboardEntry, Leaderboard, LeaderboardPeriod

// API
PaginatedResponse<T>, ApiError
```

**Usage**:
```typescript
// In API or Web
import type { User, Quest } from '@trailquest/shared-types';
```

## 🌐 Environment Variables

### API (.env)
```env
NODE_ENV=development
API_PORT=4000
DATABASE_URL=postgresql://...
REDIS_URL=redis://localhost:6379
JWT_ACCESS_SECRET=min-32-chars
JWT_ACCESS_TTL=15m
```

### Web (.env.local)
```env
NEXT_PUBLIC_API_URL=http://localhost:4000
```

## 📱 Mobile Integration

Flutter app connects to same API. Key features:
- Map display with destinations
- Quest tracking with check-ins
- QR code scanning
- User progression display
- Leaderboard rankings

See [MOBILE_INTEGRATION.md](./MOBILE_INTEGRATION.md) for setup details.

## 🐛 Troubleshooting

**API won't start?**
```bash
pnpm db:up
pnpm db:migrate
echo $DATABASE_URL  # verify connection
```

**Web can't reach API?**
```bash
# Check NEXT_PUBLIC_API_URL
curl http://localhost:4000/health
```

**Module not found?**
```bash
pnpm install
pnpm store prune
```

## 🔄 Project Phases

✅ **Phase 1**: Monorepo setup (pnpm, Docker, config)
✅ **Phase 2**: NestJS API foundation + modules
✅ **Phase 3**: Shared TypeScript types
✅ **Phase 4**: Next.js web dashboard
✅ **Phase 5**: Flutter mobile scaffold
✅ **Phase 6**: Database migrations + seed
✅ **Phase 7**: Final integration & wiring

🎯 **Next**: Real-time features, deployment, mobile completion

## 📖 Documentation Files

| File | Purpose |
|------|---------|
| [README.md](./README.md) | Main project overview |
| [INTEGRATION.md](./INTEGRATION.md) | Architecture & detailed guide |
| [MOBILE_INTEGRATION.md](./MOBILE_INTEGRATION.md) | Flutter/API integration |
| [COMPLETION_CHECKLIST.md](./COMPLETION_CHECKLIST.md) | Full checklist of what's done |

## 🚀 Deployment

**API** (Node.js)
```bash
pnpm build --filter @trailquest/api
NODE_ENV=production node dist/main.js
```

**Web** (Vercel)
```bash
vercel deploy --prod
```

**Mobile** (App Store/Play Store)
```bash
flutter build ios --release
flutter build apk --release
```

## 💡 Key Concepts

**XP System**
- Earn XP by checking in at checkpoints
- Progress through levels
- Unlock badges

**Quests**
- Collections of checkpoints
- Difficulty levels (Easy-Extreme)
- Base + bonus XP rewards

**Check-in Flow**
1. User arrives at destination
2. Scans QR code at checkpoint
3. System verifies location + code
4. Records check-in, awards XP

**Leaderboards**
- Weekly, monthly, all-time rankings
- Based on total XP
- Cached for performance

## 📞 Support

For issues or questions:
1. Check documentation (INTEGRATION.md, MOBILE_INTEGRATION.md)
2. Review checklist (COMPLETION_CHECKLIST.md)
3. Run setup scripts (setup.sh or setup.bat)
4. Check environment variables

---

**Status**: MVP Scaffold Complete ✅
**Last Updated**: May 2024
**Version**: 0.1.0
