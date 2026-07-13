import { describe, expect, it } from "vitest";

import {
  collectCoveredKeys,
  coverageKeyFromLink,
  linkInputFromCoverageCandidate,
} from "./coverageKeys";

describe("coverageKeyFromLink", () => {
  it("keys weapons by item hash", () => {
    expect(coverageKeyFromLink({ kind: "weapon", itemHash: 42 })).toBe(
      "weapon:42",
    );
  });

  it("keys armor set bonuses by set + pieces + bonus name", () => {
    expect(
      coverageKeyFromLink({
        kind: "armor_set_bonus",
        armorSetName: "Solstice",
        bonusPieces: 4,
        bonusName: "Solar Siphon",
      }),
    ).toBe("armor_set_bonus:solstice:4:solar siphon");
  });

  it("prefers origin trait hash over name", () => {
    expect(
      coverageKeyFromLink({
        kind: "origin_trait",
        originTraitHash: 9,
        originTraitName: "Wild Card",
      }),
    ).toBe("origin_trait:hash:9");
  });
});

describe("collectCoveredKeys", () => {
  it("unions keys from all synergy links", () => {
    const keys = collectCoveredKeys([
      {
        links: [
          { kind: "weapon", itemHash: 1 },
          { kind: "weapon_perk", perkHash: 2 },
        ],
      },
      { links: [{ kind: "weapon", itemHash: 1 }] },
    ]);
    expect([...keys].sort()).toEqual(["weapon:1", "weapon_perk:2"]);
  });
});

describe("linkInputFromCoverageCandidate", () => {
  it("builds a weapon link payload", () => {
    expect(
      linkInputFromCoverageCandidate({
        kind: "weapon",
        displayName: "Sunshot",
        itemHash: 123,
      }),
    ).toEqual({
      kind: "weapon",
      displayName: "Sunshot",
      itemHash: 123,
    });
  });
});
