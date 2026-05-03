# Trail Quest - Complete Integration Guide

## Project Structure

```
TrailQuest/
├── apps/
│   ├── api/              # NestJS REST API
│   │   ├── src/
│   │   │   ├── main.ts              # Entry point
│   │   │   ├── app.module.ts        # Root module
│   │   │   ├── config/              # Environment validation
│   │   │   ├── database/            # Drizzle ORM config, schema, migrations
│   │   │   ├── common/              # Shared guards, interceptors, decorators
│   │   │   └── modules/             # Feature modules
│   │   │       ├── auth/            # Authentication (JWT)
│   │   │       ├── users/           # User profiles & stats
│   │   │       ├── destinations/    # Tourism locations (PostGIS)
│   │   │       ├── quests/          # Quest definitions
│   │   │       ├── checkpoints/     # Quest waypoints + QR codes
│   │   │       ├── passports/       # User progress/XP
│   │   │       ├── rewards/         # Rewards & redemption
│   │   │       └── leaderboards/    # Rankings
│   │   └── package.json             # API dependencies
│   └── web/              # Next.js Partner Dashboard
│       ├── src/
│       │   ├── app/                 # App router pages
│       │   │   ├── layout.tsx       # Root layout
│       │   │   ├── page.tsx         # Home page
│       │   │   ├── dashboard/       # /dashboard
│       │   │   ├── destinations/    # /destinations
│       │   │   ├── quests/          # /quests
│       │   │   └── analytics/       # /analytics
│       │   ├── components/          # Reusable components
│       │   ├── lib/                 # Utilities
│       │   │   ├── api-client.ts    # Axios instance with auth
│       │   │   └── store.ts         # Zustand state management
│       │   └── app/globals.css      # Tailwind styles
│       ├── next.config.js
│       ├── tsconfig.json
│       └── package.json             # Web dependencies
├── packages/
│   └── shared-types/     # TypeScript types package
│       ├── src/
│       │   └── index.ts             # All shared interfaces & enums
│       ├── tsconfig.json
│       └── package.json
├── mobile/               # Flutter mobile app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── core/                    # API client, theme, config
│   │   └── features/                # Screens & feature modules
│   └── pubspec.yaml
├── docker-compose.yml    # PostgreSQL + Redis
├── pnpm-workspace.yaml   # Monorepo config
├── tsconfig.base.json    # Base TypeScript config
└── README.md
```

## Key Features Implemented

### 1. Shared Types Package (`@trailquest/shared-types`)
- Central TypeScript definitions used across API, Web, and Mobile
- Exports: User, Partner, Destination, Quest, Checkpoint, Passport, Reward, Leaderboard types
- All packages reference this as workspace dependency (`workspace:*`)

### 2. NestJS API (`@trailquest/api`)
- **Architecture**: Modular, feature-based
- **Database**: Drizzle ORM with PostgreSQL + PostGIS
- **Auth**: JWT (access + refresh tokens), Argon2 password hashing
- **Validation**: class-validator + Zod
- **Cache**: Redis via ioredis
- **Modules**:
  - Auth: Register, login, token refresh
  - Users: Profile, stats, progression
  - Destinations: CRUD with geo-location
  - Quests: Quest creation & management
  - Checkpoints: Location-based check-ins with QR codes
  - Passports: User XP, levels, badges
  - Rewards: Reward distribution & redemption
  - Leaderboards: Time-based rankings

### 3. Next.js Web Dashboard (`@trailquest/web`)
- **Framework**: Next.js 14 with App Router + TypeScript
- **Styling**: Tailwind CSS
- **State**: Zustand for client-side state
- **API**: Axios client with JWT interceptors
- **Pages**:
  - `/` - Landing page
  - `/dashboard` - Overview with stats & activity
  - `/destinations` - Destination CRUD
  - `/quests` - Quest management
  - `/analytics` - Performance metrics

### 4. Flutter Mobile App
- Dart/Flutter for iOS & Android
- RESTful API client for backend
- Map integration (Mapbox)
- Quest progression & check-in flows

## Environment Setup

### Local Development

1. **Copy .env file**:
   ```bash
   cp .env.example .env
   ```

2. **Update .env** with your values:
   ```env
   # Database (Docker)
   POSTGRES_USER=trailquest
   POSTGRES_PASSWORD=trailquest_dev
   POSTGRES_DB=trailquest

   # API
   NODE_ENV=development
   API_PORT=4000
   DATABASE_URL=postgresql://trailquest:trailquest_dev@localhost:5432/trailquest
   REDIS_URL=redis://localhost:6379
   JWT_ACCESS_SECRET=your-access-secret-min-32-chars
   JWT_REFRESH_SECRET=your-refresh-secret-min-32-chars

   # Web
   NEXT_PUBLIC_API_URL=http://localhost:4000
   ```

### Running Services

1. **Start PostgreSQL & Redis**:
   ```bash
   pnpm db:up
   ```

2. **Run migrations**:
   ```bash
   pnpm db:migrate
   ```

3. **Seed test data**:
   ```bash
   pnpm db:seed
   ```

4. **Development mode** (all apps):
   ```bash
   pnpm dev
   ```

   This runs:
   - API on `http://localhost:4000`
   - Web on `http://localhost:3001`

### Building

```bash
# Build all apps
pnpm build

# Build specific app
pnpm build --filter @trailquest/web
pnpm build --filter @trailquest/api
```

## API Integration

### Authentication Flow

1. **Register/Login**
   ```
   POST /auth/register
   POST /auth/login
   → Returns: { access_token, refresh_token, user }
   ```

2. **Protected Routes**
   - Send: `Authorization: Bearer {access_token}`
   - Token interceptor in web/mobile adds this automatically

3. **Token Refresh**
   ```
   POST /auth/refresh
   Body: { refreshToken }
   → Returns: { access_token, refreshToken }
   ```

### Data Flow

```
Web Dashboard ←→ API (NestJS)
                  ↓
                Database (PostgreSQL)
                  ↓
                Cache (Redis)

Mobile App ←→ API (same)
```

## Key Endpoints

### Auth
- `POST /auth/register` - Create account
- `POST /auth/login` - Sign in
- `POST /auth/refresh` - Refresh token

### Destinations
- `GET /destinations` - List all
- `POST /destinations` - Create new
- `GET /destinations/:id` - Get details
- `PUT /destinations/:id` - Update
- `DELETE /destinations/:id` - Delete

### Quests
- `GET /quests` - List all
- `POST /quests` - Create new
- `GET /quests/:id` - Get details
- `GET /quests/:id/checkpoints` - Get waypoints

### Checkpoints
- `POST /checkpoints/checkin` - Check-in at location
- `POST /checkpoints/verify-qr` - Verify QR code

### Passports
- `GET /passports/me` - Get user progress
- `GET /passports/:id/stats` - Get user stats

### Leaderboards
- `GET /leaderboards/weekly` - Weekly rankings
- `GET /leaderboards/monthly` - Monthly rankings
- `GET /leaderboards/all-time` - All-time rankings

## Dependency Chain

```
@trailquest/shared-types
  ↑
  ├── @trailquest/api
  │   └── Uses types for responses, DTOs
  ├── @trailquest/web
  │   └── Uses types for API responses, state
  └── mobile app (types.dart)
      └── Uses equivalent types via code generation
```

## Database Schema Highlights

### Core Tables
- `users` - Tourist profiles
- `partners` - Business partners
- `destinations` - Tourism locations (geo-indexed)
- `quests` - Quest definitions
- `checkpoints` - Quest waypoints (geo-indexed)
- `passports` - User progression data
- `rewards` - Redemption rewards
- `leaderboards` - Cached rankings

### PostGIS Usage
- Destination location queries: `ST_DWithin` for radius search
- Checkpoint distance calculations
- Spatial indexing for performance

## Testing

### Unit Tests
```bash
pnpm test
```

### API Testing with cURL
```bash
# Register
curl -X POST http://localhost:4000/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","username":"explorer","password":"SecurePassword123"}'

# Login
curl -X POST http://localhost:4000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"SecurePassword123"}'

# Protected endpoint
curl http://localhost:4000/passports/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

## Deployment

### Build & Deploy API
```bash
pnpm build --filter @trailquest/api
docker build -f apps/api/Dockerfile -t trailquest-api .
```

### Build & Deploy Web
```bash
pnpm build --filter @trailquest/web
docker build -f apps/web/Dockerfile -t trailquest-web .
```

### Environment for Production
- Use separate `.env.production`
- Update `NEXT_PUBLIC_API_URL` to production API
- Use strong JWT secrets
- Enable HTTPS
- Set up SSL certificates

## Troubleshooting

### API won't start
```bash
# Check database connection
pnpm db:up
pnpm db:migrate

# Verify env vars
echo $DATABASE_URL
```

### Web can't reach API
```bash
# Check NEXT_PUBLIC_API_URL
echo $NEXT_PUBLIC_API_URL

# Verify API is running
curl http://localhost:4000/health
```

### Package not found
```bash
# Reinstall dependencies
pnpm install

# Clear pnpm store
pnpm store prune
```

## Next Steps

1. **Connect Mobile App** - Update Flutter API client to match endpoint paths
2. **Database Backups** - Set up automated PostgreSQL backups
3. **Monitoring** - Add health checks and logging
4. **CI/CD** - GitHub Actions for automated testing & deployment
5. **Rate Limiting** - Configure throttler for API endpoints
6. **Search** - Add full-text search for quests & destinations

---

**Stack Summary**:
- Monorepo: pnpm workspaces
- Backend: NestJS + Drizzle ORM + PostgreSQL + Redis
- Frontend: Next.js 14 + Tailwind CSS
- Mobile: Flutter + Dart
- Types: Shared TypeScript package
- Hosting-ready: Docker Compose for local dev, ready for cloud deployment
