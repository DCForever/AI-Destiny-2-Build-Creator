import { describe, expect, it, vi } from "vitest";

import { SUB_TYPE_REQUIRED_TYPES } from "@/lib/synergies/synergyTypeRules";
import { listSubTypeOptions } from "@/lib/synergies/subTypeVocabularies";

vi.mock("@/lib/synergies/subTypeVocabularies", () => ({
  listSubTypeOptions: vi.fn(async () => [{ id: "scorch", name: "Scorch" }]),
}));

describe("subtypes picker route", () => {
  it("validates category enum", async () => {
    expect(SUB_TYPE_REQUIRED_TYPES).toContain("verb");
    const options = await listSubTypeOptions("verb");
    expect(options[0]?.name).toBe("Scorch");
  });
});
