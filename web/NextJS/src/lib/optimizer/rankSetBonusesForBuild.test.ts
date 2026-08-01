import { describe, expect, it } from "vitest";

import { goalsFromRankedOptions, rankSetBonusesForBuild } from "./rankSetBonusesForBuild";

describe("rankSetBonusesForBuild", () => {
  const catalog = [
    { setBonusKey: "two-piece", label: "Two-Piece", armorSetName: "Two-Piece" },
    { setBonusKey: "lucerne", label: "Terminal Lucerne", armorSetHash: 111, armorSetName: "Terminal Lucerne" },
    { setBonusKey: "hunters", label: "Hunter's Instinct", armorSetName: "Hunter's Instinct" },
    { setBonusKey: "pyro", label: "Pyrogale line", armorSetName: "Pyrogale" },
  ];

  it("puts synergy-linked bonuses in linked group first", () => {
    const result = rankSetBonusesForBuild({
      matchedSynergies: [
        {
          name: "Melee Devour",
          links: [
            {
              kind: "armor_set_bonus",
              displayName: "Two-Piece 2",
              armorSetName: "Two-Piece",
              bonusPieces: 2,
              bonusName: "Two-Piece",
            },
          ],
        },
        {
          name: "Grenade Weaken",
          links: [
            {
              kind: "armor_set_bonus",
              displayName: "Lucerne",
              armorSetHash: 111,
              armorSetName: "Terminal Lucerne",
              bonusPieces: 2,
            },
          ],
        },
      ],
      catalog,
    });

    expect(result.linked.map((l) => l.setBonusKey).sort()).toEqual(["lucerne", "two-piece"].sort());
    expect(result.linked.every((l) => l.linked)).toBe(true);
    expect(result.linked.find((l) => l.setBonusKey === "two-piece")?.synergyNames).toContain("Melee Devour");
    const allKeysOrder = result.all.map((a) => a.setBonusKey);
    const firstUnlinked = allKeysOrder.findIndex((k) => k === "hunters" || k === "pyro");
    const lastLinkedIdx = Math.max(allKeysOrder.indexOf("two-piece"), allKeysOrder.indexOf("lucerne"));
    expect(lastLinkedIdx).toBeLessThan(firstUnlinked === -1 ? 99 : firstUnlinked);
    expect(result.all.filter((a) => !a.linked).map((a) => a.setBonusKey).sort()).toEqual(
      ["hunters", "pyro"].sort(),
    );
  });

  it("returns empty linked when no armor_set_bonus links", () => {
    const result = rankSetBonusesForBuild({
      matchedSynergies: [{ name: "Only weapon", links: [{ kind: "weapon", displayName: "Gun", itemHash: 1 }] }],
      catalog,
    });
    expect(result.linked).toEqual([]);
    expect(result.all).toHaveLength(4);
  });

  it("goalsFromRankedOptions dedupes last-wins", () => {
    const goals = goalsFromRankedOptions([
      { setBonusKey: "a", minPieces: 2 },
      { setBonusKey: "a", minPieces: 4 },
    ]);
    expect(goals).toEqual([{ setBonusKey: "a", minPieces: 4 }]);
  });
});
