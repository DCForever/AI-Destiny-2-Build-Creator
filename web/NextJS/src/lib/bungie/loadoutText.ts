import type { EntityCache } from "@/lib/manifest/types/services";
import type { StoreName } from "@/lib/manifest/types/stores";
import type { CharacterEquipment, EquippedItemSummary } from "./types";

const BUCKET_ORDER = [
  "Subclass",
  "Kinetic Weapons",
  "Energy Weapons",
  "Power Weapons",
  "Helmet",
  "Gauntlets",
  "Chest Armor",
  "Leg Armor",
  "Class Armor",
] as const;

const ARMOR_BUCKETS = new Set<string>([
  "Helmet",
  "Gauntlets",
  "Chest Armor",
  "Leg Armor",
  "Class Armor",
]);

const MAX_PLUGS = 12;

const HASH_STORES: StoreName[] = [
  "weapons",
  "exotic-weapons",
  "exotic-armor",
  "aspects",
  "fragments",
  "abilities",
  "mods",
  "weapon-perks",
  "origin-traits",
];

async function buildHashIndex(cache: EntityCache): Promise<Map<number, string>> {
  const index = new Map<number, string>();
  for (const storeName of HASH_STORES) {
    const records = (await cache.getStore(storeName)) as unknown as {
      hash: number;
      name: string;
    }[];
    for (const record of records) {
      if (!index.has(record.hash)) {
        index.set(record.hash, record.name);
      }
    }
  }
  return index;
}

function resolvePlugNames(plugHashes: number[], index: Map<number, string>): string[] {
  const seen = new Set<string>();
  const result: string[] = [];
  for (const hash of plugHashes) {
    const name = index.get(hash);
    if (!name || seen.has(name)) continue;
    seen.add(name);
    result.push(name);
    if (result.length >= MAX_PLUGS) break;
  }
  return result;
}

function formatItemLine(item: EquippedItemSummary, index: Map<number, string>): string {
  const itemName = index.get(item.itemHash);
  const isArmor = ARMOR_BUCKETS.has(item.bucket);

  const nameLine = itemName
    ? `${item.bucket}: ${itemName}`
    : isArmor
      ? `${item.bucket}: Legendary armor piece (not in entity cache)`
      : `${item.bucket}: Unknown item (${item.itemHash})`;

  const plugNames = resolvePlugNames(item.plugHashes, index);
  if (plugNames.length === 0) return nameLine;
  return `${nameLine}\n  plugs: ${plugNames.join(", ")}`;
}

export async function equipmentToLoadoutText(
  equipment: CharacterEquipment,
  cache: EntityCache,
): Promise<string> {
  const index = await buildHashIndex(cache);

  const itemsByBucket = new Map<string, EquippedItemSummary>();
  for (const item of equipment.items) {
    itemsByBucket.set(item.bucket, item);
  }

  const lines: string[] = [];
  for (const bucket of BUCKET_ORDER) {
    const item = itemsByBucket.get(bucket);
    if (item) {
      lines.push(formatItemLine(item, index));
    }
  }

  return lines.join("\n");
}
