import { describe, expect, it } from "vitest";

import {
  evaluateCoverage,
  matchEvidenceLink,
  tierForMatches,
} from "@/lib/builds/coverage";
import type { SlotClaim } from "@/lib/builds/resolveVariant";
import type { SynergyLinkRecord, SynergyWithLinks } from "@/lib/db/repositories/synergyRepository";
import type { SetBonusRecord } from "@/lib/manifest/types/records";

function link(partial: Partial<SynergyLinkRecord> & Pick<SynergyLinkRecord, "kind" | "displayName">): SynergyLinkRecord {
  return {
    id: partial.id ?? crypto.randomUUID(),
    synergyId: partial.synergyId ?? "syn",
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
  };
}

function synergy(name: string, links: SynergyLinkRecord[]): SynergyWithLinks {
  return {
    id: "syn-1",
    userId: 1,
    name,
    type: "melee",
    subType: null,
    description: "",
    createdAt: "",
    updatedAt: "",
    links,
  };
}

function claim(partial: Partial<SlotClaim> & Pick<SlotClaim, "slot" | "itemHash">): SlotClaim {
  return {
    slot: partial.slot,
    itemHash: partial.itemHash,
    itemName: partial.itemName ?? "Item",
    source: partial.source ?? "set",
    selectedPerks: partial.selectedPerks,
  };
}

describe("tierForMatches", () => {
  it("maps all/some/none", () => {
    expect(tierForMatches(2, 2)).toBe("supported");
    expect(tierForMatches(1, 2)).toBe("weak");
    expect(tierForMatches(0, 2)).toBe("missing");
    expect(tierForMatches(0, 0)).toBe("missing");
  });
});

describe("matchEvidenceLink", () => {
  it("matches weapon by itemHash", () => {
    const ok = matchEvidenceLink(
      link({ kind: "weapon", displayName: "Gun", itemHash: 10 }),
      [claim({ slot: "primary", itemHash: 10 })],
    );
    expect(ok).toBe(true);
  });

  it("matches weapon_perk via selectedPerks", () => {
    const ok = matchEvidenceLink(
      link({ kind: "weapon_perk", displayName: "Perk", perkHash: 99 }),
      [claim({ slot: "primary", itemHash: 1, selectedPerks: [99] })],
    );
    expect(ok).toBe(true);
  });
});

describe("evaluateCoverage synergies", () => {
  it("reports supported / weak / missing per Q1=A", () => {
    const links = [
      link({ id: "a", kind: "weapon", displayName: "A", itemHash: 1 }),
      link({ id: "b", kind: "weapon", displayName: "B", itemHash: 2 }),
    ];
    const syn = synergy("Trace", links);

    const supported = evaluateCoverage({
      claims: [claim({ slot: "primary", itemHash: 1 }), claim({ slot: "special", itemHash: 2 })],
      synergies: [syn],
      subclass: { name: "Stormcaller", element: "Arc" },
    });
    expect(supported.synergies[0]?.tier).toBe("supported");

    const weak = evaluateCoverage({
      claims: [claim({ slot: "primary", itemHash: 1 })],
      synergies: [syn],
      subclass: { name: "Stormcaller", element: "Arc" },
    });
    expect(weak.synergies[0]?.tier).toBe("weak");
    expect(weak.synergies[0]?.unmatchedLinks).toHaveLength(1);

    const missing = evaluateCoverage({
      claims: [claim({ slot: "primary", itemHash: 9 })],
      synergies: [syn],
      subclass: { name: "Stormcaller", element: "Arc" },
    });
    expect(missing.synergies[0]?.tier).toBe("missing");
  });

  it("does not invent softStats when no targets", () => {
    const result = evaluateCoverage({
      claims: [],
      synergies: [],
      subclass: {},
    });
    expect(result.softStats).toEqual([]);
    expect(result.targets).toEqual({});
    expect(result.setBonuses).toEqual([]);
    expect(result.elementMismatches).toEqual([]);
  });
});

describe("evaluateCoverage set-bonus and element", () => {
  it("reports partial set-bonus soft row", () => {
    const record: SetBonusRecord = {
      hash: 500,
      name: "Field-Tested",
      searchName: "field-tested",
      icon: "",
      itemHashes: [101, 102, 103, 104],
      perks: [
        { requiredCount: 2, name: "2pc", description: "" },
        { requiredCount: 4, name: "4pc", description: "" },
      ],
    };
    const byHash = new Map([
      [101, record],
      [102, record],
    ]);
    const result = evaluateCoverage({
      claims: [claim({ slot: "helmet", itemHash: 101 })],
      synergies: [],
      subclass: { element: "Solar" },
      setBonusByItemHash: byHash,
    });
    expect(result.setBonuses[0]).toMatchObject({
      setName: "Field-Tested",
      pieceCount: 1,
      status: "partial",
    });
  });

  it("reports element soft mismatch for off-element special", () => {
    const result = evaluateCoverage({
      claims: [claim({ slot: "special", itemHash: 77 })],
      synergies: [],
      subclass: { element: "Void" },
      weaponElementByHash: new Map([[77, "Solar"]]),
    });
    expect(result.elementMismatches).toHaveLength(1);
    expect(result.elementMismatches[0]?.hint).toContain("Solar");
  });
});
