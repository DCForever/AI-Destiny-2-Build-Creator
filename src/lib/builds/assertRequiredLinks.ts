/**
 * Default-variant required synergy links (DBR-SYN-007–010a, BR-VAR-050).
 * Satisfaction: equip-ready pins only for gear claims; wishlist does not count.
 * Non-gear kinds (artifact_perk) use applied kit config on the variant.
 */

import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import {
  matchEvidenceLink,
  type MatchEvidenceContext,
  type SubclassKitMatchFields,
} from "@/lib/builds/coverage";
import {
  buildInventoryPinIndex,
  type InventoryPinIndex,
} from "@/lib/builds/equipReady";
import type { ResolvedVariantEquipment, SlotClaim } from "@/lib/builds/resolveVariant";
import type { SynergyLinkRecord, SynergyWithLinks } from "@/lib/db/repositories/synergyRepository";
import type { EquipmentSlot } from "@/lib/sets/schemas";
import type { SetBonusRecord } from "@/lib/manifest/types/records";

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

/** Link kinds satisfied by applied kit/config, not gear pins. */
const APPLIED_KIT_KINDS = new Set([
  "aspect",
  "fragment",
  "super",
  "melee",
  "grenade",
  "artifact_perk",
]);

export type RequiredLinkFailure = {
  synergyId: string;
  synergyName: string;
  linkId: string;
  kind: string;
  displayName: string;
  reason: "unmatched" | "wishlist_or_stale";
};

function claimIsEquipReady(claim: SlotClaim, inventory: InventoryPinIndex): boolean {
  if (!claim.instanceId) return false;
  const owned = inventory.get(claim.instanceId);
  if (!owned) return false;
  return owned.itemHash === claim.itemHash;
}

/** Claims that are equip-ready (non-stale owned pins). */
export function equipReadyClaims(
  resolved: ResolvedVariantEquipment,
  inventory: InventoryPinIndex,
): SlotClaim[] {
  const out: SlotClaim[] = [];
  for (const slot of COMBAT_SLOTS) {
    const claim = resolved.equipment[slot];
    if (!claim) continue;
    if (claimIsEquipReady(claim, inventory)) out.push(claim);
  }
  return out;
}

/**
 * Whether a required link is satisfied under DBR-SYN-010a.
 * Gear kinds use equip-ready claims only; wishlist-only identity never satisfies.
 */
export function isRequiredLinkSatisfied(
  link: SynergyLinkRecord,
  input: {
    readyClaims: SlotClaim[];
    allClaims: SlotClaim[];
    ctx?: MatchEvidenceContext;
  },
): { ok: true } | { ok: false; reason: RequiredLinkFailure["reason"] } {
  const ctx = input.ctx ?? {};

  if (APPLIED_KIT_KINDS.has(link.kind)) {
    const ok = matchEvidenceLink(link, input.allClaims, ctx);
    return ok ? { ok: true } : { ok: false, reason: "unmatched" };
  }

  // Soft evidence can match wishlist; required must use equip-ready only.
  const softMatch = matchEvidenceLink(link, input.allClaims, ctx);
  if (!softMatch) {
    return { ok: false, reason: "unmatched" };
  }
  const readyMatch = matchEvidenceLink(link, input.readyClaims, ctx);
  if (!readyMatch) {
    return { ok: false, reason: "wishlist_or_stale" };
  }
  return { ok: true };
}

export function collectRequiredLinkFailures(input: {
  synergies: SynergyWithLinks[];
  resolved: ResolvedVariantEquipment;
  inventory: InventoryPinIndex;
  setBonusByItemHash?: Map<number, SetBonusRecord>;
  artifactConfig?: number[] | null;
  kit?: SubclassKitMatchFields | null;
}): RequiredLinkFailure[] {
  const allClaims = Object.values(input.resolved.equipment).filter(
    (c): c is SlotClaim => c != null,
  );
  const readyClaims = equipReadyClaims(input.resolved, input.inventory);
  const ctx: MatchEvidenceContext = {
    setBonusByItemHash: input.setBonusByItemHash,
    artifactConfig: input.artifactConfig,
    kit: input.kit,
  };

  const failures: RequiredLinkFailure[] = [];
  for (const synergy of input.synergies) {
    for (const link of synergy.links) {
      if (link.required !== true) continue;
      const result = isRequiredLinkSatisfied(link, {
        readyClaims,
        allClaims,
        ctx,
      });
      if (result.ok) continue;
      failures.push({
        synergyId: synergy.id,
        synergyName: synergy.name,
        linkId: link.id,
        kind: link.kind,
        displayName: link.displayName,
        reason: result.reason,
      });
    }
  }
  return failures;
}

export function assertRequiredLinksSatisfied(input: {
  synergies: SynergyWithLinks[];
  resolved: ResolvedVariantEquipment;
  inventory: InventoryPinIndex;
  setBonusByItemHash?: Map<number, SetBonusRecord>;
  artifactConfig?: number[] | null;
  kit?: SubclassKitMatchFields | null;
}): void {
  const unsatisfied = collectRequiredLinkFailures(input);
  if (unsatisfied.length === 0) return;
  throw new ApiError(
    API_ERROR_CODES.REQUIRED_LINK_UNSATISFIED,
    "Default variant required synergy links need equip-ready pins",
    { unsatisfied },
    400,
  );
}

export { buildInventoryPinIndex };
