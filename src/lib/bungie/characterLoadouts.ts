import type { DestinyClassName } from "@/lib/manifest/types/records";
import type { CharacterSummary } from "@/lib/bungie/types";

const BUNGIE_CDN = "https://www.bungie.net";

export type RawLoadoutSlot = {
  colorHash: number;
  iconHash: number;
  nameHash: number;
  items: Array<{ itemInstanceId: string; plugItemHashes: number[] }>;
};

export type BungieInGameLoadout = {
  /** Stable id: characterId:index */
  id: string;
  characterId: string;
  className: DestinyClassName;
  characterLight: number;
  index: number;
  name: string;
  iconHash: number;
  colorHash: number;
  nameHash: number;
  /** Relative Bungie path (e.g. /common/destiny2_content/...) */
  iconPath: string | null;
  colorPath: string | null;
  iconUrl: string | null;
  colorUrl: string | null;
  itemInstanceIds: string[];
  /** True when the slot has no equipped instances (empty preset). */
  empty: boolean;
};

export type LoadoutPresentationTables = {
  icons: Record<string, { iconImagePath?: string }>;
  colors: Record<string, { colorImagePath?: string }>;
  names: Record<string, { name?: string }>;
};

function asRecord(value: unknown): Record<string, unknown> | null {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    return null;
  }
  return value as Record<string, unknown>;
}

function bungieUrl(relativePath: string | null | undefined): string | null {
  if (!relativePath || typeof relativePath !== "string") return null;
  const path = relativePath.startsWith("/") ? relativePath : `/${relativePath}`;
  return `${BUNGIE_CDN}${path}`;
}

export function isEmptyLoadoutItems(
  items: Array<{ itemInstanceId: string }>,
): boolean {
  if (items.length === 0) return true;
  return items.every(
    (i) => !i.itemInstanceId || i.itemInstanceId === "0" || i.itemInstanceId === "",
  );
}

export function resolveLoadoutPresentation(
  slot: Pick<RawLoadoutSlot, "iconHash" | "colorHash" | "nameHash">,
  tables: LoadoutPresentationTables,
  fallbackName: string,
): {
  name: string;
  iconPath: string | null;
  colorPath: string | null;
  iconUrl: string | null;
  colorUrl: string | null;
} {
  const iconDef = tables.icons[String(slot.iconHash)];
  const colorDef = tables.colors[String(slot.colorHash)];
  const nameDef = tables.names[String(slot.nameHash)];

  const iconPath =
    typeof iconDef?.iconImagePath === "string" && iconDef.iconImagePath
      ? iconDef.iconImagePath
      : null;
  const colorPath =
    typeof colorDef?.colorImagePath === "string" && colorDef.colorImagePath
      ? colorDef.colorImagePath
      : null;
  const name =
    typeof nameDef?.name === "string" && nameDef.name.trim()
      ? nameDef.name.trim()
      : fallbackName;

  return {
    name,
    iconPath,
    colorPath,
    iconUrl: bungieUrl(iconPath),
    colorUrl: bungieUrl(colorPath),
  };
}

/**
 * Parse GetProfile Response.characterLoadouts (component 206).
 * Shape: { data: { [characterId]: { loadouts: [...] } } }
 */
export function parseCharacterLoadoutsResponse(
  response: unknown,
  characters: CharacterSummary[],
  tables: LoadoutPresentationTables,
): BungieInGameLoadout[] {
  const res = asRecord(response);
  if (!res) return [];

  const section = asRecord(res.characterLoadouts);
  const data = section ? asRecord(section.data) : null;
  if (!data) return [];

  const byId = new Map(characters.map((c) => [c.characterId, c]));
  const out: BungieInGameLoadout[] = [];

  for (const [characterId, charLoadouts] of Object.entries(data)) {
    const char = byId.get(characterId);
    if (!char) continue;
    const cl = asRecord(charLoadouts);
    const loadoutsRaw = cl && Array.isArray(cl.loadouts) ? cl.loadouts : [];

    loadoutsRaw.forEach((raw, index) => {
      const slot = parseRawLoadoutSlot(raw);
      if (!slot) return;
      const empty = isEmptyLoadoutItems(slot.items);
      const presentation = resolveLoadoutPresentation(
        slot,
        tables,
        `Loadout ${index + 1}`,
      );
      const itemInstanceIds = slot.items
        .map((i) => i.itemInstanceId)
        .filter((id) => id && id !== "0");

      out.push({
        id: `${characterId}:${index}`,
        characterId,
        className: char.classType,
        characterLight: char.light,
        index,
        name: presentation.name,
        iconHash: slot.iconHash,
        colorHash: slot.colorHash,
        nameHash: slot.nameHash,
        iconPath: presentation.iconPath,
        colorPath: presentation.colorPath,
        iconUrl: presentation.iconUrl,
        colorUrl: presentation.colorUrl,
        itemInstanceIds,
        empty,
      });
    });
  }

  // Stable order: class then index
  const classOrder: Record<string, number> = { Titan: 0, Hunter: 1, Warlock: 2 };
  return out.sort(
    (a, b) =>
      (classOrder[a.className] ?? 9) - (classOrder[b.className] ?? 9) ||
      a.characterId.localeCompare(b.characterId) ||
      a.index - b.index,
  );
}

function parseRawLoadoutSlot(raw: unknown): RawLoadoutSlot | null {
  const o = asRecord(raw);
  if (!o) return null;
  const itemsRaw = Array.isArray(o.items) ? o.items : [];
  const items = itemsRaw.flatMap((item) => {
    const i = asRecord(item);
    if (!i) return [];
    const plugs = Array.isArray(i.plugItemHashes)
      ? i.plugItemHashes.filter((n): n is number => typeof n === "number")
      : [];
    return [
      {
        itemInstanceId: String(i.itemInstanceId ?? "0"),
        plugItemHashes: plugs,
      },
    ];
  });
  return {
    colorHash: Number(o.colorHash ?? 0),
    iconHash: Number(o.iconHash ?? 0),
    nameHash: Number(o.nameHash ?? 0),
    items,
  };
}

/** Extract presentation paths from raw definition tables (hash-keyed). */
export function presentationTablesFromRaw(input: {
  icons: Record<string, unknown>;
  colors: Record<string, unknown>;
  names: Record<string, unknown>;
}): LoadoutPresentationTables {
  const icons: LoadoutPresentationTables["icons"] = {};
  const colors: LoadoutPresentationTables["colors"] = {};
  const names: LoadoutPresentationTables["names"] = {};

  for (const [hash, def] of Object.entries(input.icons)) {
    const d = asRecord(def);
    if (d && typeof d.iconImagePath === "string") {
      icons[hash] = { iconImagePath: d.iconImagePath };
    }
  }
  for (const [hash, def] of Object.entries(input.colors)) {
    const d = asRecord(def);
    if (d && typeof d.colorImagePath === "string") {
      colors[hash] = { colorImagePath: d.colorImagePath };
    }
  }
  for (const [hash, def] of Object.entries(input.names)) {
    const d = asRecord(def);
    if (d && typeof d.name === "string") {
      names[hash] = { name: d.name };
    }
  }
  return { icons, colors, names };
}
