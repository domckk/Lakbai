"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.default = {
    schema: './src/database/schema.ts',
    out: './src/database/migrations',
    dialect: 'postgresql',
    dbCredentials: {
        url: process.env.DATABASE_URL ?? 'postgresql://trailquest:trailquest_dev@localhost:5432/trailquest',
    },
    verbose: true,
    strict: true,
};
//# sourceMappingURL=drizzle.config.js.map