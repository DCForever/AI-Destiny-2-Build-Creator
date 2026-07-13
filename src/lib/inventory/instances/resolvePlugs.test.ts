import { describe, expect, it } from "vitest";

import { ringingNailManifestPlugs, ringingNailRollPlugs } from "./__fixtures__/plugFixtures";
import { buildPlugNameMap, mergeManifestPlugNames, resolvePlugs } from "./resolvePlugs";

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
      {
        hash: 1001,
        name: "Subsistence",
        displayName: "Subsistence",
        resolved: true,
        icon: null,
        description: "",
      },
      {
        hash: 5001,
        name: "Solar Mod",
        displayName: "Solar Mod",
        resolved: true,
        icon: null,
        description: "",
      },
    ]);
  });

  it("degrades unresolved hashes to string displayName", () => {
    const plugs = resolvePlugs([9999999999], buildPlugNameMap(stores));
    expect(plugs[0]).toEqual({
      hash: 9999999999,
      name: null,
      displayName: "9999999999",
      resolved: false,
      icon: null,
      description: "",
    });
  });

  it("mergeManifestPlugNames fills entity gaps without overwriting entity names", () => {
    const entityMap = buildPlugNameMap(stores);
    const manifestMap = new Map<number, string>([
      [1636108362, "Precision Frame"],
      [3634656993, "Synergy"],
      [1001, "Wrong Override"],
    ]);
    const hybrid = mergeManifestPlugNames(entityMap, manifestMap);
    expect(hybrid.get(1001)).toBe("Subsistence");
    expect(hybrid.get(1636108362)).toBe("Precision Frame");
    expect(hybrid.get(3634656993)).toBe("Synergy");
  });

  it("resolves Ringing Nail fixture hashes with hybrid map", () => {
    const entityMap = buildPlugNameMap({
      "weapon-perks": Object.entries(ringingNailRollPlugs).map(([hash, name]) => ({
        hash: Number(hash),
        name,
      })),
    });
    const manifestMap = new Map(
      Object.entries(ringingNailManifestPlugs).map(([hash, name]) => [Number(hash), name]),
    );
    const hybrid = mergeManifestPlugNames(entityMap, manifestMap);
    const plugs = resolvePlugs(
      [...Object.keys(ringingNailManifestPlugs), ...Object.keys(ringingNailRollPlugs)].map(Number),
      hybrid,
    );
    expect(plugs.every((plug) => plug.resolved)).toBe(true);
    expect(plugs.find((p) => p.hash === 3634656993)?.displayName).toBe("Synergy");
    expect(plugs.find((p) => p.hash === 1636108362)?.displayName).toBe("Precision Frame");
  });

  it("hybrid map leaves unknown manifest hashes unresolved", () => {
    const hybrid = mergeManifestPlugNames(new Map(), new Map());
    const plugs = resolvePlugs([9999999999], hybrid);
    expect(plugs[0]?.resolved).toBe(false);
  });
});
