import { describe, expect, it } from "vitest";

import { buildPerkWeaponIndex } from "@/lib/manifest/perkWeaponIndex";
import type { WeaponRecord } from "@/lib/manifest/types/records";

import { mergeSynergyContext } from "./mergeSynergyContext";
import { suggestRolls } from "./suggestRolls";
import type { SynergyWithLinks } from "@/lib/db/repositories/synergyRepository";

const rifle: WeaponRecord = {
  hash: 1001,
  name: "Fatebringer",
  searchName: "fatebringer",
  icon: null,
  slot: "Kinetic",
  element: "Solar",
  ammo: "Primary",
  frame: "Adaptive Frame",
  itemTypeName: "Hand Cannon",
  originTraitHashes: [9001],
  perkColumns: [
    { column: 2, curated: [200], randomized: [201, 202] },
    { column: 3, curated: [300], randomized: [301] },
  ],
};

const arcRifle: WeaponRecord = {
  ...rifle,
  hash: 1002,
  name: "Ikelos SMG",
  searchName: "ikelos smg",
  element: "Arc",
  perkColumns: [{ column: 2, curated: [400], randomized: [401] }],
};

function synergyFixture(
  partial: Partial<SynergyWithLinks> & Pick<SynergyWithLinks, "id" | "name" | "type">,
): SynergyWithLinks {
  return {
    userId: 1,
    subType: null,
    description: "",
    createdAt: "",
    updatedAt: "",
    links: [],
    ...partial,
  };
}

describe("mergeSynergyContext", () => {
  it("merges all synergies with equal weight", () => {
    const merged = mergeSynergyContext(
      [
        synergyFixture({
          id: "s1",
          name: "Melee",
          type: "melee",
          links: [
            {
              id: "l1",
              synergyId: "s1",
              kind: "weapon_perk",
              displayName: "Firefly",
              itemHash: null,
              perkHash: 200,
              parentItemHash: null,
              originTraitName: null,
              originTraitHash: null,
              armorSetName: null,
              bonusPieces: null,
              bonusName: null,
              armorSetHash: null,
            },
          ],
        }),
        synergyFixture({ id: "s2", name: "Solar", type: "verb" }),
      ],
      { buildTagIds: ["solar"] },
    );

    expect(merged.perkHashes).toEqual([200]);
    expect(merged.tagIds).toContain("melee");
    expect(merged.tagIds).toContain("solar");
    expect(merged.tagIds).toContain("ability");
    expect(merged.synergies).toHaveLength(2);
  });

  it("collects weapon archetype sub-types", () => {
    const merged = mergeSynergyContext([
      synergyFixture({
        id: "s-arch",
        name: "Pulse Micro Missile",
        type: "weapon_archetype",
        subType: "Micro-Missile Frame",
      }),
    ]);

    expect(merged.weaponArchetypeSubTypes).toEqual(["Micro-Missile Frame"]);
  });
});

const microMissilePulse: WeaponRecord = {
  ...rifle,
  hash: 1003,
  name: "Outbreak Perfected",
  searchName: "outbreak perfected",
  frame: "Micro-Missile Frame",
  itemTypeName: "Pulse Rifle",
  perkColumns: [{ column: 2, curated: [500], randomized: [501] }],
};

describe("suggestRolls", () => {
  const perkIndex = buildPerkWeaponIndex("1.0", {
    weapons: [rifle, arcRifle, microMissilePulse],
    "exotic-weapons": [],
    "weapon-perks": [
      { hash: 200, name: "Firefly", searchName: "firefly", icon: null, description: "" },
      { hash: 201, name: "Explosive Payload", searchName: "explosive payload", icon: null, description: "" },
      { hash: 300, name: "Kill Clip", searchName: "kill clip", icon: null, description: "" },
      { hash: 400, name: "Seraph Rounds", searchName: "seraph rounds", icon: null, description: "" },
    ],
  });

  const perkNames = new Map([
    [200, "Firefly"],
    [201, "Explosive Payload"],
    [300, "Kill Clip"],
    [400, "Seraph Rounds"],
    [500, "Outbreak Prime"],
    [501, "Parasitism"],
  ]);

  it("returns at least two manifest-valid rolls with owned flags", () => {
    const context = mergeSynergyContext(
      [
        synergyFixture({
          id: "s1",
          name: "Solar Melee",
          type: "melee",
          links: [
            {
              id: "l1",
              synergyId: "s1",
              kind: "weapon_perk",
              displayName: "Firefly",
              itemHash: null,
              perkHash: 200,
              parentItemHash: null,
              originTraitName: null,
              originTraitHash: null,
              armorSetName: null,
              bonusPieces: null,
              bonusName: null,
              armorSetHash: null,
            },
          ],
        }),
      ],
      { setTagIds: ["solar"], buildTagIds: ["solar"] },
    );

    const suggestions = suggestRolls({
      context,
      perkIndex,
      perkNames,
      weapons: [rifle, arcRifle],
      ownedItems: [
        {
          instanceId: "inst-1",
          itemHash: 1001,
          bucket: "1498876634",
          location: "vault",
          power: 1800,
          isMasterwork: false,
          isCrafted: false,
          plugHashes: [200, 300],
          rollTags: [],
          syncedAt: new Date().toISOString(),
        },
      ],
    });

    expect(suggestions.length).toBeGreaterThanOrEqual(2);
    expect(suggestions[0]?.weaponHash).toBe(1001);
    expect(suggestions[0]?.perks.some((p) => p.perkHash === 200)).toBe(true);
    expect(suggestions[0]?.owned).toBe(true);
    expect(suggestions[0]?.ownedInstanceIds).toContain("inst-1");
    expect(suggestions.some((s) => !s.owned)).toBe(true);
  });

  it("boosts weapons matching weapon archetype synergies", () => {
    const context = mergeSynergyContext([
      synergyFixture({
        id: "s-arch",
        name: "Pulse Micro Missile",
        type: "weapon_archetype",
        subType: "Micro-Missile Frame",
        links: [
          {
            id: "l-arch",
            synergyId: "s-arch",
            kind: "weapon_perk",
            displayName: "Outbreak Prime",
            itemHash: null,
            perkHash: 500,
            parentItemHash: null,
            originTraitName: null,
            originTraitHash: null,
            armorSetName: null,
            bonusPieces: null,
            bonusName: null,
            armorSetHash: null,
          },
        ],
      }),
    ]);

    const suggestions = suggestRolls({
      context,
      perkIndex,
      perkNames,
      weapons: [rifle, arcRifle, microMissilePulse],
      ownedItems: [],
      limit: 3,
    });

    const outbreak = suggestions.find((s) => s.weaponHash === 1003);
    expect(outbreak?.reasons).toContain("Archetype match (Micro-Missile Frame)");
    expect(outbreak?.score).toBeGreaterThan(0);
  });

  it("boosts weapons matching weapon type archetype synergies", () => {
    const context = mergeSynergyContext([
      synergyFixture({
        id: "s-arch-type",
        name: "Pulse rifles",
        type: "weapon_archetype",
        subType: "Pulse Rifle",
      }),
    ]);

    const suggestions = suggestRolls({
      context,
      perkIndex,
      perkNames,
      weapons: [rifle, arcRifle, microMissilePulse],
      ownedItems: [],
      limit: 3,
    });

    const outbreak = suggestions.find((s) => s.weaponHash === 1003);
    expect(outbreak?.reasons).toContain("Archetype match (Pulse Rifle)");
  });
});
