import { describe, expect, it } from "vitest";

import { buildPlugNameMap, resolvePlugs } from "./resolvePlugs";

describe("resolvePlugs", () => {
  const stores = {
    "weapon-perks": [{ hash: 1001, name: "Subsistence", searchName: "subsistence" }],
    mods: [{ hash: 5001, name: "Solar Mod", searchName: "solar mod" }],
    "origin-traits": [{ hash: 3001, name: "Arrowhead Brake", searchName: "arrowhead brake" }],
  };

  it("buildPlugNameMap merges weapon-perks, mods, and origin-traits", () => {
    const map = buildPlugNameMap(stores);
    expect(map.get(1001)).toBe("Subsistence");
    expect(map.get(5001)).toBe("Solar Mod");
    expect(map.get(3001)).toBe("Arrowhead Brake");
  });

  it("resolves known hashes to display names", () => {
    const plugs = resolvePlugs([1001, 5001], buildPlugNameMap(stores));
    expect(plugs).toEqual([
      { hash: 1001, name: "Subsistence", displayName: "Subsistence", resolved: true },
      { hash: 5001, name: "Solar Mod", displayName: "Solar Mod", resolved: true },
    ]);
  });

  it("degrades unresolved hashes to string displayName", () => {
    const plugs = resolvePlugs([9999999999], buildPlugNameMap(stores));
    expect(plugs[0]).toEqual({
      hash: 9999999999,
      name: null,
      displayName: "9999999999",
      resolved: false,
    });
  });
});
