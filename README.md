# Trail Quest

Gamified digital tourism platform — explore, earn, collect.
MVP pilot: **Ilocos Norte, Philippines**.

## Monorepo layout

```
trailquest/
├── apps/
│   ├── api/        NestJS backend (REST API, PostGIS, Redis, JWT auth)
│   └── web/        Next.js partner dashboard (Tailwind CSS, Zustand)
├── mobile/         Flutter mobile app (iOS + Android)
├── packages/
│   └── shared-types/   Shared TypeScript interfaces (User, Quest, Checkpoint, etc.)
├── docker-compose.yml   Postgres+PostGIS and Redis for local dev
├── pnpm-workspace.yaml  Monorepo configuration
└── README.md, INTEGRATION.md
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Backend | NestJS 10, Drizzle ORM, PostgreSQL + PostGIS, Redis |
| Frontend (Web) | Next.js 14, Tailwind CSS, Zustand |
| Frontend (Mobile) | Flutter + Dart |
| Shared | TypeScript types package |
| Monorepo | pnpm workspaces |

## Prerequisites

- Node.js 20.11+
- pnpm 9.12+ (`npm install -g pnpm`)
- Docker Desktop
- Flutter 3.24+ (for mobile development)

## Quick Start

```bash
# 1. Install dependencies
pnpm install

# 2. Set up environment
cp .env.example .env

# 3. Start database services
pnpm db:up

# 4. Run migrations
pnpm db:migrate

# 5. Seed Ilocos Norte test data
pnpm db:seed

# 6. Start all apps in development
pnpm dev
```

**Access points:**
- API: `http://localhost:4000` (Swagger at `/docs`)
- Web Dashboard: `http://localhost:3001`
- Database: `postgresql://trailquest:trailquest_dev@localhost:5432/trailquest`

## Project Structure

### API (`apps/api`)
RESTful backend with NestJS, featuring:
- **Auth Module**: JWT-based registration, login, token refresh
- **Destination Module**: Tourism locations with PostGIS geo-indexing
- **Quest Module**: Quest definitions and difficulty levels
- **Checkpoint Module**: Location-based check-ins with QR code verification
- **Passport Module**: User progression, XP, levels, badges
- **Reward Module**: Reward distribution and redemption
- **Leaderboard Module**: Time-based rankings (weekly, monthly, all-time)

### Web Dashboard (`apps/web`)
Next.js partner/admin portal with:
- **Dashboard**: Overview stats and recent activity
- **Destination Management**: CRUD for tourism locations
- **Quest Management**: Create and manage quests with checkpoints
- **Analytics**: Performance metrics, visitor trends, quest completion rates

### Shared Types (`packages/shared-types`)
TypeScript interfaces used across all projects:
```typescript
- User, Partner, UserRole
- Destination, DestinationCategory  
- Quest, DifficultyLevel
- Checkpoint, CheckpointCheckIn
- Passport, Badge
- Reward, RewardType
- LeaderboardEntry, Leaderboard
```

## Common Commands

```bash
# Development
pnpm dev                    # Run all apps
pnpm dev --filter web      # Run only web dashboard

# Building
pnpm build                  # Build all packages
pnpm build --filter @trailquest/api

# Testing
pnpm test                   # Run all tests
pnpm lint                   # Lint all code
pnpm typecheck              # Type checking

# Database
pnpm db:up                  # Start Postgres + Redis
pnpm db:down                # Stop services
pnpm db:migrate             # Run migrations
pnpm db:seed                # Load test data
pnpm db:reset               # Full reset (down + up + migrate + seed)
```

## API Endpoints

### Authentication
```
POST   /auth/register       Register new user
POST   /auth/login          Sign in
POST   /auth/refresh        Refresh access token
```

### Destinations
```
GET    /destinations        List all destinations
POST   /destinations        Create new destination
GET    /destinations/:id    Get destination details
PUT    /destinations/:id    Update destination
DELETE /destinations/:id    Delete destination
```

### Quests
```
GET    /quests              List all quests
POST   /quests              Create new quest
GET    /quests/:id          Get quest details
GET    /quests/:id/checkpoints  Get quest waypoints
```

### Checkpoints
```
POST   /checkpoints/checkin              Check-in at location
POST   /checkpoints/verify-qr            Verify QR code
GET    /checkpoints/:questId/all         Get all checkpoints for quest
```

### Passports & Progression
```
GET    /passports/me        Get user passport & progress
GET    /passports/:id/stats Get user statistics
```

### Leaderboards
```
GET    /leaderboards/weekly      Weekly top explorers
GET    /leaderboards/monthly     Monthly top explorers
GET    /leaderboards/all-time    All-time top explorers
```

## Environment Variables

Copy `.env.example` to `.env` and update:

```env
# Database
POSTGRES_USER=trailquest
POSTGRES_PASSWORD=trailquest_dev
POSTGRES_DB=trailquest

# API
NODE_ENV=development
API_PORT=4000
DATABASE_URL=postgresql://trailquest:trailquest_dev@localhost:5432/trailquest
REDIS_URL=redis://localhost:6379
JWT_ACCESS_SECRET=change-me
JWT_ACCESS_TTL=15m
JWT_REFRESH_TTL=30d

# Web Dashboard
NEXT_PUBLIC_API_URL=http://localhost:4000
```

See `.env.local.template` for a complete development example.

## Documentation

- **[INTEGRATION.md](./INTEGRATION.md)** — Complete integration guide, architecture, deployment
- API Documentation — Available at `http://localhost:4000/docs` (Swagger UI)

## Deployment

### Using Docker

```bash
# Build API image
docker build -f apps/api/Dockerfile -t trailquest-api .

# Build Web image  
docker build -f apps/web/Dockerfile -t trailquest-web .

# Run with docker-compose
docker-compose -f docker-compose.prod.yml up
```

### Cloud Deployment (Vercel, Railway, Render)

- **Web**: Deploy `apps/web` to Vercel
- **API**: Deploy `apps/api` to Railway or Render
- **Database**: Use managed PostgreSQL with PostGIS extension

## Troubleshooting

**API won't start:**
```bash
pnpm db:up
pnpm db:migrate
npm run dev --filter @trailquest/api
```

**Web can't reach API:**
```bash
# Check NEXT_PUBLIC_API_URL
curl http://localhost:4000/health
```

**Module not found:**
```bash
pnpm install
pnpm store prune
```

## Project Timeline

✅ Monorepo setup (pnpm, docker-compose, configs)  
✅ NestJS API foundation  
✅ Core domain modules (users, destinations, quests, checkpoints)  
✅ Progression system (passports, rewards, leaderboards)  
✅ Database migrations + Ilocos Norte seed data  
✅ Flutter mobile scaffold  
✅ Next.js web dashboard  
✅ Shared types package  

## Next Steps

- [ ] Connect Flutter mobile app to API
- [ ] Authentication UI (login/register screens)
- [ ] Real-time quest tracking with WebSockets
- [ ] In-app notifications (push notifications)
- [ ] Reward redemption flow
- [ ] Admin moderation tools
- [ ] Analytics dashboards for partners

## Contributing

1. Branch from `main`
2. Use conventional commits: `feat:`, `fix:`, `docs:`
3. Run `pnpm typecheck && pnpm lint` before pushing
4. Create PR with description

## License

Proprietary — Trail Quest 2024

## Contact

For questions or collaboration: [contact info]

## Mobile (Flutter)

```bash
cd mobile
flutter pub get
flutter run
```

The app reads `API_BASE_URL` from `mobile/lib/core/config.dart` — point it to your dev API.

## Stack

| Layer | Choice |
|---|---|
| Mobile | Flutter + Dart |
| Web (partners + admin) | Next.js 15 (App Router) + TypeScript |
| API | NestJS + TypeScript + Drizzle ORM |
| Database | PostgreSQL 16 + PostGIS 3.4 |
| Cache / leaderboards | Redis 7 |
| Maps | Mapbox GL |
| Auth | JWT (access + refresh) — Supabase Auth in production |
| Cloud | GCP Cloud Run + Cloud SQL (planned) |

See the founding architecture doc for the full rationale.

## MVP scope (8–12 weeks)

A user in Laoag can pick up the app, complete a 5-checkpoint Ilocos Norte heritage quest,
earn a stamp, and redeem one partner discount.

## License

UNLICENSED — proprietary, all rights reserved.
