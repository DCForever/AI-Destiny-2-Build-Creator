import { describe, expect, it } from "vitest";

import {
  addExoticArmorClaim,
  addExoticWeaponClaim,
  assertFullCombatLoadout,
  assertNoSlotConflicts,
  buildEquipmentMap,
  detectSlotConflicts,
  effectiveExoticWeapon,
  itemsToSlotClaims,
  validatePairArmorMatch,
  type ExpandedSetItem,
  type SlotClaim,
} from "./resolveVariant";
import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";
import type { BuildRecord } from "@/lib/db/repositories/buildRepository";

describe("resolveVariant", () => {
  it("detects slot conflicts between set items", () => {
    const claims = itemsToSlotClaims([
      {
        slot: "primary",
        itemHash: 1,
        itemName: "A",
        setId: "s1",
        setType: "weapon",
      },
      {
        slot: "primary",
        itemHash: 2,
        itemName: "B",
        setId: "s2",
        setType: "weapon",
      },
    ]);

    const conflicts = detectSlotConflicts(claims);
    expect(conflicts).toHaveLength(1);
    expect(conflicts[0]?.slot).toBe("primary");
    expect(() => assertNoSlotConflicts({ equipment: buildEquipmentMap(claims), conflicts })).toThrow(ApiError);
    try {
      assertNoSlotConflicts({ equipment: buildEquipmentMap(claims), conflicts });
    } catch (err) {
      expect(err).toMatchObject({ code: API_ERROR_CODES.SLOT_CONFLICT });
    }
  });

  it("adds exotic weapon and armor claims", () => {
    let claims = addExoticWeaponClaim([], { exoticWeaponHash: 10, exoticWeaponName: "Vex" }, "primary");
    claims = addExoticArmorClaim(claims, { exoticArmorHash: 20, exoticArmorName: "Crown" }, "helmet");
    expect(claims).toHaveLength(2);
  });

  it("skips exotic armor claim when hash is null", () => {
    const claims = addExoticArmorClaim([], { exoticArmorHash: null, exoticArmorName: null }, "helmet");
    expect(claims).toHaveLength(0);
  });

  it("prefers build-shared exotic weapon over variant", () => {
    const weapon = effectiveExoticWeapon(
      {
        exoticWeaponHash: 111,
        exoticWeaponName: "Shared",
      } as BuildRecord,
      { exoticWeaponHash: 222, exoticWeaponName: "Variant" } as never,
    );
    expect(weapon.exoticWeaponHash).toBe(111);
    expect(weapon.fromBuild).toBe(true);
  });

  it("asserts full combat loadout gaps", () => {
    const build = {
      className: "Titan",
      subclass: { name: "Sunbreaker" },
    } as BuildRecord;
    expect(() =>
      assertFullCombatLoadout({ equipment: { primary: {} as never }, conflicts: [] }, build, {
        hasMods: false,
      }),
    ).toThrow(expect.objectContaining({ code: API_ERROR_CODES.DEFAULT_VARIANT_INCOMPLETE }));
  });

  it("rejects pair armor mismatch", () => {
    const pairItems: ExpandedSetItem[] = [
      {
        slot: "exotic_armor",
        itemHash: 999,
        itemName: "Wrong",
        setId: "p1",
        setType: "pair",
      },
    ];
    expect(() => validatePairArmorMatch({ exoticArmorHash: 100 }, pairItems)).toThrow(
      expect.objectContaining({ code: API_ERROR_CODES.PAIR_ARMOR_MISMATCH }),
    );
  });

  it("allows pair armor when build has no exotic armor", () => {
    const pairItems: ExpandedSetItem[] = [
      {
        slot: "exotic_armor",
        itemHash: 999,
        itemName: "Any",
        setId: "p1",
        setType: "pair",
      },
    ];
    expect(() => validatePairArmorMatch({ exoticArmorHash: null }, pairItems)).not.toThrow();
  });

  it("allows pair armor mismatch in class-item intent mode", () => {
    const pairItems: ExpandedSetItem[] = [
      {
        slot: "exotic_armor",
        itemHash: 999,
        itemName: "Other class item",
        setId: "p1",
        setType: "pair",
      },
    ];
    expect(() =>
      validatePairArmorMatch({ exoticArmorHash: 100 }, pairItems, { intentMode: true }),
    ).not.toThrow();
  });

  it("skips build exotic injection when class_item already claimed in intent mode", () => {
    const existing: SlotClaim[] = [
      {
        slot: "class_item",
        itemHash: 50,
        itemName: "Variant CI",
        source: "set",
        selectedPerks: [1, 2],
      },
    ];
    const next = addExoticArmorClaim(
      existing,
      { exoticArmorHash: 100, exoticArmorName: "Build CI" },
      "class_item",
      { skipIfClassItemClaimed: true },
    );
    expect(next).toHaveLength(1);
    expect(next[0]?.itemHash).toBe(50);
    expect(next[0]?.selectedPerks).toEqual([1, 2]);
  });
});
