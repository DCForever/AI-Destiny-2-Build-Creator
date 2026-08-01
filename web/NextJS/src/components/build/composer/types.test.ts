import { describe, expect, it } from "vitest";

import {
  COMPOSER_AREA_TAB_IDS,
  COMPOSER_TABS,
} from "@/components/build/composer/types";

describe("COMPOSER_TABS", () => {
  it("is the same full set for default and non-default (FR-018)", () => {
    expect(COMPOSER_TABS.map((t) => t.id)).toEqual([
      "general",
      "subclass",
      "armor",
      "weapon",
      "finish",
    ]);
  });

  it("exposes exactly four product areas plus Finish chrome (DBR-CMPL-005)", () => {
    const areas = COMPOSER_TABS.filter((t) => t.isArea);
    expect(areas.map((t) => t.id)).toEqual([
      "general",
      "subclass",
      "armor",
      "weapon",
    ]);
    expect(areas).toHaveLength(4);
    expect(COMPOSER_AREA_TAB_IDS).toHaveLength(4);
    expect(COMPOSER_TABS.find((t) => t.id === "finish")?.isArea).toBe(false);
  });

  it("uses product area labels", () => {
    expect(COMPOSER_TABS.find((t) => t.id === "armor")?.label).toBe(
      "Armor + Mods Sets",
    );
    expect(COMPOSER_TABS.find((t) => t.id === "weapon")?.label).toBe(
      "Weapons Set",
    );
  });
});
