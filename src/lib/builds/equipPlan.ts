import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { ResolvedArtifact, ResolvedFashion } from "@/lib/builds/resolveArtifactFashion";
import type { ResolvedVariantEquipment } from "@/lib/builds/resolveVariant";
import type { UserInventoryItem } from "@/lib/db/types";
import type { EquipmentSlot } from "@/lib/sets/schemas";

export type EquipStepKind = "transfer" | "equip" | "artifact" | "fashion";

export type PlannedEquipStep = {
  id: string;
  kind: EquipStepKind;
  slot?: string;
  itemHash?: number;
  instanceId?: string;
  /** For transfer: true = character → vault; false = vault → character. */
  transferToVault?: boolean;
  /** Artifact unlock hashes when kind === "artifact". */
  artifactConfig?: number[];
};

export type EquipPlanInput = {
  equipment: ResolvedVariantEquipment["equipment"];
  artifact: ResolvedArtifact;
  fashion: ResolvedFashion;
  inventory: UserInventoryItem[];
  characterId: string;
};

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

function inventoryByInstance(items: UserInventoryItem[]): Map<string, UserInventoryItem> {
  const map = new Map<string, UserInventoryItem>();
  for (const item of items) map.set(item.instanceId, item);
  return map;
}

function inventoryByHash(items: UserInventoryItem[]): Map<number, UserInventoryItem> {
  const map = new Map<number, UserInventoryItem>();
  for (const item of items) {
    if (!map.has(item.itemHash)) map.set(item.itemHash, item);
  }
  return map;
}

function needsTransfer(item: UserInventoryItem, characterId: string): boolean {
  if (item.location === "vault") return true;
  if (item.characterId && item.characterId !== characterId) return true;
  return false;
}

function appendTransfers(
  steps: PlannedEquipStep[],
  slot: string,
  item: UserInventoryItem,
  characterId: string,
): void {
  const onOtherCharacter =
    (item.location === "character" || item.location === "equipped") &&
    item.characterId != null &&
    item.characterId !== characterId;

  if (onOtherCharacter) {
    steps.push({
      id: `transfer-${slot}-to-vault`,
      kind: "transfer",
      slot,
      itemHash: item.itemHash,
      instanceId: item.instanceId,
      transferToVault: true,
    });
    steps.push({
      id: `transfer-${slot}-from-vault`,
      kind: "transfer",
      slot,
      itemHash: item.itemHash,
      instanceId: item.instanceId,
      transferToVault: false,
    });
    return;
  }

  if (item.location === "vault") {
    steps.push({
      id: `transfer-${slot}`,
      kind: "transfer",
      slot,
      itemHash: item.itemHash,
      instanceId: item.instanceId,
      transferToVault: false,
    });
  }
}

/** Pure planner: transfer → equip combat pins → artifact → fashion (omit empty fashion). */
export function planEquipSteps(input: EquipPlanInput): PlannedEquipStep[] {
  const steps: PlannedEquipStep[] = [];
  const byInstance = inventoryByInstance(input.inventory);
  const byHash = inventoryByHash(input.inventory);

  for (const slot of COMBAT_SLOTS) {
    const claim = input.equipment[slot];
    if (!claim?.instanceId) continue;
    const item = byInstance.get(claim.instanceId);
    if (!item) {
      throw new ApiError(
        API_ERROR_CODES.NOT_EQUIP_READY,
        `Combat pin instance missing from inventory for slot ${slot}`,
        {
          slot,
          instanceId: claim.instanceId,
          reason: "instance_missing",
          allowed: false,
        },
        409,
      );
    }

    if (needsTransfer(item, input.characterId)) {
      appendTransfers(steps, slot, item, input.characterId);
    }

    steps.push({
      id: `equip-${slot}`,
      kind: "equip",
      slot,
      itemHash: claim.itemHash,
      instanceId: claim.instanceId,
    });
  }

  if (input.artifact) {
    steps.push({
      id: "artifact",
      kind: "artifact",
      itemHash: input.artifact.hash,
      artifactConfig: input.artifact.config,
    });
  }

  if (input.fashion) {
    for (const [slot, piece] of Object.entries(input.fashion.slots)) {
      if (!piece) continue;
      const owned = byHash.get(piece.itemHash);
      steps.push({
        id: `fashion-${slot}`,
        kind: "fashion",
        slot,
        itemHash: piece.itemHash,
        instanceId: owned?.instanceId,
      });
    }
  }

  return steps;
}
