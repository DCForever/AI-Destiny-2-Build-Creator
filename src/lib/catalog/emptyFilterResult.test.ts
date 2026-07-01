import { describe, expect, it } from "vitest";

import { emptyFilterMessage } from "./emptyFilterResult";

describe("emptyFilterMessage", () => {
  it("returns perk-specific message", () => {
    expect(emptyFilterMessage({ perk: "Unknown Perk" })).toBe("No matching perk: Unknown Perk");
  });

  it("returns origin trait message", () => {
    expect(emptyFilterMessage({ originTrait: "No Trait" })).toBe("No matching origin trait: No Trait");
  });

  it("returns set bonus message", () => {
    expect(emptyFilterMessage({ setBonus: "No Set" })).toBe("No matching set bonus: No Set");
  });

  it("returns null when no named filter", () => {
    expect(emptyFilterMessage({})).toBeNull();
  });
});
