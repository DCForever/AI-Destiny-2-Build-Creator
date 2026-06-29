import { describe, expect, it } from "vitest";

import {
  funnelCopyVault,
  helmetCopy,
  ringingNailCopy,
  samplePlugNameMap,
  subclassItem,
} from "./__fixtures__/inventoryFixtures";
import { armorHybridPlugMap, ringingNailHybridPlugMap } from "./__fixtures__/plugFixtures";
import { isEquipmentBucket, projectInstance } from "./projectInstance";

describe("projectInstance", () => {
  it("lists all plug hashes from sync", () => {
    const detail = projectInstance(funnelCopyVault, samplePlugNameMap);
    expect(detail.plugs).toHaveLength(3);
    expect(detail.plugs.map((p) => p.displayName)).toContain("Subsistence");
  });

  it("derives kind from bucket", () => {
    expect(projectInstance(funnelCopyVault, samplePlugNameMap).kind).toBe("weapon");
    expect(projectInstance(helmetCopy, samplePlugNameMap).kind).toBe("armor");
  });

  it("excludes non-equipment buckets", () => {
    expect(isEquipmentBucket(subclassItem.bucket)).toBe(false);
  });

  it("includes power for sorting", () => {
    expect(projectInstance(funnelCopyVault, samplePlugNameMap).power).toBe(1810);
  });

  it("enriches character labels when provided", () => {
    const labels = new Map([
      ["char-warlock", { className: "Warlock" as const, characterDisplayName: "Guardian#1" }],
    ]);
    const detail = projectInstance(
      { ...funnelCopyVault, location: "equipped", characterId: "char-warlock" },
      samplePlugNameMap,
      labels,
    );
    expect(detail.className).toBe("Warlock");
    expect(detail.characterDisplayName).toBe("Guardian#1");
  });

  it("resolves armor mod and masterwork plugs from hybrid map", () => {
    const detail = projectInstance(helmetCopy, armorHybridPlugMap);
    expect(detail.plugs.find((p) => p.hash === 6001)).toMatchObject({
      displayName: "Harmonic Resonance",
      resolved: true,
    });
    expect(detail.plugs.find((p) => p.hash === 882794621)).toMatchObject({
      displayName: "Intellect Masterwork",
      resolved: true,
    });
  });

  it("resolves Ringing Nail non-roll plugs from hybrid map", () => {
    const detail = projectInstance(ringingNailCopy, ringingNailHybridPlugMap);
    expect(detail.plugs.find((p) => p.hash === 3634656993)?.resolved).toBe(true);
    expect(detail.plugs.find((p) => p.hash === 4248210736)?.displayName).toBe("Default Shader");
  });
});
