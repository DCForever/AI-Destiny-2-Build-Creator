import { describe, expect, it } from "vitest";

import {
  emptyLookupMessage,
  mapExoticSelection,
  setIdentityFields,
  synergyIdentityFields,
  variantIdentityFields,
} from "./lookupParity";

describe("lookupParity", () => {
  it("returns clear empty-state copy per lookup kind", () => {
    expect(emptyLookupMessage("exotic_armor")).toContain("exotic armor");
    expect(emptyLookupMessage("exotic_weapon")).toContain("exotic weapon");
    expect(emptyLookupMessage("set")).toContain("sets");
    expect(emptyLookupMessage("synergy")).toContain("synergies");
    expect(emptyLookupMessage("variant")).toContain("variants");
  });

  it("maps exotic selections to persisted identity fields", () => {
    expect(mapExoticSelection({ hash: 123, name: "Celestial Nighthawk" })).toEqual({
      hash: 123,
      name: "Celestial Nighthawk",
    });
    expect(mapExoticSelection({ hash: 456, name: "Thunderlord" })).toEqual({
      hash: 456,
      name: "Thunderlord",
    });
  });

  it("returns synergy identity fields", () => {
    expect(
      synergyIdentityFields({
        id: "syn-1",
        name: "Ignition Loop",
        type: "damage_loop",
      }),
    ).toEqual({
      id: "syn-1",
      name: "Ignition Loop",
      type: "damage_loop",
    });
  });

  it("returns set identity fields", () => {
    expect(
      setIdentityFields({
        id: "set-1",
        name: "Solar Weapons",
        type: "weapon",
      }),
    ).toEqual({
      id: "set-1",
      name: "Solar Weapons",
      type: "weapon",
    });
  });

  it("returns variant identity fields with explicit default state", () => {
    expect(variantIdentityFields({ id: "var-1", name: "Default", isDefault: true })).toEqual({
      id: "var-1",
      name: "Default",
      isDefault: true,
    });
    expect(variantIdentityFields({ id: "var-2", name: "Alt" })).toEqual({
      id: "var-2",
      name: "Alt",
      isDefault: false,
    });
  });

  it("preserves required identity fields for picker parity", () => {
    expect(Object.keys(synergyIdentityFields({ id: "syn-2", name: "Loop", type: "verb" }))).toEqual([
      "id",
      "name",
      "type",
    ]);
    expect(Object.keys(setIdentityFields({ id: "set-2", name: "Armor", type: "armor" }))).toEqual([
      "id",
      "name",
      "type",
    ]);
    expect(Object.keys(variantIdentityFields({ id: "var-3", name: "Boss" }))).toEqual([
      "id",
      "name",
      "isDefault",
    ]);
  });
});
