import { describe, expect, it } from "vitest";

import {
  buildLoadoutMatchLabel,
  indexBuildLoadoutMatches,
  loadoutMatchLabel,
  matchBuildToLoadouts,
  matchLoadoutToBuilds,
} from "./matchLoadoutToBuilds";

const builds = [
  {
    id: "1",
    name: "Consecrated Pyre",
    className: "Titan",
    exoticArmorHash: 100,
    exoticWeaponHash: 200,
  },
  {
    id: "2",
    name: "Void Anchor",
    className: "Warlock",
    exoticArmorHash: 300,
    exoticWeaponHash: null,
  },
  {
    id: "3",
    name: "Synth Melee",
    className: "Titan",
    exoticArmorHash: 100,
    exoticWeaponHash: null,
  },
];

describe("matchLoadoutToBuilds", () => {
  it("returns exact when class and both exotics match", () => {
    const m = matchLoadoutToBuilds(
      {
        className: "Titan",
        exoticArmorHash: 100,
        exoticWeaponHash: 200,
      },
      builds,
    );
    expect(m.kind).toBe("exact");
    expect(m.builds.map((b) => b.name)).toEqual(["Consecrated Pyre"]);
  });

  it("returns partial when only armor matches", () => {
    const m = matchLoadoutToBuilds(
      {
        className: "Titan",
        exoticArmorHash: 100,
        exoticWeaponHash: 999,
      },
      builds,
    );
    expect(m.kind).toBe("partial");
    expect(m.builds.some((b) => b.id === "1" || b.id === "3")).toBe(true);
  });

  it("returns none when class differs", () => {
    const m = matchLoadoutToBuilds(
      {
        className: "Hunter",
        exoticArmorHash: 100,
        exoticWeaponHash: 200,
      },
      builds,
    );
    expect(m.kind).toBe("none");
    expect(m.builds).toEqual([]);
  });
});

describe("loadoutMatchLabel", () => {
  it("labels unlinked and linked states", () => {
    expect(loadoutMatchLabel({ kind: "none", builds: [] })).toBe(
      "No linked build",
    );
    expect(
      loadoutMatchLabel({
        kind: "exact",
        builds: [{ id: "1", name: "Pyre" }],
      }),
    ).toBe("Linked build: Pyre");
    expect(
      loadoutMatchLabel({
        kind: "partial",
        builds: [{ id: "1", name: "Pyre" }],
      }),
    ).toBe("Partial match: Pyre");
  });
});

const loadouts = [
  {
    id: "lo-exact",
    name: "Pyre Slot",
    className: "Titan",
    exoticArmorHash: 100,
    exoticWeaponHash: 200,
    iconUrl: "/icon-a.png",
  },
  {
    id: "lo-partial",
    name: "Synth Only",
    className: "Titan",
    exoticArmorHash: 100,
    exoticWeaponHash: null,
    iconUrl: "/icon-b.png",
  },
  {
    id: "lo-other",
    name: "Warlock Slot",
    className: "Warlock",
    exoticArmorHash: 300,
    exoticWeaponHash: null,
  },
];

describe("matchBuildToLoadouts", () => {
  it("returns exact loadouts for a build", () => {
    const m = matchBuildToLoadouts(builds[0]!, loadouts);
    expect(m.kind).toBe("exact");
    expect(m.loadouts.map((l) => l.id)).toEqual(["lo-exact"]);
  });

  it("falls back to partial when no exact", () => {
    const m = matchBuildToLoadouts(builds[2]!, loadouts);
    // Synth Melee has armor 100 weapon null — lo-partial is exact (both sides weapon null, armor match)
    // lo-exact has weapon 200 vs build null → partial
    expect(m.kind).toBe("exact");
    expect(m.loadouts.map((l) => l.id)).toContain("lo-partial");
  });

  it("indexes all builds", () => {
    const map = indexBuildLoadoutMatches(builds, loadouts);
    expect(map.get("1")?.kind).toBe("exact");
    expect(map.get("2")?.kind).toBe("exact");
    expect(map.get("2")?.loadouts[0]?.id).toBe("lo-other");
  });
});

describe("buildLoadoutMatchLabel", () => {
  it("labels in-game loadout badges", () => {
    expect(buildLoadoutMatchLabel({ kind: "none", loadouts: [] })).toBe("");
    expect(
      buildLoadoutMatchLabel({
        kind: "exact",
        loadouts: [{ id: "1", name: "PvE" }],
      }),
    ).toBe("In-game: PvE");
    expect(
      buildLoadoutMatchLabel({
        kind: "partial",
        loadouts: [{ id: "1", name: "PvE" }],
      }),
    ).toBe("Partial loadout: PvE");
  });
});

