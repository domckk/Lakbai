# Trail Quest - Documentation Index

Welcome! This file helps you navigate all Trail Quest documentation.

## 📚 Start Here

**New to the project?** Start with one of these:
1. **[README.md](./README.md)** - Project overview and quick start (5 min read)
2. **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Commands and endpoints cheat sheet (2 min read)
3. **[PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md)** - What's been built and current status (10 min read)

---

## 📖 Documentation Files

### For Getting Started
- **[README.md](./README.md)** - Main overview
  - Tech stack overview
  - Prerequisites and installation
  - Quick start commands
  - Project structure
  - Common commands
  - Troubleshooting

- **[QUICK_REFERENCE.md](./QUICK_REFERENCE.md)** - Quick lookup
  - Command reference
  - API endpoints
  - Environment setup
  - Quick troubleshooting

### For Development

- **[INTEGRATION.md](./INTEGRATION.md)** - Complete architecture guide (500+ lines)
  - Detailed project structure
  - Component descriptions
  - Architecture patterns
  - Database schema
  - API integration flow
  - Testing guide
  - Deployment instructions

- **[MOBILE_INTEGRATION.md](./MOBILE_INTEGRATION.md)** - Flutter/API guide
  - API client setup for Flutter
  - Authentication flow
  - Key endpoints for mobile
  - Data models for Dart
  - Feature implementation checklist
  - Testing API endpoints
  - Environment configuration

### For Project Management

- **[PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md)** - Comprehensive completion report
  - All completed phases (1-8)
  - File structure overview
  - Code statistics
  - Key features implemented
  - Technology stack
  - Project timeline
  - Design decisions
  - Current maturity level

- **[COMPLETION_CHECKLIST.md](./COMPLETION_CHECKLIST.md)** - Detailed checklist
  - All completed tasks
  - Phase-by-phase breakdown
  - What's included
  - File inventory
  - Next steps and roadmap

### Environment & Setup

- **[.env.example](./.env.example)** - Environment variables template
- **[.env.local.template](./.env.local.template)** - Local dev template with comments
- **[setup.sh](./setup.sh)** - Automated setup for macOS/Linux
- **[setup.bat](./setup.bat)** - Automated setup for Windows

---

## 🎯 By Use Case

### "I'm new, where do I start?"
1. Read [README.md](./README.md) (5 min)
2. Run `setup.sh` or `setup.bat`
3. Run `pnpm dev`
4. Keep [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) handy

### "I need to implement a feature"
1. Refer to [INTEGRATION.md](./INTEGRATION.md) for architecture
2. Check [PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md) for what's done
3. Review relevant module in `apps/api/src/modules/`
4. Use shared types from `packages/shared-types`

### "I'm working on Flutter/Mobile"
1. Read [MOBILE_INTEGRATION.md](./MOBILE_INTEGRATION.md)
2. Set up API client using provided examples
3. Refer to [INTEGRATION.md](./INTEGRATION.md) for endpoints
4. Keep API URL from `.env` in mind

### "I need to deploy"
1. Check [INTEGRATION.md](./INTEGRATION.md) deployment section
2. Review Dockerfiles in `apps/api` and `apps/web`
3. Set production environment variables
4. Review CI/CD workflow in `.github/workflows`

### "I'm debugging an issue"
1. Check [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) troubleshooting section
2. Review error logs
3. Verify environment variables
4. Check [README.md](./README.md) prerequisites

### "I need to understand the database"
1. Review schema in [INTEGRATION.md](./INTEGRATION.md)
2. Check migrations in `apps/api/src/database/migrations/`
3. Review seed data in `apps/api/src/database/seed.ts`
4. PostGIS docs for geo-queries

---

## 📋 Quick Navigation

### APIs
- **REST API**: http://localhost:4000
- **Swagger Docs**: http://localhost:4000/docs (when running)
- **API Code**: `apps/api/src/modules/`

### Web Dashboard
- **URL**: http://localhost:3001
- **Code**: `apps/web/`
- **Pages**: 
  - Dashboard: `/dashboard`
  - Destinations: `/destinations`
  - Quests: `/quests`
  - Analytics: `/analytics`

### Database
- **Type**: PostgreSQL 16 with PostGIS
- **Connection**: `postgresql://trailquest:trailquest_dev@localhost:5432/trailquest`
- **Docker**: Managed by `docker-compose.yml`

### Mobile
- **Framework**: Flutter/Dart
- **Location**: `mobile/`
- **Setup Guide**: See [MOBILE_INTEGRATION.md](./MOBILE_INTEGRATION.md)

### Shared Types
- **Location**: `packages/shared-types/`
- **Types**: `packages/shared-types/src/index.ts`

---

## 🔗 File Cross-Reference

| Need | File | Section |
|------|------|---------|
| Get started | README.md | Quick Start |
| Commands | QUICK_REFERENCE.md | Quick Commands |
| Architecture | INTEGRATION.md | Project Structure |
| What's built | PROJECT_SUMMARY.md | What's Complete |
| Checklist | COMPLETION_CHECKLIST.md | All tasks |
| Env setup | .env.local.template | Full example |
| Mobile setup | MOBILE_INTEGRATION.md | API Client Setup |
| Troubleshoot | README.md | Troubleshooting |
| Deploy | INTEGRATION.md | Deployment section |
| CI/CD | .github/workflows/ci.yml | GitHub Actions |
| Docker | apps/api/Dockerfile | API image |
| Docker | apps/web/Dockerfile | Web image |

---

## 💡 Tips

**Keyboard Shortcuts**
- Ctrl+K (Cmd+K) - Search in editor
- Ctrl+Shift+P (Cmd+Shift+P) - VS Code command palette
- `pnpm dev` - Run all apps
- `pnpm db:reset` - Full database reset

**Debug Commands**
```bash
# API logs
pnpm dev --filter @trailquest/api

# Web logs
pnpm dev --filter @trailquest/web

# Database shell
docker exec -it trailquest-postgres psql -U trailquest -d trailquest

# Redis CLI
docker exec -it trailquest-redis redis-cli

# Check API health
curl http://localhost:4000/health
```

**Common Issues**
- Can't connect to database? → Run `pnpm db:up`
- Dependencies missing? → Run `pnpm install`
- Port already in use? → Change `API_PORT` or `NEXT_PUBLIC_PORT`
- Types not found? → Run `pnpm install` in root

---

## 📞 Support

If you're stuck:
1. Check [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) troubleshooting
2. Read relevant section in [INTEGRATION.md](./INTEGRATION.md)
3. Review setup in [README.md](./README.md)
4. Check environment variables in `.env`
5. Verify services are running with `docker ps`

---

## 🚀 Next Steps

After setup, consider:
1. **Explore the Code** - Start with `apps/api/src/modules/auth/`
2. **Test Endpoints** - Use Postman or cURL (see QUICK_REFERENCE.md)
3. **Add a Feature** - Try creating a new endpoint
4. **Run Tests** - `pnpm test`
5. **Check Types** - Review `packages/shared-types/src/index.ts`
6. **Connect Mobile** - Follow [MOBILE_INTEGRATION.md](./MOBILE_INTEGRATION.md)

---

## 📊 Documentation Statistics

- **Total Pages**: 7 markdown files
- **Total Words**: 25,000+
- **Diagrams & Examples**: 50+
- **Code Samples**: 30+
- **Command Examples**: 20+

---

## Version Info

- **Project Version**: 0.1.0
- **Documentation Date**: May 2024
- **Last Updated**: May 2, 2024

---

**Start with [README.md](./README.md) and you'll be up and running in minutes!** 🚀
