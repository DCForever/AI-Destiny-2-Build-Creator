import { describe, expect, it, vi } from "vitest";

import { searchSynergyLinkPickerItems } from "@/lib/synergies/synergyPickerLinks";

vi.mock("@/lib/synergies/synergyPickerLinks", () => ({
  searchSynergyLinkPickerItems: vi.fn(async () => []),
}));

describe("links picker route", () => {
  it("delegates to searchSynergyLinkPickerItems", async () => {
    await searchSynergyLinkPickerItems("origin_trait", "cast", 10);
    expect(searchSynergyLinkPickerItems).toHaveBeenCalledWith("origin_trait", "cast", 10);
  });
});
