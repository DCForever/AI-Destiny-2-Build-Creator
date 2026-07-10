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
  instanceId?: string | null;
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
  instanceId?: string | null;
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
  opts?: { intentMode?: boolean },
): void {
  if (build.exoticArmorHash == null) return;
  const pairArmor = pairItems.find((i) => i.slot === "exotic_armor");
  if (!pairArmor) return;
  if (pairArmor.itemHash === build.exoticArmorHash) return;
  if (opts?.intentMode) return;
  throw new ApiError(
    API_ERROR_CODES.PAIR_ARMOR_MISMATCH,
    "Pair set exotic armor must match build exotic armor",
    { expected: build.exoticArmorHash, actual: pairArmor.itemHash },
    409,
  );
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
      instanceId: cfg.instanceId ?? null,
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
    instanceId: item.instanceId,
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
    instanceId: item.instanceId ?? null,
  }));
}

export function addExoticWeaponClaim(
  claims: SlotClaim[],
  weapon: { exoticWeaponHash: number | null; exoticWeaponName: string | null },
  weaponSlot: EquipmentSlot | null,
  source: SlotClaim["source"] = "variant_exotic_weapon",
): SlotClaim[] {
  if (!weapon.exoticWeaponHash || !weaponSlot) return claims;
  return [
    ...claims,
    {
      slot: weaponSlot,
      itemHash: weapon.exoticWeaponHash,
      itemName: weapon.exoticWeaponName ?? `Exotic (${weapon.exoticWeaponHash})`,
      source,
    },
  ];
}

export function addExoticArmorClaim(
  claims: SlotClaim[],
  build: Pick<BuildRecord, "exoticArmorHash" | "exoticArmorName">,
  armorSlot: EquipmentSlot | null,
  opts?: { skipIfClassItemClaimed?: boolean },
): SlotClaim[] {
  if (!armorSlot || build.exoticArmorHash == null) return claims;
  if (opts?.skipIfClassItemClaimed && claims.some((c) => c.slot === "class_item")) {
    return claims;
  }
  return [
    ...claims,
    {
      slot: armorSlot,
      itemHash: build.exoticArmorHash,
      itemName: build.exoticArmorName ?? `Exotic (${build.exoticArmorHash})`,
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

const REQUIRED_WEAPON_SLOTS: EquipmentSlot[] = ["primary", "special", "heavy"];
const REQUIRED_ARMOR_SLOTS: EquipmentSlot[] = ["helmet", "arms", "chest", "legs", "class_item"];

export function assertFullCombatLoadout(
  resolved: ResolvedVariantEquipment,
  build: BuildRecord,
  opts?: { hasMods?: boolean },
): void {
  const missing: string[] = [];
  for (const slot of REQUIRED_WEAPON_SLOTS) {
    if (!resolved.equipment[slot]) missing.push(slot);
  }
  for (const slot of REQUIRED_ARMOR_SLOTS) {
    if (!resolved.equipment[slot]) missing.push(slot);
  }
  if (!build.className) missing.push("className");
  const subclass = build.subclass as { name?: string; super?: string } | null;
  if (!subclass || typeof subclass !== "object" || !subclass.name) {
    missing.push("subclass");
  }
  if (!opts?.hasMods) missing.push("mods");

  if (missing.length > 0) {
    throw new ApiError(
      API_ERROR_CODES.DEFAULT_VARIANT_INCOMPLETE,
      "Default variant must be a full combat loadout",
      { missing },
      400,
    );
  }
}

export function effectiveExoticWeapon(
  build: BuildRecord,
  variant: VariantRecord,
): { exoticWeaponHash: number | null; exoticWeaponName: string | null; fromBuild: boolean } {
  if (build.exoticWeaponHash != null) {
    return {
      exoticWeaponHash: build.exoticWeaponHash,
      exoticWeaponName: build.exoticWeaponName,
      fromBuild: true,
    };
  }
  return {
    exoticWeaponHash: variant.exoticWeaponHash,
    exoticWeaponName: variant.exoticWeaponName,
    fromBuild: false,
  };
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

  const intentMode = opts?.exoticArmorSlot === "class_item";
  validatePairArmorMatch(build, expanded.filter((i) => i.setType === "pair"), { intentMode });

  let claims = itemsToSlotClaims(expanded);
  const weapon = effectiveExoticWeapon(build, variant);
  claims = addExoticWeaponClaim(
    claims,
    weapon,
    opts?.exoticWeaponSlot ?? null,
    weapon.fromBuild ? "variant_exotic_weapon" : "variant_exotic_weapon",
  );
  claims = addExoticArmorClaim(claims, build, opts?.exoticArmorSlot ?? null, {
    skipIfClassItemClaimed: intentMode,
  });

  const conflicts = detectSlotConflicts(claims);
  return {
    equipment: buildEquipmentMap(claims),
    conflicts,
  };
}
