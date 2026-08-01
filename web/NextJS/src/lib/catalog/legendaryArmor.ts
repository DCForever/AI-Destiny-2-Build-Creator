import {
  asRawEquipmentSlot,
  asRawInventoryItem,
} from "@/lib/manifest/extractors/rawTypes";
import {
  getRaw,
  isUsable,
  projectBase,
  toArmorSlot,
  toClassName,
} from "@/lib/manifest/extractors/common";
import type { SetBonusRecord } from "@/lib/manifest/types/records";
import type { ManifestService } from "@/lib/manifest/types/services";

export type LegendaryArmorRow = {
  hash: number;
  name: string;
  searchName: string;
  icon: string | null;
  slot: string;
  classType?: string;
  setBonusName: string;
  setBonusHash: number;
  setBonusIcon?: string | null;
  setBonusPerks?: Array<{
    requiredCount: number;
    name: string;
    description: string;
  }>;
};

export type LegendaryArmorItemProjection = {
  name: string;
  searchName: string;
  icon: string | null;
  slot: string;
  classType?: string;
};

async function buildSlotMap(
  manifest: ManifestService,
  version: string,
): Promise<Map<number, string>> {
  const slotTable = await manifest.loadRawTable(version, "DestinyEquipmentSlotDefinition");
  const map = new Map<number, string>();
  for (const v of Object.values(slotTable)) {
    const slot = asRawEquipmentSlot(v);
    if (!slot) continue;
    const name = toArmorSlot(slot.displayProperties.name);
    if (name) map.set(slot.hash, name);
  }
  return map;
}

export function buildLegendaryArmorRows(
  setBonuses: SetBonusRecord[],
  projectItem: (hash: number) => LegendaryArmorItemProjection | null,
): LegendaryArmorRow[] {
  const rows: LegendaryArmorRow[] = [];
  const seen = new Set<number>();

  for (const set of setBonuses) {
    for (const hash of set.itemHashes) {
      if (seen.has(hash)) continue;
      const projection = projectItem(hash);
      if (!projection) continue;
      seen.add(hash);
      rows.push({
        hash,
        name: projection.name,
        searchName: projection.searchName,
        icon: projection.icon,
        slot: projection.slot,
        classType: projection.classType,
        setBonusName: set.name,
        setBonusHash: set.hash,
        setBonusIcon: set.icon ?? null,
        setBonusPerks: set.perks.map((p) => ({
          requiredCount: p.requiredCount,
          name: p.name,
          description: p.description,
        })),
      });
    }
  }

  return rows;
}

export async function loadLegendaryArmorRows(
  setBonuses: SetBonusRecord[],
  manifest: ManifestService,
  version: string,
): Promise<LegendaryArmorRow[]> {
  const [itemTable, slotMap] = await Promise.all([
    manifest.loadRawTable(version, "DestinyInventoryItemDefinition"),
    buildSlotMap(manifest, version),
  ]);

  return buildLegendaryArmorRows(setBonuses, (hash) => {
    const raw = getRaw(itemTable, hash);
    const item = asRawInventoryItem(raw);
    if (!item || !isUsable(item)) return null;
    const base = projectBase(item);
    const slotHash = item.equippingBlock?.equipmentSlotTypeHash;
    const slot = slotHash != null ? slotMap.get(slotHash) : undefined;
    if (!slot) return null;
    const classType = toClassName(item.classType) ?? undefined;
    return {
      name: base.name,
      searchName: base.searchName,
      icon: base.icon,
      slot,
      classType,
    };
  });
}
