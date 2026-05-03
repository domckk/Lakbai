#!/bin/bash
# Trail Quest - Local Development Setup Script

set -e

echo "🗺️  Trail Quest - Setup Script"
echo "================================"

# Check prerequisites
echo "✓ Checking prerequisites..."

if ! command -v pnpm &> /dev/null; then
    echo "❌ pnpm not found. Install with: npm install -g pnpm"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "❌ Docker not found. Please install Docker Desktop"
    exit 1
fi

echo "✓ pnpm and Docker found"

# Setup environment
echo ""
echo "📝 Setting up environment..."

if [ ! -f .env ]; then
    echo "Creating .env from .env.example..."
    cp .env.example .env
    echo "✓ .env created - update values as needed"
else
    echo "✓ .env already exists"
fi

# Install dependencies
echo ""
echo "📦 Installing dependencies..."
pnpm install

# Start database
echo ""
echo "🐘 Starting PostgreSQL and Redis..."
pnpm db:up
echo "⏳ Waiting for database to be ready..."
sleep 5

# Run migrations
echo ""
echo "🔄 Running database migrations..."
pnpm db:migrate

# Seed data
echo ""
echo "🌱 Seeding Ilocos Norte test data..."
pnpm db:seed

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "   1. Start development servers: pnpm dev"
echo "   2. API:  http://localhost:4000"
echo "   3. Web:  http://localhost:3001"
echo "   4. Swagger Docs: http://localhost:4000/docs"
echo ""
echo "💡 Useful commands:"
echo "   pnpm dev              Start all apps"
echo "   pnpm build            Build all packages"
echo "   pnpm test             Run tests"
echo "   pnpm db:reset         Reset database"
echo "   pnpm lint             Lint code"
echo ""
