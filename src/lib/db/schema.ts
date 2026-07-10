import { sqliteTable, text, integer, uniqueIndex } from "drizzle-orm/sqlite-core";

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
  statValues: text("stat_values"),
  gearTier: integer("gear_tier"),
  socketPlugs: text("socket_plugs"),
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

export const sets = sqliteTable(
  "sets",
  {
    id: text("id").primaryKey(),
    userId: integer("user_id")
      .notNull()
      .references(() => users.id, { onDelete: "cascade" }),
    name: text("name").notNull(),
    type: text("type").notNull(),
    createdAt: text("created_at").notNull(),
    updatedAt: text("updated_at").notNull(),
  },
  (table) => ({
    userTypeName: uniqueIndex("sets_user_type_name").on(table.userId, table.type, table.name),
  }),
);

export const setTags = sqliteTable(
  "set_tags",
  {
    setId: text("set_id")
      .notNull()
      .references(() => sets.id, { onDelete: "cascade" }),
    tagId: text("tag_id").notNull(),
  },
  (table) => ({
    pk: uniqueIndex("set_tags_set_tag").on(table.setId, table.tagId),
  }),
);

export const setItems = sqliteTable("set_items", {
  id: text("id").primaryKey(),
  setId: text("set_id")
    .notNull()
    .references(() => sets.id, { onDelete: "cascade" }),
  slot: text("slot").notNull(),
  itemHash: integer("item_hash").notNull(),
  itemName: text("item_name").notNull(),
  selectedPerks: text("selected_perks").notNull().default("[]"),
  masterworkHash: integer("masterwork_hash"),
  modHashes: text("mod_hashes"),
  instanceId: text("instance_id"),
  sortOrder: integer("sort_order").notNull().default(0),
  removedAt: text("removed_at"),
});

export const synergies = sqliteTable("synergies", {
  id: text("id").primaryKey(),
  userId: integer("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  type: text("type").notNull(),
  subType: text("sub_type"),
  description: text("description").notNull().default(""),
  createdAt: text("created_at").notNull(),
  updatedAt: text("updated_at").notNull(),
});

export const synergyLinks = sqliteTable("synergy_links", {
  id: text("id").primaryKey(),
  synergyId: text("synergy_id")
    .notNull()
    .references(() => synergies.id, { onDelete: "cascade" }),
  kind: text("kind").notNull(),
  displayName: text("display_name").notNull(),
  itemHash: integer("item_hash"),
  perkHash: integer("perk_hash"),
  parentItemHash: integer("parent_item_hash"),
  originTraitName: text("origin_trait_name"),
  originTraitHash: integer("origin_trait_hash"),
  armorSetName: text("armor_set_name"),
  bonusPieces: integer("bonus_pieces"),
  bonusName: text("bonus_name"),
  armorSetHash: integer("armor_set_hash"),
});

export const builds = sqliteTable("builds", {
  id: text("id").primaryKey(),
  userId: integer("user_id")
    .notNull()
    .references(() => users.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  className: text("class_name").notNull(),
  subclass: text("subclass").notNull(),
  exoticArmorHash: integer("exotic_armor_hash"),
  exoticArmorName: text("exotic_armor_name"),
  exoticWeaponHash: integer("exotic_weapon_hash"),
  exoticWeaponName: text("exotic_weapon_name"),
  pinnedSuper: text("pinned_super"),
  createdAt: text("created_at").notNull(),
  updatedAt: text("updated_at").notNull(),
});

export const buildTags = sqliteTable(
  "build_tags",
  {
    buildId: text("build_id")
      .notNull()
      .references(() => builds.id, { onDelete: "cascade" }),
    tagId: text("tag_id").notNull(),
  },
  (table) => ({
    pk: uniqueIndex("build_tags_build_tag").on(table.buildId, table.tagId),
  }),
);

export const buildVariants = sqliteTable("build_variants", {
  id: text("id").primaryKey(),
  buildId: text("build_id")
    .notNull()
    .references(() => builds.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  isDefault: integer("is_default").notNull().default(0),
  exoticWeaponHash: integer("exotic_weapon_hash"),
  exoticWeaponName: text("exotic_weapon_name"),
  artifactHash: integer("artifact_hash"),
  artifactName: text("artifact_name"),
  artifactConfig: text("artifact_config").notNull().default("[]"),
  notes: text("notes"),
  createdAt: text("created_at").notNull(),
  updatedAt: text("updated_at").notNull(),
});

export const buildSynergies = sqliteTable(
  "build_synergies",
  {
    buildId: text("build_id")
      .notNull()
      .references(() => builds.id, { onDelete: "cascade" }),
    synergyId: text("synergy_id")
      .notNull()
      .references(() => synergies.id, { onDelete: "cascade" }),
    attachedAt: text("attached_at").notNull(),
  },
  (table) => ({
    pk: uniqueIndex("build_synergies_build_synergy").on(table.buildId, table.synergyId),
  }),
);

export const variantSetAttachments = sqliteTable("variant_set_attachments", {
  id: text("id").primaryKey(),
  variantId: text("variant_id")
    .notNull()
    .references(() => buildVariants.id, { onDelete: "cascade" }),
  setId: text("set_id")
    .notNull()
    .references(() => sets.id, { onDelete: "restrict" }),
  mode: text("mode").notNull(),
  snapshotConfigs: text("snapshot_configs"),
  attachedAt: text("attached_at").notNull(),
});
