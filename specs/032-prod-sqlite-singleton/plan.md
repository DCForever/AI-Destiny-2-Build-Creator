# Implementation Plan: Production SQLite Singleton

**Branch**: `032-prod-sqlite-singleton` | **Date**: 2026-07-23 | **Spec**: [spec.md](./spec.md)

## Technical Context
- Language: TypeScript / Next.js 16 Node runtime
- Storage: better-sqlite3 + drizzle-orm, `.cache/app.db`
- Testing: vitest

## Constitution Check
- Local-first single-process SQLite preserved
- No multi-tenant architecture

## Project Structure
- `src/lib/db/client.ts` — singleton cache for all NODE_ENV
- `src/lib/db/client.singleton.test.ts` — reuse + isolation tests

## Implementation
1. Cache `global.__d2bcSqlite` unconditionally
2. Export test helpers getAppSqliteForTests / resetAppSqliteForTests
3. Keep createTestDb / createTestSqlite on :memory:
