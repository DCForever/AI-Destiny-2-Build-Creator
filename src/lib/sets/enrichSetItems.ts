import { resolveArmorTier } from "@/data/rules/armorTiers";
import type { AppDatabase } from "@/lib/db/client";
import { queryInventoryByInstanceIds } from "@/lib/db/repositories/inventoryRepository";
import { findSynergiesByTarget } from "@/lib/db/repositories/synergyRepository";
import { resolveInventoryHashProjections } from "@/lib/catalog/inventoryHashProjections";
import {
  computeTotalArmorStats,
  isCompleteArmorStats,
} from "@/lib/inventory/instances/parseArmorStats";
import { getServices } from "@/lib/services";
import {
  formatSynergyTypeDesignation,
} from "@/lib/synergies/generateSynergyName";
import type { SetItemRecord } from "@/lib/sets/setItemService";
import { sumArmorSetStats } from "@/lib/sets/sumArmorSetStats";

const NON_TRAIT_PLUG_TYPES = new Set([
  "barrel",
  "magazine",
  "stock",
  "guard",
  "blade",
  "bowstring",
  "arrow",
  "launcher barrel",
  "battery",
  "scope",
  "sight",
]);

export type SetItemPerkName = {
  hash: number;
  name: string;
};

export type SetItemLinkedSynergy = {
  id: string;
  label: string;
};

export type EnrichedSetItem = SetItemRecord & {
  itemTypeName?: string | null;
  frame?: string | null;
  ammo?: string | null;
  classType?: string | null;
  isExotic?: boolean;
  power?: number | null;
  location?: string | null;
  tier?: number | null;
  tierLabel?: string | null;
  originTraitName?: string | null;
  selectedTraitPerks?: SetItemPerkName[];
  availableTraitPerks?: SetItemPerkName[];
  linkedSynergies?: SetItemLinkedSynergy[];
  statValues?: Partial<Record<string, number>> | null;
  totalStats?: number | null;
  statsIncomplete?: boolean | null;
  /** Mods store energy cost when known. */
  energyCost?: number | null;
  slotCategory?: string | null;
};

function isTraitPlugType(plugTypeName: string | null | undefined): boolean {
  if (!plugTypeName?.trim()) return true; // unknown: keep if not clearly barrel/mag
  const t = plugTypeName.trim().toLowerCase();
  if (NON_TRAIT_PLUG_TYPES.has(t)) return false;
  if (t.includes("barrel") || t.includes("magazine") || t.includes("stock")) {
    return false;
  }
  return true;
}

export async function enrichSetItems(
  db: AppDatabase,
  userId: number,
  items: SetItemRecord[],
): Promise<{
  items: EnrichedSetItem[];
  armorStatTotals: ReturnType<typeof sumArmorSetStats> | null;
}> {
  const { entityCache, manifest } = await getServices();
  const [weapons, exoticWeapons, exoticArmor, weaponPerks, originTraits, mods] =
    await Promise.all([
      entityCache.getStore("weapons"),
      entityCache.getStore("exotic-weapons"),
      entityCache.getStore("exotic-armor"),
      entityCache.getStore("weapon-perks"),
      entityCache.getStore("origin-traits"),
      entityCache.getStore("mods"),
    ]);

  const weaponByHash = new Map(weapons.map((w) => [w.hash, w]));
  const exoticWByHash = new Map(exoticWeapons.map((w) => [w.hash, w]));
  const exoticAByHash = new Map(exoticArmor.map((a) => [a.hash, a]));
  const perkByHash = new Map(weaponPerks.map((p) => [p.hash, p]));
  const originByHash = new Map(originTraits.map((o) => [o.hash, o]));
  const modByHash = new Map(mods.map((m) => [m.hash, m]));

  // Legendary armor has no entity store — resolve icons from raw manifest.
  const missingIconHashes = [
    ...new Set(
      items
        .filter(
          (i) =>
            !i.icon &&
            !weaponByHash.has(i.itemHash) &&
            !exoticWByHash.has(i.itemHash) &&
            !exoticAByHash.has(i.itemHash),
        )
        .map((i) => i.itemHash),
    ),
  ];
  let manifestByHash = new Map<
    number,
    { name: string; icon: string | null; slot?: string; classType?: string }
  >();
  if (missingIconHashes.length > 0 && manifest?.getStatus) {
    try {
      const status = await manifest.getStatus();
      if (status.cachedVersion) {
        const projections = await resolveInventoryHashProjections(
          manifest,
          status.cachedVersion,
          missingIconHashes,
        );
        manifestByHash = projections;
      }
    } catch {
      // Tests / offline: leave icons unresolved
    }
  }

  const instanceIds = items
    .map((i) => i.instanceId)
    .filter((id): id is string => Boolean(id));
  const invRows = queryInventoryByInstanceIds(db, userId, instanceIds);
  const invByInstance = new Map(invRows.map((r) => [r.instanceId, r]));

  const enriched: EnrichedSetItem[] = [];

  for (const item of items) {
    const next: EnrichedSetItem = { ...item };
    const inv = item.instanceId
      ? invByInstance.get(item.instanceId)
      : undefined;

    const weapon = weaponByHash.get(item.itemHash);
    const exoW = exoticWByHash.get(item.itemHash);
    const exoA = exoticAByHash.get(item.itemHash);
    const manifestHit = manifestByHash.get(item.itemHash);

    if (weapon) {
      next.itemTypeName = weapon.itemTypeName;
      next.frame = weapon.frame;
      next.ammo = weapon.ammo;
      next.isExotic = false;
      next.originTraitName =
        weapon.originTraitHashes
          .map((h) => originByHash.get(h)?.name)
          .find(Boolean) ?? null;
      next.availableTraitPerks = collectAvailableTraits(
        weapon.perkColumns,
        perkByHash,
        inv?.plugHashes ?? item.selectedPerks,
      );
    } else if (exoW) {
      next.itemTypeName = "Exotic weapon";
      next.frame = exoW.frame;
      next.ammo = exoW.ammo;
      next.isExotic = true;
      next.availableTraitPerks = collectAvailableTraits(
        exoW.perkColumns ?? [],
        perkByHash,
        inv?.plugHashes ?? item.selectedPerks,
      );
    } else if (exoA) {
      next.itemTypeName = "Exotic armor";
      next.classType = exoA.classType;
      next.isExotic = true;
      next.frame = exoA.archetype;
    } else if (modByHash.has(item.itemHash)) {
      const mod = modByHash.get(item.itemHash)!;
      next.itemTypeName = "Mod";
      next.energyCost = mod.energyCost;
      next.slotCategory = mod.slotCategory;
      next.isExotic = false;
      if (!next.icon && mod.icon) next.icon = mod.icon;
    } else if (manifestHit) {
      // Legendary armor / non-store combat items
      next.isExotic = false;
      if (!next.icon && manifestHit.icon) next.icon = manifestHit.icon;
      if (manifestHit.classType) next.classType = manifestHit.classType;
      if (isArmorSetSlot(item.slot) || manifestHit.slot) {
        next.itemTypeName = next.itemTypeName ?? "Armor";
      }
    }

    if (inv) {
      next.power = inv.power;
      next.location = inv.location;
      const plugHashes =
        inv.plugHashes.length > 0 ? inv.plugHashes : item.selectedPerks;
      next.selectedTraitPerks = traitNamesFromHashes(plugHashes, perkByHash);

      // Origin trait from inventory plugs if not from catalog
      if (!next.originTraitName) {
        for (const h of plugHashes) {
          const o = originByHash.get(h);
          if (o) {
            next.originTraitName = o.name;
            break;
          }
        }
      }

      const isArmorBucket =
        inv.bucket.toLowerCase().includes("helmet") ||
        inv.bucket.toLowerCase().includes("gauntlet") ||
        inv.bucket.toLowerCase().includes("chest") ||
        inv.bucket.toLowerCase().includes("leg") ||
        inv.bucket.toLowerCase().includes("class") ||
        inv.bucket === "Helmet" ||
        inv.bucket === "Gauntlets" ||
        inv.bucket === "Chest" ||
        inv.bucket === "Legs" ||
        inv.bucket === "ClassItem";

      if (inv.statValues && (isArmorBucket || exoA || isArmorSetSlot(item.slot))) {
        next.statValues = inv.statValues;
        next.totalStats = computeTotalArmorStats(inv.statValues);
        next.statsIncomplete = !isCompleteArmorStats(inv.statValues);
        const tier = resolveArmorTier({
          gearTier: inv.gearTier ?? null,
          totalStats: next.totalStats,
          isExotic: next.isExotic ?? false,
          statsComplete: !next.statsIncomplete,
        });
        next.tier = tier.tier;
        next.tierLabel = tier.label;
      } else if (inv.gearTier != null) {
        next.tier = inv.gearTier;
        next.tierLabel = `Tier ${inv.gearTier}`;
      }
    } else if (item.selectedPerks.length > 0) {
      next.selectedTraitPerks = traitNamesFromHashes(
        item.selectedPerks,
        perkByHash,
      );
    }

    next.linkedSynergies = collectLinkedSynergies(db, userId, item, [
      ...(next.selectedTraitPerks ?? []).map((p) => p.hash),
      ...item.selectedPerks,
    ]);

    enriched.push(next);
  }

  const armorPieces = enriched.filter((i) => isArmorSetSlot(i.slot));
  const armorStatTotals =
    armorPieces.length > 0 ? sumArmorSetStats(armorPieces) : null;

  return { items: enriched, armorStatTotals };
}

function isArmorSetSlot(slot: string): boolean {
  return [
    "helmet",
    "arms",
    "chest",
    "legs",
    "class_item",
    "exotic_armor",
  ].includes(slot);
}

function traitNamesFromHashes(
  hashes: number[],
  perkByHash: Map<number, { hash: number; name: string; plugTypeName?: string | null }>,
): SetItemPerkName[] {
  const out: SetItemPerkName[] = [];
  const seen = new Set<number>();
  for (const h of hashes) {
    if (seen.has(h)) continue;
    const p = perkByHash.get(h);
    if (!p) continue;
    if (!isTraitPlugType(p.plugTypeName)) continue;
    seen.add(h);
    out.push({ hash: p.hash, name: p.name });
  }
  return out;
}

function collectAvailableTraits(
  columns: Array<{ column: number; curated: number[]; randomized: number[] }>,
  perkByHash: Map<number, { hash: number; name: string; plugTypeName?: string | null }>,
  selectedHashes: number[],
): SetItemPerkName[] {
  const selected = new Set(selectedHashes);
  const out: SetItemPerkName[] = [];
  const seen = new Set<number>();
  // Skip barrel (0) and magazine (1) columns when present as fixed layout
  for (const col of columns) {
    if (col.column === 0 || col.column === 1) {
      // Still allow if plugs are traits (exotic batteries etc.) — filter by type
    }
    for (const h of [...col.curated, ...col.randomized]) {
      if (selected.has(h) || seen.has(h)) continue;
      const p = perkByHash.get(h);
      if (!p || !isTraitPlugType(p.plugTypeName)) continue;
      // Skip pure barrel/mag by column only for legendary layout when type missing
      if (
        (col.column === 0 || col.column === 1) &&
        !p.plugTypeName
      ) {
        continue;
      }
      if (col.column === 0 || col.column === 1) {
        const t = (p.plugTypeName ?? "").toLowerCase();
        if (t === "barrel" || t === "magazine" || t === "stock") continue;
      }
      seen.add(h);
      out.push({ hash: p.hash, name: p.name });
    }
  }
  return out.slice(0, 24);
}

function collectLinkedSynergies(
  db: AppDatabase,
  userId: number,
  item: SetItemRecord,
  perkHashes: number[],
): SetItemLinkedSynergy[] {
  const byId = new Map<string, SetItemLinkedSynergy>();

  const add = (rows: ReturnType<typeof findSynergiesByTarget>) => {
    for (const s of rows) {
      if (byId.has(s.id)) continue;
      byId.set(s.id, {
        id: s.id,
        label: formatSynergyTypeDesignation({
          type: s.type,
          subType: s.subType,
        }),
      });
    }
  };

  add(
    findSynergiesByTarget(db, userId, {
      kind: "weapon",
      itemHash: item.itemHash,
    }),
  );
  add(
    findSynergiesByTarget(db, userId, {
      kind: "exotic_armor",
      itemHash: item.itemHash,
    }),
  );
  for (const h of [...new Set(perkHashes)]) {
    add(
      findSynergiesByTarget(db, userId, {
        kind: "weapon_perk",
        perkHash: h,
      }),
    );
  }

  return [...byId.values()].sort((a, b) =>
    a.label.localeCompare(b.label, undefined, { sensitivity: "base" }),
  );
}
