import type { AppDatabase } from "@/lib/db/client";
import { queryInventoryByBucket } from "@/lib/db/repositories/inventoryRepository";
import type { EntityCache, ItemResolver, ResolveResult } from "@/lib/manifest/types/services";
import type {
  ArtifactRecord,
  ExoticArmorRecord,
  ExoticWeaponRecord,
  PerkRecord,
  WeaponRecord,
  WeaponSlotName,
} from "@/lib/manifest/types/records";
import type { StoreName } from "@/lib/manifest/types/stores";

import {
  buildPerkWeaponIndex,
  columnIndexToLabel,
  loadPerkWeaponIndex,
  type PerkWeaponIndex,
  type PerkWeaponIndexEntry,
} from "@/lib/manifest/perkWeaponIndex";

import type { ToolExecutor, ToolName, ToolResult } from "./toolTypes";
import { TOOL_NAMES } from "./toolTypes";

export { buildToolDefinitions } from "./toolDefinitions";

export interface InventoryContext {
  userId: number;
  db: AppDatabase;
}

export interface WebSearcher {
  search(query: string, limit?: number): Promise<{
    available: boolean;
    results?: { title: string; snippet: string; url: string }[];
    reason?: string;
  }>;
}

const MAX_MATCHES = 5;
const MAX_WEAPON_PERK_MATCHES = 5;
const MAX_WEAPONS_WITH_PERK = 8;
const MAX_PERKS_PER_COLUMN = 12;
const DESC_TRUNC = 140;
const SNIPPET_TRUNC = 200;
const SEARCH_STORES: StoreName[] = ["exotic-armor", "exotic-weapons", "weapons"];
const SEARCH_CATEGORIES = new Set<string>([...SEARCH_STORES, "aspects", "fragments", "mods"]);
const WEAPON_SLOTS = new Set<string>(["Kinetic", "Energy", "Power"]);

function truncate(text: string, max: number): string {
  return text.length <= max ? text : `${text.slice(0, max)}…`;
}

function stripNulls(obj: Record<string, unknown>): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  for (const [key, value] of Object.entries(obj)) {
    if (value === null || value === undefined) continue;
    out[key] =
      typeof value === "object" && !Array.isArray(value)
        ? stripNulls(value as Record<string, unknown>)
        : value;
  }
  return out;
}

function requireString(args: Record<string, unknown>, key: string): string | null {
  const value = args[key];
  return typeof value === "string" && value.trim() ? value.trim() : null;
}

function parseSlotFilter(value: unknown): WeaponSlotName | null {
  return typeof value === "string" && WEAPON_SLOTS.has(value) ? (value as WeaponSlotName) : null;
}

function isToolName(name: string): name is ToolName {
  return (TOOL_NAMES as readonly string[]).includes(name);
}

async function buildPerkNameMap(cache: EntityCache): Promise<Map<number, string>> {
  const perks = await cache.getStore("weapon-perks");
  return new Map(perks.map((p) => [p.hash, p.name]));
}

async function resolvePerkIndex(cache: EntityCache): Promise<PerkWeaponIndex> {
  const meta = await cache.getMeta();
  if (meta) {
    const loaded = await loadPerkWeaponIndex(meta.manifestVersion);
    if (loaded) return loaded;
  }
  const [weapons, exoticWeapons, weaponPerks] = await Promise.all([
    cache.getStore("weapons"),
    cache.getStore("exotic-weapons"),
    cache.getStore("weapon-perks"),
  ]);
  return buildPerkWeaponIndex(meta?.manifestVersion ?? "inline", {
    weapons,
    "exotic-weapons": exoticWeapons,
    "weapon-perks": weaponPerks,
  });
}

function perkNamesForColumn(
  column: { curated: number[]; randomized: number[] },
  perkMap: Map<number, string>,
): string[] {
  const names: string[] = [];
  const seen = new Set<number>();
  for (const hash of [...column.curated, ...column.randomized]) {
    if (seen.has(hash)) continue;
    const name = perkMap.get(hash);
    if (!name) continue;
    seen.add(hash);
    names.push(name);
    if (names.length >= MAX_PERKS_PER_COLUMN) break;
  }
  return names;
}

function aggregatePerkColumns(entries: PerkWeaponIndexEntry[]): {
  column: number;
  label: string;
  weaponCount: number;
  curatedCount: number;
}[] {
  const byColumn = new Map<number, { weapons: Set<number>; curated: number }>();
  for (const entry of entries) {
    const bucket = byColumn.get(entry.column) ?? { weapons: new Set<number>(), curated: 0 };
    bucket.weapons.add(entry.weaponHash);
    if (entry.curated) bucket.curated++;
    byColumn.set(entry.column, bucket);
  }
  return [...byColumn.entries()]
    .sort(([a], [b]) => a - b)
    .map(([column, stats]) => ({
      column,
      label: columnIndexToLabel(column),
      weaponCount: stats.weapons.size,
      curatedCount: stats.curated,
    }));
}

function resolveSearchStores(category: unknown): StoreName[] {
  return typeof category === "string" && SEARCH_CATEGORIES.has(category)
    ? [category as StoreName]
    : SEARCH_STORES;
}

function weaponMatchFields(record: WeaponRecord | ExoticWeaponRecord): Record<string, unknown> {
  return {
    name: record.name,
    slot: record.slot,
    itemTypeName: "itemTypeName" in record ? record.itemTypeName : undefined,
    frame: record.frame,
  };
}

function matchesSlotFilter(record: unknown, slot: WeaponSlotName | null): boolean {
  if (!slot) return true;
  return typeof record === "object"
    && record !== null
    && "slot" in record
    && (record as { slot: string }).slot === slot;
}

async function searchItems(resolver: ItemResolver, args: Record<string, unknown>): Promise<ToolResult> {
  const query = requireString(args, "query");
  if (!query) return { error: "query must be a non-empty string" };

  const slotFilter = parseSlotFilter(args.slot);
  const matches: Record<string, unknown>[] = [];
  const seen = new Set<number>();

  for (const store of resolveSearchStores(args.category)) {
    const hits = await resolver.search(store, query, MAX_MATCHES * 2);
    for (const hit of hits) {
      if (seen.has(hit.record.hash)) continue;
      if (!matchesSlotFilter(hit.record, slotFilter)) continue;
      seen.add(hit.record.hash);
      const base = { name: hit.record.name, category: store, hash: hit.record.hash };
      if (store === "weapons" || store === "exotic-weapons") {
        matches.push({ ...base, ...weaponMatchFields(hit.record as WeaponRecord | ExoticWeaponRecord) });
      } else {
        matches.push(base);
      }
      if (matches.length >= MAX_MATCHES) break;
    }
    if (matches.length >= MAX_MATCHES) break;
  }
  return { matches };
}

async function searchWeaponPerks(
  resolver: ItemResolver,
  cache: EntityCache,
  args: Record<string, unknown>,
): Promise<ToolResult> {
  const query = requireString(args, "query");
  if (!query) return { error: "query must be a non-empty string" };

  const limit = typeof args.limit === "number" && args.limit > 0
    ? Math.min(args.limit, MAX_WEAPON_PERK_MATCHES)
    : MAX_WEAPON_PERK_MATCHES;

  const hits = await resolver.search("weapon-perks", query, limit);
  const index = await resolvePerkIndex(cache);

  const matches = hits.map((hit) => {
    const perk = hit.record as PerkRecord;
    const entries = index.byPerk[String(perk.hash)] ?? [];
    const columns = entries.length > 0
      ? aggregatePerkColumns(entries)
      : [{ column: -1, label: "Intrinsic", weaponCount: 0, curatedCount: 0 }];
    return {
      name: perk.name,
      description: truncate(perk.description, DESC_TRUNC),
      columns,
    };
  });

  return { matches };
}

async function findWeaponsWithPerk(
  resolver: ItemResolver,
  cache: EntityCache,
  args: Record<string, unknown>,
  inventoryContext?: InventoryContext,
): Promise<ToolResult> {
  const perkName = requireString(args, "perkName");
  const slot = parseSlotFilter(args.slot);
  if (!perkName) return { error: "perkName must be a non-empty string" };
  if (!slot) return { error: "slot is required (Kinetic, Energy, or Power)" };

  const resolved = await resolver.resolve("weapon-perks", perkName);
  if (!resolved) return { error: `no perk matching "${perkName}"` };

  const ownedOnly = args.ownedOnly === true;
  if (ownedOnly && !inventoryContext) {
    return { error: "ownedOnly requires a signed-in user with synced inventory" };
  }

  const itemTypeFilter = requireString(args, "itemTypeName");
  const index = await resolvePerkIndex(cache);
  let entries = (index.byPerk[String(resolved.record.hash)] ?? [])
    .filter((e) => e.slot === slot)
    .filter((e) => !itemTypeFilter || e.itemTypeName.toLowerCase().includes(itemTypeFilter.toLowerCase()));

  if (ownedOnly && inventoryContext) {
    const owned = queryInventoryByBucket(inventoryContext.db, inventoryContext.userId, slot);
    const ownedWithPerk = new Set(
      owned
        .filter((item) => item.plugHashes.includes(resolved.record.hash))
        .map((item) => item.itemHash),
    );
    entries = entries.filter((e) => ownedWithPerk.has(e.weaponHash));
  }

  const sorted = [...entries].sort((a, b) => {
    if (a.curated !== b.curated) return a.curated ? -1 : 1;
    return a.weaponName.localeCompare(b.weaponName);
  });

  const seen = new Set<number>();
  const weapons: Record<string, unknown>[] = [];
  for (const entry of sorted) {
    if (seen.has(entry.weaponHash)) continue;
    seen.add(entry.weaponHash);
    weapons.push({
      name: entry.weaponName,
      itemTypeName: entry.itemTypeName,
      frame: entry.frame,
      column: entry.column,
      columnLabel: columnIndexToLabel(entry.column),
      curated: entry.curated,
    });
    if (weapons.length >= MAX_WEAPONS_WITH_PERK) break;
  }

  return { perk: resolved.record.name, slot, ownedOnly, weapons };
}

async function buildLegendaryPerkResult(
  resolved: ResolveResult<WeaponRecord>,
  cache: EntityCache,
): Promise<ToolResult> {
  const weapon = resolved.record;
  const perkMap = await buildPerkNameMap(cache);
  return {
    weapon: weapon.name,
    slot: weapon.slot,
    frame: weapon.frame,
    element: weapon.element,
    ammo: weapon.ammo,
    columns: weapon.perkColumns.map((col) => ({
      column: col.column,
      perks: perkNamesForColumn(col, perkMap),
    })),
  };
}

async function getWeaponPerks(
  resolver: ItemResolver,
  cache: EntityCache,
  args: Record<string, unknown>,
): Promise<ToolResult> {
  const weaponName = requireString(args, "weaponName");
  if (!weaponName) return { error: "weaponName must be a non-empty string" };

  const legendary = await resolver.resolve("weapons", weaponName);
  if (legendary) return buildLegendaryPerkResult(legendary, cache);

  const exotic = await resolver.resolve("exotic-weapons", weaponName);
  if (exotic) {
    const weapon = exotic.record as ExoticWeaponRecord;
    return stripNulls({
      weapon: weapon.name,
      slot: weapon.slot,
      frame: weapon.frame,
      intrinsic: weapon.intrinsic,
      catalyst: weapon.catalyst,
    });
  }
  return { error: `no weapon matching "${weaponName}"` };
}

async function getExoticDetails(resolver: ItemResolver, args: Record<string, unknown>): Promise<ToolResult> {
  const name = requireString(args, "name");
  if (!name) return { error: "name must be a non-empty string" };

  const armor = await resolver.resolve("exotic-armor", name);
  if (armor) {
    const piece = armor.record as ExoticArmorRecord;
    return stripNulls({ name: piece.name, class: piece.classType, slot: piece.slot, intrinsic: piece.intrinsic, archetype: piece.archetype });
  }
  const weapon = await resolver.resolve("exotic-weapons", name);
  if (weapon) {
    const exo = weapon.record as ExoticWeaponRecord;
    return stripNulls({ name: exo.name, slot: exo.slot, element: exo.element, ammo: exo.ammo, frame: exo.frame, intrinsic: exo.intrinsic, catalyst: exo.catalyst });
  }
  return { error: `no exotic matching "${name}"` };
}

async function getArtifactPerks(
  resolver: ItemResolver,
  cache: EntityCache,
  args: Record<string, unknown>,
): Promise<ToolResult> {
  const artifactName = requireString(args, "artifactName");
  if (!artifactName) return { error: "artifactName must be a non-empty string" };

  const resolved = await resolver.resolve("artifacts", artifactName);
  if (!resolved) {
    const artifacts = await cache.getStore("artifacts");
    const available = artifacts.map((a: ArtifactRecord) => a.name);
    return {
      error: `no artifact matching "${artifactName}". Available: ${available.join(", ")}`,
    };
  }

  const artifact = resolved.record as ArtifactRecord;
  return {
    artifact: artifact.name,
    perks: artifact.perks.map((p) => ({
      name: p.name,
      column: p.column,
      description: truncate(p.description, DESC_TRUNC),
    })),
  };
}

async function webSearch(searcher: WebSearcher, args: Record<string, unknown>): Promise<ToolResult> {
  const query = requireString(args, "query");
  if (!query) return { error: "query must be a non-empty string" };

  const response = await searcher.search(query, MAX_MATCHES);
  if (!response.available) {
    const reason = response.reason ?? "unknown";
    return { error: `web search unavailable: ${reason}. Use the curated meta notes instead.` };
  }
  return {
    results: (response.results ?? []).map((r) => ({
      title: r.title,
      snippet: truncate(r.snippet, SNIPPET_TRUNC),
      url: r.url,
    })),
  };
}

export class ManifestToolExecutor implements ToolExecutor {
  constructor(
    private readonly deps: {
      resolver: ItemResolver;
      cache: EntityCache;
      searcher: WebSearcher;
      inventoryContext?: InventoryContext;
    },
  ) {}

  async execute(name: ToolName, args: Record<string, unknown>): Promise<ToolResult> {
    if (!isToolName(name)) return { error: `unknown tool: ${name}` };
    try {
      return await this.dispatch(name, args);
    } catch (error) {
      return { error: error instanceof Error ? error.message : String(error) };
    }
  }

  private dispatch(name: ToolName, args: Record<string, unknown>): Promise<ToolResult> {
    const { resolver, cache, searcher, inventoryContext } = this.deps;
    switch (name) {
      case "search_items":
        return searchItems(resolver, args);
      case "get_weapon_perks":
        return getWeaponPerks(resolver, cache, args);
      case "search_weapon_perks":
        return searchWeaponPerks(resolver, cache, args);
      case "find_weapons_with_perk":
        return findWeaponsWithPerk(resolver, cache, args, inventoryContext);
      case "get_exotic_details":
        return getExoticDetails(resolver, args);
      case "get_artifact_perks":
        return getArtifactPerks(resolver, cache, args);
      case "web_search":
        return webSearch(searcher, args);
      default:
        return Promise.resolve({ error: `unknown tool: ${name}` });
    }
  }
}

export function createToolExecutor(deps: {
  resolver: ItemResolver;
  cache: EntityCache;
  searcher: WebSearcher;
  inventoryContext?: InventoryContext;
}): ToolExecutor {
  return new ManifestToolExecutor(deps);
}
