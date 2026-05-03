@echo off
REM Trail Quest - Local Development Setup Script (Windows)

setlocal enabledelayedexpansion

echo.
echo 🗺️  Trail Quest - Setup Script (Windows)
echo ====================================== 
echo.

REM Check prerequisites
echo Checking prerequisites...

where pnpm >nul 2>nul
if errorlevel 1 (
    echo ❌ pnpm not found. Install with: npm install -g pnpm
    exit /b 1
)

where docker >nul 2>nul
if errorlevel 1 (
    echo ❌ Docker not found. Please install Docker Desktop
    exit /b 1
)

echo ✓ pnpm and Docker found
echo.

REM Setup environment
echo Setting up environment...

if not exist .env (
    echo Creating .env from .env.example...
    copy .env.example .env
    echo ✓ .env created - update values as needed
) else (
    echo ✓ .env already exists
)
echo.

REM Install dependencies
echo Installing dependencies...
call pnpm install
echo.

REM Start database
echo Starting PostgreSQL and Redis...
call pnpm db:up
echo ⏳ Waiting for database to be ready...
timeout /t 5 /nobreak

REM Run migrations
echo.
echo Running database migrations...
call pnpm db:migrate

REM Seed data
echo.
echo Seeding Ilocos Norte test data...
call pnpm db:seed

echo.
echo ✅ Setup complete!
echo.
echo 📋 Next steps:
echo    1. Start development servers: pnpm dev
echo    2. API:  http://localhost:4000
echo    3. Web:  http://localhost:3001
echo    4. Swagger Docs: http://localhost:4000/docs
echo.
echo 💡 Useful commands:
echo    pnpm dev              Start all apps
echo    pnpm build            Build all packages
echo    pnpm test             Run tests
echo    pnpm db:reset         Reset database
echo    pnpm lint             Lint code
echo.
