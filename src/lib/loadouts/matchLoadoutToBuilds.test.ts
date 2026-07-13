import { describe, expect, it } from "vitest";

import {
  loadoutMatchLabel,
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
