import {
  evaluateFinishGaps,
  type FinishAttachmentInput,
  type FinishEquipmentClaim,
  type FinishGapsResult,
} from "@/lib/builds/finishGaps";
import type { SetType } from "@/lib/sets/schemas";

/** Shape attachments from build detail / variant for gap eval. */
export function attachmentsToFinishInput(
  attachments: Array<{
    setId: string;
    mode: string;
    set?: { type?: string; name?: string } | null;
  }>,
): FinishAttachmentInput[] {
  const out: FinishAttachmentInput[] = [];
  for (const a of attachments) {
    const t = a.set?.type;
    if (!t) continue;
    out.push({
      setId: a.setId,
      mode: a.mode === "snapshot" ? "snapshot" : "live",
      setType: t as SetType,
      setName: a.set?.name,
    });
  }
  return out;
}

export function equipmentRecordFromResolved(
  equipment: Partial<
    Record<string, { slot?: string; itemHash?: number; itemName?: string; instanceId?: string | null } | null>
  > | null | undefined,
): Partial<Record<string, FinishEquipmentClaim>> {
  const out: Partial<Record<string, FinishEquipmentClaim>> = {};
  if (!equipment) return out;
  for (const [key, claim] of Object.entries(equipment)) {
    if (!claim || !claim.itemHash) continue;
    const slot = claim.slot ?? key;
    out[slot] = {
      slot,
      itemHash: claim.itemHash,
      itemName: claim.itemName ?? slot,
      instanceId: claim.instanceId,
    };
  }
  return out;
}

export function evaluateFinishGapsFromVariant(input: {
  variantId: string;
  isDefaultVariant: boolean;
  attachments: Array<{
    setId: string;
    mode: string;
    set?: { type?: string; name?: string } | null;
  }>;
  equipment?: Partial<
    Record<string, { slot?: string; itemHash?: number; itemName?: string; instanceId?: string | null } | null>
  > | null;
  hasModCoverage?: boolean;
  skippedKeys?: readonly string[];
}): FinishGapsResult {
  return evaluateFinishGaps({
    variantId: input.variantId,
    isDefaultVariant: input.isDefaultVariant,
    attachments: attachmentsToFinishInput(input.attachments),
    equipment: equipmentRecordFromResolved(input.equipment),
    hasModCoverage: input.hasModCoverage,
    skippedKeys: input.skippedKeys,
  });
}
