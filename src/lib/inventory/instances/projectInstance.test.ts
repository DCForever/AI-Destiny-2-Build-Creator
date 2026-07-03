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

  it("adds armor tier from gearTier and set bonus from projection context", () => {
    const armor = {
      ...helmetCopy,
      gearTier: 5,
      statValues: { Health: 12, Melee: 10, Grenade: 10, Super: 10, Class: 10, Weapons: 11 },
    };
    const meta = new Map([
      [
        armor.itemHash,
        {
          isExotic: false,
          setBonus: {
            hash: 1,
            name: "Deep Stone Crypt",
            tiers: [
              { requiredCount: 2, name: "Scanner", description: "d2" },
              { requiredCount: 4, name: "Reaper", description: "d4" },
            ],
          },
        },
      ],
    ]);
    const detail = projectInstance(armor, armorHybridPlugMap, undefined, undefined, meta);
    expect(detail.tier).toMatchObject({ tier: 5, source: "api", available: true });
    expect(detail.setBonus?.name).toBe("Deep Stone Crypt");
    expect(detail.setBonus?.tiers.map((t) => t.requiredCount)).toEqual([2, 4]);
  });

  it("omits tier and setBonus for weapons and lists every equipped socket", () => {
    const detail = projectInstance(ringingNailCopy, ringingNailHybridPlugMap);
    expect(detail.tier).toBeUndefined();
    expect(detail.setBonus).toBeUndefined();
    expect(detail.plugs).toHaveLength(ringingNailCopy.plugHashes.length);
  });
});
