import { describe, expect, it } from "vitest";

import {
  crownWarlockLoadout,
  hallowfireTitanLoadout,
  manifestStores,
  noExoticLoadout,
  witherLoadout,
} from "./__fixtures__/loadoutFixtures";
import { classifyLoadoutExotics } from "./classifyExotics";
import { filterLoadouts, matchesExoticFilter } from "./filterLoadouts";
import { summarizeLoadouts } from "./summarizeLoadouts";

describe("filterLoadouts armor", () => {
  const loadouts = [crownWarlockLoadout, hallowfireTitanLoadout, noExoticLoadout];
  const summaries = summarizeLoadouts(loadouts, manifestStores);

  it("filters exact armor by hash", () => {
    const result = filterLoadouts(
      loadouts,
      { armor: { mode: "exact", hash: 2001 } },
      summaries,
    );
    expect(result.map((l) => l.id)).toEqual(["crown"]);
  });

  it("filters exact armor by name when hash missing", () => {
    const result = filterLoadouts(
      [noExoticLoadout],
      { armor: { mode: "exact", name: "Hallowfire Heart" } },
      summarizeLoadouts([noExoticLoadout], manifestStores),
    );
    expect(result).toHaveLength(1);
  });

  it("filters armor slot with class match", () => {
    const result = filterLoadouts(
      loadouts,
      { armor: { mode: "slot", slot: "Helmet" } },
      summaries,
    );
    expect(result.map((l) => l.id)).toEqual(["crown"]);
  });

  it("excludes cross-class helmet matches", () => {
    const titanHelmet = {
      ...hallowfireTitanLoadout,
      id: "titan-helm",
      resolvedSheet: {
        ...hallowfireTitanLoadout.resolvedSheet,
        exoticArmor: {
          ...crownWarlockLoadout.resolvedSheet.exoticArmor,
        },
      },
    };
    const sums = summarizeLoadouts([titanHelmet], manifestStores);
    const result = filterLoadouts(
      [titanHelmet],
      { armor: { mode: "slot", slot: "Helmet" } },
      sums,
    );
    expect(result).toHaveLength(0);
  });

  it("excludes loadouts without exotic armor", () => {
    const bare = {
      ...noExoticLoadout,
      resolvedSheet: {
        ...noExoticLoadout.resolvedSheet,
        exoticArmor: {
          requestedName: "",
          resolved: null,
          confidence: 0,
          status: "unresolved" as const,
          alternatives: [],
        },
      },
    };
    const result = filterLoadouts(
      [bare],
      { armor: { mode: "slot", slot: "Helmet" } },
      summarizeLoadouts([bare], manifestStores),
    );
    expect(result).toHaveLength(0);
  });
});

describe("filterLoadouts weapon and AND", () => {
  const loadouts = [crownWarlockLoadout, witherLoadout];
  const summaries = summarizeLoadouts(loadouts, manifestStores);

  it("filters exact weapon by hash", () => {
    const result = filterLoadouts(
      loadouts,
      { weapon: { mode: "exact", hash: 9001 } },
      summaries,
    );
    expect(result.map((l) => l.id)).toEqual(["wither"]);
  });

  it("filters weapon slot", () => {
    const result = filterLoadouts(
      loadouts,
      { weapon: { mode: "slot", slot: "Kinetic" } },
      summaries,
    );
    expect(result.map((l) => l.id)).toEqual(["wither"]);
  });

  it("excludes loadouts without exotic weapon", () => {
    expect(
      matchesExoticFilter(classifyLoadoutExotics(crownWarlockLoadout, manifestStores), {
        weapon: { mode: "slot", slot: "Kinetic" },
      }),
    ).toBe(false);
  });

  it("applies AND when armor and weapon set", () => {
    const combo = {
      ...witherLoadout,
      id: "combo",
      buildRequest: {
        className: "Warlock" as const,
        activity: "Patrol",
        subclass: "Stormcaller",
        playstyle: "PvE",
      },
      resolvedSheet: {
        ...witherLoadout.resolvedSheet,
        exoticArmor: crownWarlockLoadout.resolvedSheet.exoticArmor,
      },
    };
    const all = [combo, crownWarlockLoadout, witherLoadout];
    const sums = summarizeLoadouts(all, manifestStores);
    const result = filterLoadouts(
      all,
      {
        armor: { mode: "exact", hash: 2001 },
        weapon: { mode: "exact", hash: 9001 },
      },
      sums,
    );
    expect(result.map((l) => l.id)).toEqual(["combo"]);
  });
});
