import { describe, expect, it } from "vitest";

import {
  assertRequiredLinksSatisfied,
  collectRequiredLinkFailures,
  equipReadyClaims,
  isRequiredLinkSatisfied,
} from "@/lib/builds/assertRequiredLinks";
import { buildInventoryPinIndex } from "@/lib/builds/equipReady";
import type { ResolvedVariantEquipment, SlotClaim } from "@/lib/builds/resolveVariant";
import type { SynergyLinkRecord, SynergyWithLinks } from "@/lib/db/repositories/synergyRepository";
import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";

function link(
  partial: Partial<SynergyLinkRecord> &
    Pick<SynergyLinkRecord, "kind" | "displayName">,
): SynergyLinkRecord {
  return {
    id: partial.id ?? "L1",
    synergyId: partial.synergyId ?? "S1",
    kind: partial.kind,
    displayName: partial.displayName,
    itemHash: partial.itemHash ?? null,
    perkHash: partial.perkHash ?? null,
    parentItemHash: partial.parentItemHash ?? null,
    originTraitName: partial.originTraitName ?? null,
    originTraitHash: partial.originTraitHash ?? null,
    armorSetName: partial.armorSetName ?? null,
    bonusPieces: partial.bonusPieces ?? null,
    bonusName: partial.bonusName ?? null,
    armorSetHash: partial.armorSetHash ?? null,
    required: partial.required ?? false,
  };
}

function synergy(links: SynergyLinkRecord[]): SynergyWithLinks {
  return {
    id: "S1",
    userId: 1,
    name: "Melee: Base",
    type: "melee",
    subType: "Base",
    description: "",
    createdAt: "",
    updatedAt: "",
    links,
  };
}

function claim(
  partial: Partial<SlotClaim> & Pick<SlotClaim, "slot" | "itemHash">,
): SlotClaim {
  return {
    slot: partial.slot,
    itemHash: partial.itemHash,
    itemName: partial.itemName ?? "Item",
    source: partial.source ?? "set",
    selectedPerks: partial.selectedPerks,
    instanceId: partial.instanceId,
  };
}

function resolved(
  claims: SlotClaim[],
): ResolvedVariantEquipment {
  const equipment: ResolvedVariantEquipment["equipment"] = {};
  for (const c of claims) equipment[c.slot] = c;
  return { equipment, conflicts: [] };
}

describe("isRequiredLinkSatisfied", () => {
  it("rejects wishlist match without pin", () => {
    const l = link({
      kind: "weapon",
      displayName: "Fatebringer",
      itemHash: 10,
      required: true,
    });
    const all = [claim({ slot: "primary", itemHash: 10 })];
    const result = isRequiredLinkSatisfied(l, {
      readyClaims: [],
      allClaims: all,
    });
    expect(result).toEqual({ ok: false, reason: "wishlist_or_stale" });
  });

  it("accepts equip-ready pin match", () => {
    const l = link({
      kind: "weapon",
      displayName: "Fatebringer",
      itemHash: 10,
      required: true,
    });
    const pinned = claim({
      slot: "primary",
      itemHash: 10,
      instanceId: "inst-1",
    });
    const inv = buildInventoryPinIndex([{ instanceId: "inst-1", itemHash: 10 }]);
    const ready = equipReadyClaims(resolved([pinned]), inv);
    const result = isRequiredLinkSatisfied(l, {
      readyClaims: ready,
      allClaims: [pinned],
    });
    expect(result).toEqual({ ok: true });
  });

  it("matches artifact_perk from applied config", () => {
    const l = link({
      kind: "artifact_perk",
      displayName: "Anti-Barrier",
      perkHash: 55,
      required: true,
    });
    expect(
      isRequiredLinkSatisfied(l, {
        readyClaims: [],
        allClaims: [],
        ctx: { artifactConfig: [55] },
      }),
    ).toEqual({ ok: true });
    expect(
      isRequiredLinkSatisfied(l, {
        readyClaims: [],
        allClaims: [],
        ctx: { artifactConfig: [] },
      }),
    ).toEqual({ ok: false, reason: "unmatched" });
  });

  it("matches required aspect from applied kit without pins", () => {
    const l = link({
      kind: "aspect",
      displayName: "Roaring Flames",
      required: true,
    });
    expect(
      isRequiredLinkSatisfied(l, {
        readyClaims: [],
        allClaims: [],
        ctx: { kit: { aspects: ["Roaring Flames"] } },
      }),
    ).toEqual({ ok: true });
  });
});

describe("collectRequiredLinkFailures / assert", () => {
  it("ignores non-required links", () => {
    const failures = collectRequiredLinkFailures({
      synergies: [
        synergy([
          link({
            kind: "weapon",
            displayName: "Soft",
            itemHash: 99,
            required: false,
          }),
        ]),
      ],
      resolved: resolved([]),
      inventory: buildInventoryPinIndex([]),
    });
    expect(failures).toEqual([]);
  });

  it("throws REQUIRED_LINK_UNSATISFIED when required link missing pin", () => {
    const syn = synergy([
      link({
        kind: "weapon",
        displayName: "Required Gun",
        itemHash: 10,
        required: true,
      }),
    ]);
    try {
      assertRequiredLinksSatisfied({
        synergies: [syn],
        resolved: resolved([claim({ slot: "primary", itemHash: 10 })]),
        inventory: buildInventoryPinIndex([]),
      });
      expect.unreachable();
    } catch (e) {
      expect(e).toBeInstanceOf(ApiError);
      expect((e as ApiError).code).toBe(API_ERROR_CODES.REQUIRED_LINK_UNSATISFIED);
    }
  });

  it("passes when required link is pin-satisfied", () => {
    const syn = synergy([
      link({
        kind: "weapon",
        displayName: "Required Gun",
        itemHash: 10,
        required: true,
      }),
    ]);
    expect(() =>
      assertRequiredLinksSatisfied({
        synergies: [syn],
        resolved: resolved([
          claim({ slot: "primary", itemHash: 10, instanceId: "i1" }),
        ]),
        inventory: buildInventoryPinIndex([{ instanceId: "i1", itemHash: 10 }]),
      }),
    ).not.toThrow();
  });
});
