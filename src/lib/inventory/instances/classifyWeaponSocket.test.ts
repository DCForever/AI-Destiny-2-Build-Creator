import { describe, expect, it } from "vitest";

import { classifyWeaponSocket, isEnhancedPlug } from "./classifyWeaponSocket";

describe("classifyWeaponSocket", () => {
  const weaponPerkSocketIndexes = [0, 1, 2, 3];

  it("labels barrel, magazine, and trait columns from plug categories", () => {
    const categories = new Map<number, string>([
      [101, "barrels.rifle"],
      [201, "magazines.ar"],
      [301, "traits.weapon"],
      [302, "traits.weapon"],
    ]);

    expect(
      classifyWeaponSocket({
        socketIndex: 0,
        equippedPlugHash: 101,
        plugCategoryByHash: categories,
        weaponPerkSocketIndexes,
      }),
    ).toMatchObject({ columnKind: "barrel", columnLabel: "Barrel", includeInGrid: true });

    expect(
      classifyWeaponSocket({
        socketIndex: 1,
        equippedPlugHash: 201,
        plugCategoryByHash: categories,
        weaponPerkSocketIndexes,
      }),
    ).toMatchObject({ columnKind: "magazine", columnLabel: "Magazine", includeInGrid: true });

    expect(
      classifyWeaponSocket({
        socketIndex: 2,
        equippedPlugHash: 301,
        plugCategoryByHash: categories,
        weaponPerkSocketIndexes,
      }),
    ).toMatchObject({ columnKind: "trait", columnLabel: "Trait 1", includeInGrid: true });

    expect(
      classifyWeaponSocket({
        socketIndex: 3,
        equippedPlugHash: 302,
        plugCategoryByHash: categories,
        weaponPerkSocketIndexes,
      }),
    ).toMatchObject({ columnKind: "trait", columnLabel: "Trait 2", includeInGrid: true });
  });

  it("excludes sockets outside weapon-perk indexes without a known column kind", () => {
    const categories = new Map<number, string>([[901, "traits.weapon"]]);
    expect(
      classifyWeaponSocket({
        socketIndex: 9,
        equippedPlugHash: 901,
        plugCategoryByHash: categories,
        weaponPerkSocketIndexes: [0, 1, 2, 3],
      }).includeInGrid,
    ).toBe(false);
  });

  it("labels true intrinsics as Intrinsic (not bare frames category)", () => {
    expect(
      classifyWeaponSocket({
        socketIndex: 0,
        equippedPlugHash: 401,
        plugCategoryByHash: new Map([[401, "intrinsics"]]),
        weaponPerkSocketIndexes: [0, 1, 2, 3],
      }).columnLabel,
    ).toBe("Intrinsic");
  });

  it("treats Enhanced Trait plugs under frames category as traits", () => {
    expect(
      classifyWeaponSocket({
        socketIndex: 3,
        equippedPlugHash: 402,
        plugCategoryByHash: new Map([[402, "frames"]]),
        plugItemTypeByHash: new Map([[402, "Enhanced Trait"]]),
        weaponPerkSocketIndexes: [0, 1, 2, 3],
      }),
    ).toMatchObject({ columnKind: "trait", includeInGrid: true });
  });

  it("includes masterwork before generic enhancements exclusion", () => {
    expect(
      classifyWeaponSocket({
        socketIndex: 8,
        equippedPlugHash: 601,
        plugCategoryByHash: new Map([[601, "enhancements.weapon.masterwork"]]),
        weaponPerkSocketIndexes: [0, 1, 2, 3],
      }),
    ).toMatchObject({ columnKind: "masterwork", columnLabel: "Masterwork", includeInGrid: true });
  });

  it("excludes gear-tier enhancement sockets", () => {
    expect(
      classifyWeaponSocket({
        socketIndex: 12,
        equippedPlugHash: 701,
        plugCategoryByHash: new Map([[701, "enhancements.tuning"]]),
        weaponPerkSocketIndexes: [0, 1, 2, 3],
      }).includeInGrid,
    ).toBe(false);
  });

  it("excludes shader and ornament sockets", () => {
    const categories = new Map<number, string>([[901, "shader"]]);
    expect(
      classifyWeaponSocket({
        socketIndex: 9,
        equippedPlugHash: 901,
        plugCategoryByHash: categories,
        weaponPerkSocketIndexes,
      }).includeInGrid,
    ).toBe(false);
  });

  it("maps intrinsic, origin, masterwork, and catalyst sockets", () => {
    const categories = new Map<number, string>([
      [401, "intrinsics"],
      [501, "origins"],
      [601, "masterwork"],
      [701, "catalyst"],
    ]);

    expect(
      classifyWeaponSocket({
        socketIndex: 4,
        equippedPlugHash: 401,
        plugCategoryByHash: categories,
        weaponPerkSocketIndexes,
      }).columnKind,
    ).toBe("intrinsic");

    expect(
      classifyWeaponSocket({
        socketIndex: 5,
        equippedPlugHash: 501,
        plugCategoryByHash: categories,
        weaponPerkSocketIndexes,
      }).columnKind,
    ).toBe("origin");

    expect(
      classifyWeaponSocket({
        socketIndex: 6,
        equippedPlugHash: 601,
        plugCategoryByHash: categories,
        weaponPerkSocketIndexes,
      }).columnKind,
    ).toBe("masterwork");

    expect(
      classifyWeaponSocket({
        socketIndex: 7,
        equippedPlugHash: 701,
        plugCategoryByHash: categories,
        weaponPerkSocketIndexes,
      }).columnKind,
    ).toBe("catalyst");
  });

  it("detects enhanced plug variants", () => {
    expect(isEnhancedPlug("Zen Moment", "enhancements.v2")).toBe(true);
    expect(isEnhancedPlug("Zen Moment Enhanced", "traits.weapon")).toBe(true);
    expect(isEnhancedPlug("Zen Moment", "traits.weapon")).toBe(false);
  });
});
