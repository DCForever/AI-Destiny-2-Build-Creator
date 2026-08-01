import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { join } from "node:path";

import {
  applySlotModHashes,
  attachmentsWithSlotMods,
  configsFromSetItems,
  isArmorModSlot,
  toggleSlotModHash,
} from "./variantMods";

const baseConfigs = [
  {
    slot: "helmet",
    itemHash: 10,
    itemName: "Helm",
    modHashes: [101] as number[],
  },
  {
    slot: "arms",
    itemHash: 20,
    itemName: "Gaunts",
    modHashes: [] as number[],
  },
];

describe("variantMods", () => {
  it("applies slot modHashes without mutating other slots", () => {
    const next = applySlotModHashes(baseConfigs, "helmet", [201, 202, 201]);
    expect(next.find((c) => c.slot === "helmet")?.modHashes).toEqual([201, 202]);
    expect(next.find((c) => c.slot === "arms")?.modHashes).toEqual([]);
    expect(baseConfigs[0]?.modHashes).toEqual([101]);
  });

  it("throws when slot is missing", () => {
    expect(() => applySlotModHashes(baseConfigs, "chest", [1])).toThrow(/chest/);
  });

  it("toggles mod hash on and off", () => {
    const on = toggleSlotModHash(baseConfigs, "arms", 55);
    expect(on.find((c) => c.slot === "arms")?.modHashes).toEqual([55]);
    const off = toggleSlotModHash(on, "arms", 55);
    expect(off.find((c) => c.slot === "arms")?.modHashes).toEqual([]);
  });

  it("attachmentsWithSlotMods forces snapshot and preserves others", () => {
    const current = [
      { setId: "armor-a", mode: "live" as const },
      { setId: "weapon-b", mode: "live" as const },
    ];
    const configs = applySlotModHashes(baseConfigs, "helmet", [9]);
    const patch = attachmentsWithSlotMods(current, "armor-a", configs);
    expect(patch).toEqual([
      {
        setId: "armor-a",
        mode: "snapshot",
        snapshotConfigs: configs,
      },
      { setId: "weapon-b", mode: "live", snapshotConfigs: undefined },
    ]);
  });

  it("configsFromSetItems maps active items only", () => {
    const configs = configsFromSetItems([
      {
        slot: "helmet",
        itemHash: 1,
        itemName: "H",
        modHashes: [3],
        selectedPerks: [1],
        removedAt: null,
      },
      {
        slot: "arms",
        itemHash: 2,
        itemName: "A",
        modHashes: null,
        removedAt: "2020-01-01",
      },
    ]);
    expect(configs).toHaveLength(1);
    expect(configs[0]).toMatchObject({
      slot: "helmet",
      itemHash: 1,
      modHashes: [3],
    });
  });

  it("recognizes armor mod slots", () => {
    expect(isArmorModSlot("helmet")).toBe(true);
    expect(isArmorModSlot("primary")).toBe(false);
  });

  it("Mods tab is no longer a Sets-only stub", () => {
    const src = readFileSync(
      join(process.cwd(), "src/components/build/VariantEditPanel.tsx"),
      "utf8",
    );
    expect(src).toMatch(/attachmentsWithSlotMods|applySlotModHashes|slot-level/i);
    expect(src).not.toMatch(
      /Armor mods live on set instances and resolve through attached sets\.\s*Edit mod rolls on the Sets screen/,
    );
  });
});
