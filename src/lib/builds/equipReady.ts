import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { EquipmentSlot } from "@/lib/sets/schemas";
import type { ResolvedVariantEquipment, SlotClaim } from "@/lib/builds/resolveVariant";

export type PinStatusKind = "wishlist" | "pinned" | "stale";

export type PinStatus = {
  slot: EquipmentSlot;
  status: PinStatusKind;
  instanceId?: string;
  reason?: "instance_missing" | "hash_mismatch";
};

export type EquipReadyResult = {
  equipReady: boolean;
  pinStatuses: PinStatus[];
};

export type InventoryPinIndex = Map<string, { itemHash: number }>;

const COMBAT_SLOTS: EquipmentSlot[] = [
  "primary",
  "special",
  "heavy",
  "helmet",
  "arms",
  "chest",
  "legs",
  "class_item",
];

export function buildInventoryPinIndex(
  items: Array<{ instanceId: string; itemHash: number }>,
): InventoryPinIndex {
  const map: InventoryPinIndex = new Map();
  for (const item of items) {
    map.set(item.instanceId, { itemHash: item.itemHash });
  }
  return map;
}

function statusForClaim(claim: SlotClaim, inventory: InventoryPinIndex): PinStatus {
  if (!claim.instanceId) {
    return { slot: claim.slot, status: "wishlist" };
  }
  const owned = inventory.get(claim.instanceId);
  if (!owned) {
    return {
      slot: claim.slot,
      status: "stale",
      instanceId: claim.instanceId,
      reason: "instance_missing",
    };
  }
  if (owned.itemHash !== claim.itemHash) {
    return {
      slot: claim.slot,
      status: "stale",
      instanceId: claim.instanceId,
      reason: "hash_mismatch",
    };
  }
  return { slot: claim.slot, status: "pinned", instanceId: claim.instanceId };
}

/** Evaluate equip-ready over applied combat slots only (empty gaps ignored). */
export function computeEquipReady(
  resolved: ResolvedVariantEquipment,
  inventory: InventoryPinIndex,
): EquipReadyResult {
  const pinStatuses: PinStatus[] = [];
  for (const slot of COMBAT_SLOTS) {
    const claim = resolved.equipment[slot];
    if (!claim) continue;
    pinStatuses.push(statusForClaim(claim, inventory));
  }
  const equipReady = pinStatuses.length > 0 && pinStatuses.every((s) => s.status === "pinned");
  return { equipReady, pinStatuses };
}

export function assertEquipReady(result: EquipReadyResult): void {
  if (result.equipReady) return;
  throw new ApiError(
    API_ERROR_CODES.NOT_EQUIP_READY,
    "Variant is not equip-ready: applied slots need non-stale owned instance pins",
    { pinStatuses: result.pinStatuses, allowed: false },
    409,
  );
}
