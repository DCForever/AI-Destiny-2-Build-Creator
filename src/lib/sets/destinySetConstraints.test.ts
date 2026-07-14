import { describe, expect, it } from "vitest";

import {
  assertSetCompositionAllowed,
  assertSetExoticExclusivity,
  assertSetItemAllowed,
  kindFromEntityStore,
  setAlreadyHasExotic,
  setItemMetaFromCatalog,
  setItemMetaFromManifestCategory,
} from "./destinySetConstraints";

describe("assertSetItemAllowed", () => {
  it("rejects invalid slots for set type", () => {
    const r = assertSetItemAllowed("weapon", "helmet", {
      kind: "weapon",
      equipmentSlot: "Kinetic",
    });
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.reasons[0]).toMatch(/not valid/i);
  });

  it("rejects armor in a weapon set", () => {
    const r = assertSetItemAllowed("weapon", "primary", {
      kind: "armor",
      equipmentSlot: "Helmet",
    });
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.reasons.join(" ")).toMatch(/weapons/i);
  });

  it("allows unknown kind on armor set (legendary armor store miss)", () => {
    expect(
      assertSetItemAllowed("armor", "helmet", { kind: "unknown" }),
    ).toEqual({ ok: true });
  });

  it("rejects Kinetic weapon in special (Energy) slot", () => {
    const r = assertSetItemAllowed("weapon", "special", {
      kind: "weapon",
      equipmentSlot: "Kinetic",
    });
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.reasons.join(" ")).toMatch(/Energy/i);
  });

  it("allows matching Kinetic weapon in primary", () => {
    const r = assertSetItemAllowed("weapon", "primary", {
      kind: "weapon",
      equipmentSlot: "Kinetic",
      isExotic: false,
    });
    expect(r).toEqual({ ok: true });
  });

  it("allows exotic weapon in primary", () => {
    const r = assertSetItemAllowed("weapon", "primary", {
      kind: "exotic_weapon",
      equipmentSlot: "Kinetic",
      isExotic: true,
    });
    expect(r).toEqual({ ok: true });
  });

  it("rejects wrong armor piece", () => {
    const r = assertSetItemAllowed("armor", "helmet", {
      kind: "armor",
      equipmentSlot: "Legs",
    });
    expect(r.ok).toBe(false);
  });

  it("allows matching helmet", () => {
    expect(
      assertSetItemAllowed("armor", "helmet", {
        kind: "armor",
        equipmentSlot: "Helmet",
      }),
    ).toEqual({ ok: true });
  });

  it("rejects legendary weapon in pair exotic_weapon", () => {
    const r = assertSetItemAllowed("pair", "exotic_weapon", {
      kind: "weapon",
      isExotic: false,
      equipmentSlot: "Kinetic",
    });
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.reasons.join(" ")).toMatch(/exotic weapon/i);
  });

  it("allows exotic weapon in pair exotic_weapon", () => {
    expect(
      assertSetItemAllowed("pair", "exotic_weapon", {
        kind: "exotic_weapon",
        isExotic: true,
      }),
    ).toEqual({ ok: true });
  });

  it("rejects non-exotic armor in pair exotic_armor", () => {
    const r = assertSetItemAllowed("pair", "exotic_armor", {
      kind: "armor",
      isExotic: false,
      equipmentSlot: "Helmet",
    });
    expect(r.ok).toBe(false);
  });

  it("rejects weapon hash meta in mod set", () => {
    const r = assertSetItemAllowed("mod", "mod:1", {
      kind: "weapon",
      equipmentSlot: "Kinetic",
    });
    expect(r.ok).toBe(false);
  });

  it("allows mods in mod set", () => {
    expect(
      assertSetItemAllowed("mod", "mod:42", { kind: "mod" }),
    ).toEqual({ ok: true });
  });

  it("allows fashion freely when slot valid", () => {
    expect(
      assertSetItemAllowed("fashion", "ghost", { kind: "unknown" }),
    ).toEqual({ ok: true });
  });

  it("skips bucket check when equipmentSlot unknown", () => {
    expect(
      assertSetItemAllowed("weapon", "primary", {
        kind: "weapon",
        equipmentSlot: null,
      }),
    ).toEqual({ ok: true });
  });
});

describe("assertSetExoticExclusivity", () => {
  it("blocks a second exotic weapon in a weapon set", () => {
    const r = assertSetExoticExclusivity({
      setType: "weapon",
      otherItems: [
        {
          slot: "primary",
          meta: {
            kind: "exotic_weapon",
            isExotic: true,
            name: "Witherhoard",
            equipmentSlot: "Kinetic",
          },
        },
      ],
      candidate: {
        slot: "heavy",
        meta: {
          kind: "exotic_weapon",
          isExotic: true,
          name: "Gjallarhorn",
          equipmentSlot: "Power",
        },
      },
    });
    expect(r.ok).toBe(false);
    if (!r.ok) expect(r.reasons[0]).toMatch(/Witherhoard|exotic/i);
  });

  it("allows legendary after one exotic weapon", () => {
    expect(
      assertSetExoticExclusivity({
        setType: "weapon",
        otherItems: [
          {
            slot: "primary",
            meta: { kind: "exotic_weapon", isExotic: true, name: "X" },
          },
        ],
        candidate: {
          slot: "special",
          meta: {
            kind: "weapon",
            isExotic: false,
            equipmentSlot: "Energy",
          },
        },
      }),
    ).toEqual({ ok: true });
  });

  it("allows replacing the slot that already holds the exotic", () => {
    // otherItems excludes the slot being replaced
    expect(
      assertSetExoticExclusivity({
        setType: "weapon",
        otherItems: [
          {
            slot: "special",
            meta: { kind: "weapon", isExotic: false },
          },
        ],
        candidate: {
          slot: "primary",
          meta: { kind: "exotic_weapon", isExotic: true },
        },
      }),
    ).toEqual({ ok: true });
  });

  it("blocks a second exotic armor piece", () => {
    const r = assertSetExoticExclusivity({
      setType: "armor",
      otherItems: [
        {
          slot: "helmet",
          meta: {
            kind: "exotic_armor",
            isExotic: true,
            name: "Synthoceps",
          },
        },
      ],
      candidate: {
        slot: "legs",
        meta: { kind: "exotic_armor", isExotic: true, name: "Dunemarchers" },
      },
    });
    expect(r.ok).toBe(false);
  });

  it("pair allows exotic weapon + exotic armor", () => {
    expect(
      assertSetExoticExclusivity({
        setType: "pair",
        otherItems: [
          {
            slot: "exotic_weapon",
            meta: { kind: "exotic_weapon", isExotic: true },
          },
        ],
        candidate: {
          slot: "exotic_armor",
          meta: { kind: "exotic_armor", isExotic: true },
        },
      }),
    ).toEqual({ ok: true });
  });

  it("assertSetCompositionAllowed combines fit + exclusivity", () => {
    const r = assertSetCompositionAllowed(
      "weapon",
      "heavy",
      {
        kind: "exotic_weapon",
        isExotic: true,
        equipmentSlot: "Power",
      },
      [
        {
          slot: "primary",
          meta: {
            kind: "exotic_weapon",
            isExotic: true,
            equipmentSlot: "Kinetic",
            name: "First",
          },
        },
      ],
    );
    expect(r.ok).toBe(false);
  });

  it("setAlreadyHasExotic detects weapon exotic", () => {
    const hit = setAlreadyHasExotic(
      "weapon",
      [
        {
          slot: "heavy",
          meta: { kind: "exotic_weapon", isExotic: true, name: "Ghorn" },
        },
      ],
      "weapon",
    );
    expect(hit?.meta.name).toBe("Ghorn");
  });
});

describe("helpers", () => {
  it("kindFromEntityStore maps stores", () => {
    expect(kindFromEntityStore("exotic-weapons")).toBe("exotic_weapon");
    expect(kindFromEntityStore("weapons")).toBe("weapon");
    expect(kindFromEntityStore("mods")).toBe("mod");
  });

  it("setItemMetaFromCatalog tags exotic weapons", () => {
    expect(
      setItemMetaFromCatalog({
        kind: "weapons",
        slot: "Power",
        isExotic: true,
      }),
    ).toEqual({
      kind: "exotic_weapon",
      equipmentSlot: "Power",
      isExotic: true,
    });
  });

  it("setItemMetaFromManifestCategory", () => {
    expect(setItemMetaFromManifestCategory("mods")).toMatchObject({ kind: "mod" });
    expect(setItemMetaFromManifestCategory("exotic-armor")).toMatchObject({
      kind: "exotic_armor",
      isExotic: true,
    });
  });
});
