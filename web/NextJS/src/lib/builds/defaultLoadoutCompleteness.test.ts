import { describe, expect, it } from "vitest";

import {
  collectArtifactCompleteGaps,
  collectSubclassKitCompleteGaps,
} from "@/lib/builds/defaultLoadoutCompleteness";
import { assertFullCombatLoadout } from "@/lib/builds/resolveVariant";
import { API_ERROR_CODES } from "@/lib/api/errors";
import type { BuildRecord } from "@/lib/db/repositories/buildRepository";

const fullEquipment = {
  primary: {} as never,
  special: {} as never,
  heavy: {} as never,
  helmet: {} as never,
  arms: {} as never,
  chest: {} as never,
  legs: {} as never,
  class_item: {} as never,
};

const completeKit = {
  name: "Sunbreaker",
  super: "Hammer of Sol",
  melee: "Hammer Strike",
  grenade: "Thermite Grenade",
  aspects: ["Roaring Flames", "Consecration"],
  fragments: ["Ember of Ashes", "Ember of Beams", "Ember of Char", "Ember of Combustion"],
};

describe("collectSubclassKitCompleteGaps", () => {
  it("requires super, melee, grenade, and full aspects", () => {
    const gaps = collectSubclassKitCompleteGaps(
      { name: "Sunbreaker", super: "", melee: "", grenade: "", aspects: [], fragments: [] },
      { fragmentCapacity: 0, capacityResolved: true },
    );
    expect(gaps).toEqual(
      expect.arrayContaining(["super", "melee", "grenade", "aspects"]),
    );
  });

  it("requires fragments at capacity when capacity known", () => {
    const gaps = collectSubclassKitCompleteGaps(completeKit, {
      fragmentCapacity: 4,
      capacityResolved: true,
    });
    expect(gaps).toEqual([]);

    const short = collectSubclassKitCompleteGaps(
      { ...completeKit, fragments: ["Ember of Ashes"] },
      { fragmentCapacity: 4, capacityResolved: true },
    );
    expect(short).toContain("fragments");
  });

  it("does not require class ability or movement", () => {
    const gaps = collectSubclassKitCompleteGaps(
      { ...completeKit, classAbility: "", movement: "" },
      { fragmentCapacity: 4, capacityResolved: true },
    );
    expect(gaps).toEqual([]);
  });
});

describe("collectArtifactCompleteGaps", () => {
  it("requires artifact hash and non-empty config", () => {
    expect(collectArtifactCompleteGaps({})).toContain("artifact");
    expect(
      collectArtifactCompleteGaps({ artifactHash: 1, artifactConfig: [] }),
    ).toContain("artifactConfig");
    expect(
      collectArtifactCompleteGaps({ artifactHash: 1, artifactConfig: [99] }),
    ).toEqual([]);
  });
});

describe("assertFullCombatLoadout kit + artifact", () => {
  it("fails when kit/artifact missing even with full gear", () => {
    const build = {
      className: "Titan",
      subclass: { name: "Sunbreaker", super: "", aspects: [], fragments: [] },
    } as BuildRecord;
    expect(() =>
      assertFullCombatLoadout(
        { equipment: fullEquipment, conflicts: [] },
        build,
        { hasMods: true },
      ),
    ).toThrow(
      expect.objectContaining({ code: API_ERROR_CODES.DEFAULT_VARIANT_INCOMPLETE }),
    );
  });

  it("passes when gear, kit, and artifact are complete", () => {
    const build = {
      className: "Titan",
      subclass: completeKit,
    } as BuildRecord;
    expect(() =>
      assertFullCombatLoadout(
        { equipment: fullEquipment, conflicts: [] },
        build,
        {
          hasMods: true,
          fragmentCapacity: 4,
          capacityResolved: true,
          artifactHash: 42,
          artifactConfig: [1, 2],
        },
      ),
    ).not.toThrow();
  });

  it("can skip kit/artifact for equipment-only unit checks", () => {
    const build = {
      className: "Titan",
      subclass: { name: "Sunbreaker" },
    } as BuildRecord;
    expect(() =>
      assertFullCombatLoadout(
        { equipment: fullEquipment, conflicts: [] },
        build,
        { hasMods: true, requireKitAndArtifact: false },
      ),
    ).not.toThrow();
  });
});
