import type { ArmorSlotName, WeaponSlotName } from "@/lib/manifest/types/records";
import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { AttachmentRecord } from "@/lib/db/repositories/variantRepository";
import type { BuildRecord } from "@/lib/db/repositories/buildRepository";
import type { VariantRecord } from "@/lib/db/repositories/variantRepository";
import type { SetType } from "@/lib/sets/schemas";
import type { EquipmentSlot } from "@/lib/sets/schemas";
import { getSet } from "@/lib/db/repositories/setRepository";
import type { AppDatabase } from "@/lib/db/client";
import { listActiveSetItems, type SetItemRecord } from "@/lib/sets/setItemService";

export type SlotClaim = {
  slot: EquipmentSlot;
  itemHash: number;
  itemName: string;
  source: "set" | "build_exotic_armor" | "variant_exotic_weapon" | "pair_set";
  setId?: string;
  selectedPerks?: number[];
};

export type ResolvedVariantEquipment = {
  equipment: Partial<Record<EquipmentSlot, SlotClaim>>;
  conflicts: Array<{ slot: EquipmentSlot; claimants: SlotClaim[] }>;
};

const WEAPON_SLOT_MAP: Record<WeaponSlotName, EquipmentSlot> = {
  Kinetic: "primary",
  Energy: "special",
  Power: "heavy",
};

const ARMOR_SLOT_MAP: Record<ArmorSlotName, EquipmentSlot> = {
  Helmet: "helmet",
  Gauntlets: "arms",
  Chest: "chest",
  Legs: "legs",
  ClassItem: "class_item",
};

export function weaponManifestSlotToEquipment(slot: WeaponSlotName): EquipmentSlot {
  return WEAPON_SLOT_MAP[slot];
}

export function armorManifestSlotToEquipment(slot: ArmorSlotName): EquipmentSlot {
  return ARMOR_SLOT_MAP[slot];
}

export type ExpandedSetItem = {
  slot: EquipmentSlot;
  itemHash: number;
  itemName: string;
  selectedPerks?: number[];
  setId: string;
  setType: SetType;
};

export function detectSlotConflicts(claims: SlotClaim[]): ResolvedVariantEquipment["conflicts"] {
  const bySlot = new Map<EquipmentSlot, SlotClaim[]>();
  for (const claim of claims) {
    const list = bySlot.get(claim.slot) ?? [];
    list.push(claim);
    bySlot.set(claim.slot, list);
  }
  return [...bySlot.entries()]
    .filter(([, claimants]) => claimants.length > 1)
    .map(([slot, claimants]) => ({ slot, claimants }));
}

export function buildEquipmentMap(claims: SlotClaim[]): Partial<Record<EquipmentSlot, SlotClaim>> {
  const equipment: Partial<Record<EquipmentSlot, SlotClaim>> = {};
  for (const claim of claims) {
    if (!equipment[claim.slot]) {
      equipment[claim.slot] = claim;
    }
  }
  return equipment;
}

export function validatePairArmorMatch(
  build: Pick<BuildRecord, "exoticArmorHash">,
  pairItems: ExpandedSetItem[],
): void {
  const pairArmor = pairItems.find((i) => i.slot === "exotic_armor");
  if (pairArmor && pairArmor.itemHash !== build.exoticArmorHash) {
    throw new ApiError(
      API_ERROR_CODES.PAIR_ARMOR_MISMATCH,
      "Pair set exotic armor must match build exotic armor",
      { expected: build.exoticArmorHash, actual: pairArmor.itemHash },
      409,
    );
  }
}

export function expandAttachmentItems(
  attachment: AttachmentRecord,
  items: ExpandedSetItem[],
): ExpandedSetItem[] {
  return items.map((item) => ({ ...item, setId: attachment.setId }));
}

export async function loadExpandedAttachmentItems(
  db: AppDatabase,
  userId: number,
  attachment: AttachmentRecord,
): Promise<ExpandedSetItem[]> {
  const set = getSet(db, userId, attachment.setId);
  if (!set) return [];

  if (set.type === "fashion") return [];

  if (attachment.mode === "snapshot" && attachment.snapshotConfigs) {
    return attachment.snapshotConfigs.map((cfg) => ({
      slot: cfg.slot as EquipmentSlot,
      itemHash: cfg.itemHash,
      itemName: cfg.itemName,
      selectedPerks: cfg.selectedPerks,
      setId: attachment.setId,
      setType: set.type,
    }));
  }

  const active = await listActiveSetItems(db, attachment.setId);
  return active.map((item: SetItemRecord) => ({
    slot: item.slot as EquipmentSlot,
    itemHash: item.itemHash,
    itemName: item.itemName,
    selectedPerks: item.selectedPerks,
    setId: attachment.setId,
    setType: set.type,
  }));
}

export function itemsToSlotClaims(items: ExpandedSetItem[]): SlotClaim[] {
  return items.map((item) => ({
    slot: item.slot,
    itemHash: item.itemHash,
    itemName: item.itemName,
    source: item.setType === "pair" ? "pair_set" : "set",
    setId: item.setId,
    selectedPerks: item.selectedPerks,
  }));
}

export function addExoticWeaponClaim(
  claims: SlotClaim[],
  variant: Pick<VariantRecord, "exoticWeaponHash" | "exoticWeaponName">,
  weaponSlot: EquipmentSlot | null,
): SlotClaim[] {
  if (!variant.exoticWeaponHash || !weaponSlot) return claims;
  return [
    ...claims,
    {
      slot: weaponSlot,
      itemHash: variant.exoticWeaponHash,
      itemName: variant.exoticWeaponName ?? `Exotic (${variant.exoticWeaponHash})`,
      source: "variant_exotic_weapon",
    },
  ];
}

export function addExoticArmorClaim(
  claims: SlotClaim[],
  build: Pick<BuildRecord, "exoticArmorHash" | "exoticArmorName">,
  armorSlot: EquipmentSlot | null,
): SlotClaim[] {
  if (!armorSlot) return claims;
  return [
    ...claims,
    {
      slot: armorSlot,
      itemHash: build.exoticArmorHash,
      itemName: build.exoticArmorName,
      source: "build_exotic_armor",
    },
  ];
}

export function assertNoSlotConflicts(resolved: ResolvedVariantEquipment): void {
  if (resolved.conflicts.length === 0) return;
  throw new ApiError(
    API_ERROR_CODES.SLOT_CONFLICT,
    "Multiple items claim the same equipment slot",
    {
      conflicts: resolved.conflicts.map((c) => ({
        slot: c.slot,
        claimants: c.claimants.map((x) => ({ source: x.source, setId: x.setId, itemHash: x.itemHash })),
      })),
    },
    409,
  );
}

export function assertVariantNotEmpty(resolved: ResolvedVariantEquipment): void {
  if (Object.keys(resolved.equipment).length === 0) {
    throw new ApiError(API_ERROR_CODES.VARIANT_EMPTY, "Variant must fill at least one equipment slot", {}, 400);
  }
}

export async function resolveVariantEquipment(
  db: AppDatabase,
  userId: number,
  build: BuildRecord,
  variant: VariantRecord,
  attachments: AttachmentRecord[],
  opts?: {
    exoticWeaponSlot?: EquipmentSlot | null;
    exoticArmorSlot?: EquipmentSlot | null;
  },
): Promise<ResolvedVariantEquipment> {
  const expanded: ExpandedSetItem[] = [];
  for (const attachment of attachments) {
    expanded.push(...(await loadExpandedAttachmentItems(db, userId, attachment)));
  }

  validatePairArmorMatch(build, expanded.filter((i) => i.setType === "pair"));

  let claims = itemsToSlotClaims(expanded);
  claims = addExoticWeaponClaim(claims, variant, opts?.exoticWeaponSlot ?? null);
  claims = addExoticArmorClaim(claims, build, opts?.exoticArmorSlot ?? null);

  const conflicts = detectSlotConflicts(claims);
  return {
    equipment: buildEquipmentMap(claims),
    conflicts,
  };
}
