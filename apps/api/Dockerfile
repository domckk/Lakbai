# API Dockerfile
FROM node:20-alpine

WORKDIR /app

# Install pnpm
RUN npm install -g pnpm

# Copy workspace files
COPY pnpm-workspace.yaml .
COPY pnpm-lock.yaml .
COPY tsconfig.base.json .
COPY package.json .
COPY packages ./packages
COPY apps/api ./apps/api

# Install dependencies
RUN pnpm install --frozen-lockfile

# Build
RUN pnpm --filter @trailquest/api run build

# Run
EXPOSE 4000
CMD ["node", "apps/api/dist/main.js"]
