import { describe, expect, it } from "vitest";

import { COMPOSER_TABS } from "@/components/build/composer/types";

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
});
