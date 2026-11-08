# Contract: Process SQLite singleton

## getSqlite / getDb (app path)

- **Input**: None (uses process env + `appDbPath()`).
- **Behavior**:
  - Returns drizzle over a native better-sqlite3 Database.
  - Native Database instance is process-wide singleton on `global.__d2bcSqlite` for every `NODE_ENV`.
  - First open applies `journal_mode = WAL` and `foreign_keys = ON`.
  - `runMigrations` runs once per process against that handle (existing `migrated` flag).
- **Non-goals**: Multi-worker sharing, Edge runtime, connection pooling.

## createTestDb / createTestSqlite

- **Input**: None.
- **Behavior**:
  - Always `new Database(":memory:")` with `foreign_keys = ON`.
  - Never read or write `global.__d2bcSqlite`.
  - Apply migrations with temporary `migrated` reset so schema is present on the memory DB.

## Observability / docs

- Code comment at singleton acquisition: multi-worker / Edge against one file unsupported.
