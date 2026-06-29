import { describe, expect, it } from "vitest";

import { funnelCopyCharacter, funnelCopyVault, samplePlugNameMap } from "./__fixtures__/inventoryFixtures";
import { projectInstance } from "./projectInstance";
import { buildCharacterLabelMap } from "./resolveCharacterLabels";

describe("resolveCharacterLabels", () => {
  it("maps characterId to class and display name", () => {
    const map = buildCharacterLabelMap(
      [
        {
          characterId: "char-1",
          classType: "Warlock",
          light: 1810,
          emblemPath: null,
          dateLastPlayed: "2026-01-01",
        },
      ],
      "Guardian#0001",
    );
    expect(map.get("char-1")).toEqual({
      className: "Warlock",
      characterDisplayName: "Guardian#0001",
    });
  });

  it("omits vault items at projection time (no characterId)", () => {
    const map = buildCharacterLabelMap([], "Guardian");
    expect(map.size).toBe(0);
    const vault = projectInstance(funnelCopyVault, samplePlugNameMap, map, "Guardian");
    expect(vault.className).toBeNull();
    expect(vault.characterDisplayName).toBeNull();
  });

  it("degrades to membership display name when roster misses character", () => {
    const detail = projectInstance(funnelCopyCharacter, samplePlugNameMap, new Map(), "Guardian#0001");
    expect(detail.characterDisplayName).toBe("Guardian#0001");
    expect(detail.className).toBeNull();
  });
});
