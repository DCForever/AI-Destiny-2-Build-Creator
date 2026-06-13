import Database from "better-sqlite3";
import { drizzle, type BetterSQLite3Database } from "drizzle-orm/better-sqlite3";
import { mkdirSync } from "node:fs";
import path from "node:path";

import { appDbPath } from "@/lib/manifest/cachePaths";

import * as schema from "./schema";

export type AppDatabase = BetterSQLite3Database<typeof schema>;

declare global {
  var __d2bcSqlite: Database.Database | undefined;
}

function openDatabase(): Database.Database {
  const dbPath = appDbPath();
  mkdirSync(path.dirname(dbPath), { recursive: true });
  const db = new Database(dbPath);
  db.pragma("journal_mode = WAL");
  db.pragma("foreign_keys = ON");
  return db;
}

function getSqlite(): Database.Database {
  if (process.env.NODE_ENV === "development") {
    if (!global.__d2bcSqlite) {
      global.__d2bcSqlite = openDatabase();
    }
    return global.__d2bcSqlite;
  }
  return openDatabase();
}

let migrated = false;

export function runMigrations(db: Database.Database): void {
  if (migrated) return;
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      bungie_membership_id TEXT NOT NULL UNIQUE,
      membership_type INTEGER NOT NULL,
      display_name TEXT NOT NULL DEFAULT '',
      last_sync_at TEXT
    );

    CREATE TABLE IF NOT EXISTS inventory_items (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      instance_id TEXT NOT NULL,
      item_hash INTEGER NOT NULL,
      bucket TEXT NOT NULL,
      location TEXT NOT NULL,
      character_id TEXT,
      power INTEGER NOT NULL DEFAULT 0,
      is_masterwork INTEGER NOT NULL DEFAULT 0,
      is_crafted INTEGER NOT NULL DEFAULT 0,
      plug_hashes TEXT NOT NULL DEFAULT '[]',
      roll_tags TEXT NOT NULL DEFAULT '[]',
      synced_at TEXT NOT NULL,
      UNIQUE(user_id, instance_id)
    );

    CREATE INDEX IF NOT EXISTS idx_inventory_user_hash ON inventory_items(user_id, item_hash);
    CREATE INDEX IF NOT EXISTS idx_inventory_user_bucket ON inventory_items(user_id, bucket);
    CREATE INDEX IF NOT EXISTS idx_inventory_user_location ON inventory_items(user_id, location);

    CREATE TABLE IF NOT EXISTS inventory_sync_meta (
      user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
      item_count INTEGER NOT NULL DEFAULT 0,
      sync_version INTEGER NOT NULL DEFAULT 0,
      last_full_sync_at TEXT
    );

    CREATE TABLE IF NOT EXISTS loadouts (
      id TEXT PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      source TEXT NOT NULL,
      manifest_version TEXT NOT NULL,
      build_request TEXT,
      generated_build TEXT NOT NULL,
      resolved_sheet TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE INDEX IF NOT EXISTS idx_loadouts_user_updated ON loadouts(user_id, updated_at);
  `);
  migrated = true;
}

export function getDb(): AppDatabase {
  const sqlite = getSqlite();
  runMigrations(sqlite);
  return drizzle(sqlite, { schema });
}

/** Test helper: in-memory database with schema applied. */
export function createTestDb(): AppDatabase {
  const sqlite = new Database(":memory:");
  sqlite.pragma("foreign_keys = ON");
  migrated = false;
  runMigrations(sqlite);
  return drizzle(sqlite, { schema });
}
