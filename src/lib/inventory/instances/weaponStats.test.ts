import { describe, expect, it } from "vitest";

import { parseWeaponStatValues, weaponStatLines } from "./weaponStats";

describe("weaponStats", () => {
  it("maps known Bungie hashes to display names", () => {
    const values = parseWeaponStatValues([
      { statHash: 4284893193, value: 260 },
      { statHash: 4043523819, value: 45 },
      { statHash: 155624089, value: 49 },
      { statHash: 3871231066, value: 19 },
    ]);
    expect(values).toEqual({
      RPM: 260,
      Impact: 45,
      Stability: 49,
      Magazine: 19,
    });
  });

  it("orders lines for DIM-style bars", () => {
    const lines = weaponStatLines({
      Magazine: 19,
      RPM: 260,
      Stability: 49,
      Impact: 45,
    });
    expect(lines.map((l) => l.name)).toEqual([
      "RPM",
      "Impact",
      "Stability",
      "Magazine",
    ]);
    expect(lines[0]?.ratio).toBeCloseTo(0.26);
  });

  it("returns null for empty input", () => {
    expect(parseWeaponStatValues([])).toBeNull();
    expect(parseWeaponStatValues(undefined)).toBeNull();
  });
});
