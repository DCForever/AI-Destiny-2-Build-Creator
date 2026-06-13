import { sqliteTable, text, integer } from "drizzle-orm/sqlite-core";

export const users = sqliteTable("users", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  bungieMembershipId: text("bungie_membership_id").notNull().unique(),
  membershipType: integer("membership_type").notNull(),
  displayName: text("display_name").notNull().default(""),
  lastSyncAt: text("last_sync_at"),
});

export const inventoryItems = sqliteTable("inventory_items", {
  id: integer("id").primaryKey({ autoIncrement: true }),
  userId: integer("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  instanceId: text("instance_id").notNull(),
  itemHash: integer("item_hash").notNull(),
  bucket: text("bucket").notNull(),
  location: text("location").notNull(),
  characterId: text("character_id"),
  power: integer("power").notNull().default(0),
  isMasterwork: integer("is_masterwork").notNull().default(0),
  isCrafted: integer("is_crafted").notNull().default(0),
  plugHashes: text("plug_hashes").notNull().default("[]"),
  rollTags: text("roll_tags").notNull().default("[]"),
  syncedAt: text("synced_at").notNull(),
});

export const inventorySyncMeta = sqliteTable("inventory_sync_meta", {
  userId: integer("user_id").primaryKey().references(() => users.id, { onDelete: "cascade" }),
  itemCount: integer("item_count").notNull().default(0),
  syncVersion: integer("sync_version").notNull().default(0),
  lastFullSyncAt: text("last_full_sync_at"),
});

export const loadouts = sqliteTable("loadouts", {
  id: text("id").primaryKey(),
  userId: integer("user_id").notNull().references(() => users.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  source: text("source").notNull(),
  manifestVersion: text("manifest_version").notNull(),
  buildRequest: text("build_request"),
  generatedBuild: text("generated_build").notNull(),
  resolvedSheet: text("resolved_sheet").notNull(),
  createdAt: text("created_at").notNull(),
  updatedAt: text("updated_at").notNull(),
});
