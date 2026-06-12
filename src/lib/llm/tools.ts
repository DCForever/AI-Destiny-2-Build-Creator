import type { EntityCache, ItemResolver, ResolveResult } from "@/lib/manifest/types/services";
import type {
  ArtifactRecord,
  ExoticArmorRecord,
  ExoticWeaponRecord,
  WeaponRecord,
} from "@/lib/manifest/types/records";
import type { StoreName } from "@/lib/manifest/types/stores";

import type { ToolDefinition, ToolExecutor, ToolName, ToolResult } from "./toolTypes";
import { TOOL_NAMES } from "./toolTypes";

export interface WebSearcher {
  search(query: string, limit?: number): Promise<{
    available: boolean;
    results?: { title: string; snippet: string; url: string }[];
    reason?: string;
  }>;
}

const MAX_MATCHES = 5;
const MAX_PERKS_PER_COLUMN = 12;
const DESC_TRUNC = 140;
const SNIPPET_TRUNC = 200;
const SEARCH_STORES: StoreName[] = ["exotic-armor", "exotic-weapons", "weapons"];
const SEARCH_CATEGORIES = new Set<string>([...SEARCH_STORES, "aspects", "fragments", "mods"]);

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

function isToolName(name: string): name is ToolName {
  return (TOOL_NAMES as readonly string[]).includes(name);
}

function toolDef(
  name: ToolName,
  description: string,
  properties: Record<string, unknown>,
  required: string[],
): ToolDefinition {
  return {
    type: "function",
    function: { name, description, parameters: { type: "object", properties, required } },
  };
}

export function buildToolDefinitions(): ToolDefinition[] {
  return [
    toolDef("search_items", "Fuzzy-search Destiny items by name.", {
      query: { type: "string", description: "Item name or fragment" },
      category: {
        type: "string",
        enum: ["weapons", "exotic-armor", "exotic-weapons", "aspects", "fragments", "mods"],
        description: "Optional store; default searches armor and weapons",
      },
    }, ["query"]),
    toolDef("get_weapon_perks", "Legendary perk columns or exotic intrinsics for a weapon.", {
      weaponName: { type: "string", description: "Weapon name" },
    }, ["weaponName"]),
    toolDef("get_exotic_details", "Exotic armor or weapon intrinsic and slot details.", {
      name: { type: "string", description: "Exotic name" },
    }, ["name"]),
    toolDef("get_artifact_perks", "Perks for a permanent Artifacts 2.0 artifact.", {
      artifactName: { type: "string", description: "Artifact name" },
    }, ["artifactName"]),
    toolDef("web_search", "Web search for current meta; prefer manifest tools first.", {
      query: { type: "string", description: "Search query" },
    }, ["query"]),
  ];
}

async function buildPerkNameMap(cache: EntityCache): Promise<Map<number, string>> {
  const perks = await cache.getStore("weapon-perks");
  return new Map(perks.map((p) => [p.hash, p.name]));
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

function resolveSearchStores(category: unknown): StoreName[] {
  return typeof category === "string" && SEARCH_CATEGORIES.has(category)
    ? [category as StoreName]
    : SEARCH_STORES;
}

async function searchItems(resolver: ItemResolver, args: Record<string, unknown>): Promise<ToolResult> {
  const query = requireString(args, "query");
  if (!query) return { error: "query must be a non-empty string" };

  const matches: { name: string; category: string; hash: number }[] = [];
  const seen = new Set<number>();
  for (const store of resolveSearchStores(args.category)) {
    const hits = await resolver.search(store, query, MAX_MATCHES);
    for (const hit of hits) {
      if (seen.has(hit.record.hash)) continue;
      seen.add(hit.record.hash);
      matches.push({ name: hit.record.name, category: store, hash: hit.record.hash });
      if (matches.length >= MAX_MATCHES) break;
    }
    if (matches.length >= MAX_MATCHES) break;
  }
  return { matches };
}

async function buildLegendaryPerkResult(
  resolved: ResolveResult<WeaponRecord>,
  cache: EntityCache,
): Promise<ToolResult> {
  const weapon = resolved.record;
  const perkMap = await buildPerkNameMap(cache);
  return {
    weapon: weapon.name,
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
  constructor(private readonly deps: { resolver: ItemResolver; cache: EntityCache; searcher: WebSearcher }) {}

  async execute(name: ToolName, args: Record<string, unknown>): Promise<ToolResult> {
    if (!isToolName(name)) return { error: `unknown tool: ${name}` };
    try {
      return await this.dispatch(name, args);
    } catch (error) {
      return { error: error instanceof Error ? error.message : String(error) };
    }
  }

  private dispatch(name: ToolName, args: Record<string, unknown>): Promise<ToolResult> {
    const { resolver, cache, searcher } = this.deps;
    switch (name) {
      case "search_items":
        return searchItems(resolver, args);
      case "get_weapon_perks":
        return getWeaponPerks(resolver, cache, args);
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
}): ToolExecutor {
  return new ManifestToolExecutor(deps);
}
