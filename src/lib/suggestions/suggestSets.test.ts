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
      createdAt: "",
      updatedAt: "",
    },
    {
      id: "s2",
      userId: 1,
      name: "Arc Only",
      type: "weapon",
      tagIds: ["arc"],
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
        tagIds: ["solar", "melee"],
        synergyIds: [],
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
        tagIds: [],
        synergyIds: [],
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
});
