# Web Dashboard Dockerfile
FROM node:20-alpine AS builder

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy workspace files
COPY pnpm-workspace.yaml .
COPY tsconfig.base.json .
COPY package.json .
COPY packages ./packages
COPY apps/web ./apps/web

# Install dependencies
RUN pnpm install --frozen-lockfile

# Build
RUN pnpm build --filter @trailquest/web

# Production stage
FROM node:20-alpine

WORKDIR /app

RUN npm install -g pnpm

COPY --from=builder /app/apps/web/.next ./apps/web/.next
COPY --from=builder /app/apps/web/public ./apps/web/public
COPY --from=builder /app/apps/web/package.json ./apps/web/

# Install only production dependencies
WORKDIR /app/apps/web
RUN pnpm install --prod

EXPOSE 3001
CMD ["pnpm", "start"]
