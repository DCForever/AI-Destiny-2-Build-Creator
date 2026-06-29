import { describe, expect, it } from "vitest";

import {
  funnelCopyCharacter,
  funnelCopyVault,
  helmetCopy,
  subclassItem,
} from "./__fixtures__/inventoryFixtures";
import {
  filterInventoryItems,
  filterProjectedByPerkQuery,
  kindFromQuery,
} from "./filterInstances";
import { projectInstance } from "./projectInstance";
import { samplePlugNameMap } from "./__fixtures__/inventoryFixtures";

describe("filterInstances", () => {
  const items = [funnelCopyVault, funnelCopyCharacter, helmetCopy, subclassItem];

  it("filters by itemHash", () => {
    const result = filterInventoryItems(items, { itemHash: 1363886209 });
    expect(result.map((i) => i.instanceId)).toEqual(["inst-vault-1", "inst-char-1"]);
  });

  it("matches reissue inventory hashes by catalog search name", () => {
    const result = filterInventoryItems(
      items,
      { itemHash: 93253474 },
      {
        itemSearchName: "the ringing nail",
        inventorySearchNames: new Map([[1363886209, "the ringing nail"]]),
      },
    );
    expect(result.map((i) => i.instanceId)).toEqual(["inst-vault-1", "inst-char-1"]);
  });

  it("filters by kind weapons", () => {
    const result = filterInventoryItems(items, { kind: "weapon" });
    expect(result.every((i) => i.bucket === "Kinetic")).toBe(true);
  });

  it("filters by bucket", () => {
    const result = filterInventoryItems(items, { bucket: "Helmet" });
    expect(result).toHaveLength(1);
  });

  it("excludes non-weapon/armor buckets", () => {
    const result = filterInventoryItems(items, {});
    expect(result.some((i) => i.instanceId === "inst-sub")).toBe(false);
  });

  it("filters projected instances by perk q", () => {
    const projected = items
      .filter((i) => i.instanceId !== "inst-sub")
      .map((i) => projectInstance(i, samplePlugNameMap));
    const result = filterProjectedByPerkQuery(projected, "frenzy");
    expect(result).toHaveLength(1);
    expect(result[0]?.instanceId).toBe("inst-vault-1");
  });

  it("returns empty for itemHash with no matches", () => {
    const result = filterInventoryItems(items, { itemHash: 1 });
    expect(result).toEqual([]);
  });

  it("maps weapons kind query", () => {
    expect(kindFromQuery("weapons")).toBe("weapon");
    expect(kindFromQuery("armor")).toBe("armor");
  });
});
