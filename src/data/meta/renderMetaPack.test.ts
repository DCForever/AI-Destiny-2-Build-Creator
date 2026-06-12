import { describe, expect, it } from "vitest";

import { renderMetaPack } from "./renderMetaPack";

describe("renderMetaPack", () => {
  it("includes only the requested class's builds and exotics", () => {
    const pack = renderMetaPack("Warlock", "Grandmaster Nightfall");
    expect(pack).toContain("Soul Siphon Attrition");
    expect(pack).toContain("Nezarec's Sin");
    expect(pack).not.toContain("Hallowfire Heart");
    expect(pack).not.toContain("Crackshot Duelist");
  });

  it("includes all seven artifacts for PvE activities", () => {
    const pack = renderMetaPack("Titan", "Grandmaster Nightfall");
    for (const artifact of [
      "Queensfoil Censer",
      "Slayer Baron Apothecary Satchel",
      "Hunters Journal",
      "Tablet of Ruin",
      "Implement of Curiosity",
      "Encrypted Data Disc",
      "NPA Repulsion Regulator",
    ]) {
      expect(pack).toContain(artifact);
    }
  });

  it("replaces artifact guidance with a disabled note in Trials", () => {
    const pack = renderMetaPack("Hunter", "Trials of Osiris");
    expect(pack).toContain("artifact section must be null");
    expect(pack).not.toContain("Queensfoil Censer");
  });

  it("always carries weapon notes, set bonuses, and stat guidance", () => {
    const pack = renderMetaPack("Hunter", "Raid");
    expect(pack).toContain("The Lament");
    expect(pack).toContain("Shattered Throne");
    expect(pack).toContain("Stat target guidance");
  });
});
