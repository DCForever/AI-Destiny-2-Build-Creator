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

    CREATE TABLE IF NOT EXISTS sets (
      id TEXT PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );
    CREATE UNIQUE INDEX IF NOT EXISTS idx_sets_user_type_name ON sets(user_id, type, name);

    CREATE TABLE IF NOT EXISTS set_tags (
      set_id TEXT NOT NULL REFERENCES sets(id) ON DELETE CASCADE,
      tag_id TEXT NOT NULL,
      UNIQUE(set_id, tag_id)
    );
    CREATE INDEX IF NOT EXISTS idx_set_tags_tag ON set_tags(tag_id, set_id);

    CREATE TABLE IF NOT EXISTS set_items (
      id TEXT PRIMARY KEY,
      set_id TEXT NOT NULL REFERENCES sets(id) ON DELETE CASCADE,
      slot TEXT NOT NULL,
      item_hash INTEGER NOT NULL,
      item_name TEXT NOT NULL,
      selected_perks TEXT NOT NULL DEFAULT '[]',
      masterwork_hash INTEGER,
      mod_hashes TEXT,
      sort_order INTEGER NOT NULL DEFAULT 0,
      removed_at TEXT
    );
    CREATE INDEX IF NOT EXISTS idx_set_items_set ON set_items(set_id);

    CREATE TABLE IF NOT EXISTS synergies (
      id TEXT PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      description TEXT NOT NULL DEFAULT '',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS synergy_links (
      id TEXT PRIMARY KEY,
      synergy_id TEXT NOT NULL REFERENCES synergies(id) ON DELETE CASCADE,
      kind TEXT NOT NULL,
      display_name TEXT NOT NULL,
      item_hash INTEGER,
      perk_hash INTEGER,
      parent_item_hash INTEGER,
      origin_trait_name TEXT,
      origin_trait_hash INTEGER,
      armor_set_name TEXT,
      bonus_pieces INTEGER,
      bonus_name TEXT,
      armor_set_hash INTEGER
    );
    CREATE INDEX IF NOT EXISTS idx_synergy_links_synergy ON synergy_links(synergy_id);

    CREATE TABLE IF NOT EXISTS builds (
      id TEXT PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      class_name TEXT NOT NULL,
      subclass TEXT NOT NULL,
      exotic_armor_hash INTEGER NOT NULL,
      exotic_armor_name TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS build_tags (
      build_id TEXT NOT NULL REFERENCES builds(id) ON DELETE CASCADE,
      tag_id TEXT NOT NULL,
      UNIQUE(build_id, tag_id)
    );

    CREATE TABLE IF NOT EXISTS build_variants (
      id TEXT PRIMARY KEY,
      build_id TEXT NOT NULL REFERENCES builds(id) ON DELETE CASCADE,
      name TEXT NOT NULL,
      is_default INTEGER NOT NULL DEFAULT 0,
      exotic_weapon_hash INTEGER,
      exotic_weapon_name TEXT,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS build_synergies (
      build_id TEXT NOT NULL REFERENCES builds(id) ON DELETE CASCADE,
      synergy_id TEXT NOT NULL REFERENCES synergies(id) ON DELETE CASCADE,
      attached_at TEXT NOT NULL,
      UNIQUE(build_id, synergy_id)
    );

    CREATE TABLE IF NOT EXISTS variant_set_attachments (
      id TEXT PRIMARY KEY,
      variant_id TEXT NOT NULL REFERENCES build_variants(id) ON DELETE CASCADE,
      set_id TEXT NOT NULL REFERENCES sets(id) ON DELETE RESTRICT,
      mode TEXT NOT NULL,
      snapshot_configs TEXT,
      attached_at TEXT NOT NULL
    );
    CREATE INDEX IF NOT EXISTS idx_variant_attachments_set ON variant_set_attachments(set_id);
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
  const prevMigrated = migrated;
  migrated = false;
  runMigrations(sqlite);
  migrated = prevMigrated;
  return drizzle(sqlite, { schema });
}

/** Raw sqlite handle for migration smoke tests. */
export function createTestSqlite(): Database.Database {
  const sqlite = new Database(":memory:");
  sqlite.pragma("foreign_keys = ON");
  const prevMigrated = migrated;
  migrated = false;
  runMigrations(sqlite);
  migrated = prevMigrated;
  return sqlite;
}
