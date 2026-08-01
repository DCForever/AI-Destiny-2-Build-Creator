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

  it("keys exotic armor by item hash", () => {
    expect(coverageKeyFromLink({ kind: "exotic_armor", itemHash: 55 })).toBe(
      "exotic_armor:55",
    );
  });

  it("keys class-item exotic_armor perk config", () => {
    expect(
      coverageKeyFromLink({ kind: "exotic_armor", perkHash: 900 }),
    ).toBe("exotic_armor:perk:900");
    expect(
      coverageKeyFromLink({ kind: "exotic_armor", itemHash: 77, perkHash: 900 }),
    ).toBe("exotic_armor:77:perk:900");
  });

  it("keys artifact perks by perk hash", () => {
    expect(coverageKeyFromLink({ kind: "artifact_perk", perkHash: 77 })).toBe(
      "artifact_perk:77",
    );
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
