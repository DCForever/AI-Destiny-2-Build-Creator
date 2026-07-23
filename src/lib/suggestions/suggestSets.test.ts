import { describe, expect, it } from "vitest";

import { buildAutomaticSuggestionContext, suggestSets } from "./suggestSets";
import type { SetRecord } from "@/lib/db/repositories/setRepository";

describe("suggestSets", () => {
  const sets: SetRecord[] = [
    {
      id: "s1",
      userId: 1,
      name: "Solar Melee",
      type: "weapon",
      tagIds: ["solar", "melee"],
      optimizerConstraints: null,
      linkedModSetId: null,
      createdAt: "",
      updatedAt: "",
    },
    {
      id: "s2",
      userId: 1,
      name: "Arc Only",
      type: "weapon",
      tagIds: ["arc"],
      optimizerConstraints: null,
      linkedModSetId: null,
      createdAt: "",
      updatedAt: "",
    },
  ];

  it("suggests sets matching build tags and subclass element", () => {
    const ctx = buildAutomaticSuggestionContext(
      {
        id: "b1",
        userId: 1,
        name: "Build",
        className: "Titan",
        subclass: { name: "Sunbreaker" },
        exoticArmorHash: 1,
        exoticArmorName: "X",
        exoticWeaponHash: null,
        exoticWeaponName: null,
        pinnedSuper: null,
        softStatTargets: {},
        tagIds: ["solar", "melee"],
        synergyTypes: [],
        createdAt: "",
        updatedAt: "",
      },
      { exoticWeaponHash: null },
      [],
    );

    const results = suggestSets(sets, ctx);
    expect(results[0]?.setId).toBe("s1");
    expect(results[0]?.score).toBeGreaterThan(0);
  });

  it("includes explicit goal in scoring", () => {
    const ctx = buildAutomaticSuggestionContext(
      {
        id: "b1",
        userId: 1,
        name: "Build",
        className: "Titan",
        subclass: { name: "Striker" },
        exoticArmorHash: 1,
        exoticArmorName: "X",
        exoticWeaponHash: null,
        exoticWeaponName: null,
        pinnedSuper: null,
        softStatTargets: {},
        tagIds: [],
        synergyTypes: [],
        createdAt: "",
        updatedAt: "",
      },
      { exoticWeaponHash: null },
      [],
    );
    ctx.goal = "arc";

    const results = suggestSets(sets, ctx);
    expect(results.some((r) => r.setId === "s2")).toBe(true);
  });

  it("ranks gap-closing sets above peers that do not close gaps", () => {
    const gapSets: SetRecord[] = [
      {
        id: "gap-close",
        userId: 1,
        name: "Has Missing Gun",
        type: "weapon",
        tagIds: ["solar"],
        optimizerConstraints: null,
        linkedModSetId: null,
        createdAt: "",
        updatedAt: "",
      },
      {
        id: "gap-miss",
        userId: 1,
        name: "Other Solar",
        type: "weapon",
        tagIds: ["solar"],
        optimizerConstraints: null,
        linkedModSetId: null,
        createdAt: "",
        updatedAt: "",
      },
      {
        id: "fashion",
        userId: 1,
        name: "Looks",
        type: "fashion",
        tagIds: ["solar"],
        optimizerConstraints: null,
        linkedModSetId: null,
        createdAt: "",
        updatedAt: "",
      },
    ];
    const ctx = buildAutomaticSuggestionContext(
      {
        id: "b1",
        userId: 1,
        name: "Build",
        className: "Warlock",
        subclass: { name: "Dawnblade", element: "Solar" },
        exoticArmorHash: 1,
        exoticArmorName: "X",
        exoticWeaponHash: null,
        exoticWeaponName: null,
        pinnedSuper: null,
        softStatTargets: {},
        tagIds: ["solar"],
        synergyTypes: [],
        createdAt: "",
        updatedAt: "",
      },
      { exoticWeaponHash: null },
      [],
    );
    ctx.coverageGaps = [{ synergyName: "Trace", itemHashes: [4242], perkHashes: [] }];
    ctx.setItemHashesBySetId = {
      "gap-close": [4242],
      "gap-miss": [999],
      fashion: [4242],
    };

    const results = suggestSets(gapSets, ctx);
    expect(results[0]?.setId).toBe("gap-close");
    expect(results[0]?.reasons.some((r) => r.includes("Closes gap"))).toBe(true);
    const fashionResult = results.find((r) => r.setId === "fashion");
    expect(fashionResult?.reasons.some((r) => r.includes("Closes gap")) ?? false).toBe(false);
  });
});
