import { describe, expect, it } from "vitest";

import { classifyLoadoutExotics } from "./classifyExotics";
import {
  crownWarlockLoadout,
  hallowfireTitanLoadout,
  manifestStores,
  noExoticLoadout,
  witherLoadout,
} from "./__fixtures__/loadoutFixtures";

describe("classifyLoadoutExotics", () => {
  it("classifies armor hash slot and class from manifest", () => {
    const summary = classifyLoadoutExotics(crownWarlockLoadout, manifestStores);
    expect(summary.exoticArmor?.hash).toBe(2001);
    expect(summary.exoticArmor?.slot).toBe("Helmet");
    expect(summary.exoticArmor?.classType).toBe("Warlock");
    expect(summary.className).toBe("Warlock");
  });

  it("detects exotic weapon", () => {
    const summary = classifyLoadoutExotics(witherLoadout, manifestStores);
    expect(summary.exoticWeapon?.name).toBe("Witherhoard");
    expect(summary.exoticWeapon?.slot).toBe("Kinetic");
  });

  it("returns null weapon when none equipped", () => {
    const summary = classifyLoadoutExotics(crownWarlockLoadout, manifestStores);
    expect(summary.exoticWeapon).toBeNull();
  });

  it("uses name fallback when hash unresolved", () => {
    const summary = classifyLoadoutExotics(noExoticLoadout, manifestStores);
    expect(summary.exoticArmor?.hash).toBeNull();
    expect(summary.exoticArmor?.name).toBe("Hallowfire Heart");
    expect(summary.exoticArmor?.slot).toBeNull();
  });

  it("classifies titan chest from manifest", () => {
    const summary = classifyLoadoutExotics(hallowfireTitanLoadout, manifestStores);
    expect(summary.exoticArmor?.slot).toBe("Chest");
    expect(summary.exoticArmor?.classType).toBe("Titan");
  });
});
