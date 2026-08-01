import { describe, expect, it } from "vitest";

import { createSetsFromBuildBodySchema } from "@/lib/builds/createSetsFromBuild";

describe("POST /api/user/builds/[id]/create-sets body schema", () => {
  it("defaults attachNow to true and accepts empty body", () => {
    const parsed = createSetsFromBuildBodySchema.safeParse({});
    expect(parsed.success).toBe(true);
    if (parsed.success) {
      expect(parsed.data.attachNow).toBe(true);
    }
  });

  it("accepts categories and attachNow false", () => {
    const parsed = createSetsFromBuildBodySchema.safeParse({
      attachNow: false,
      categories: ["armor", "weapon"],
      namePrefix: "Raid",
    });
    expect(parsed.success).toBe(true);
    if (parsed.success) {
      expect(parsed.data.attachNow).toBe(false);
      expect(parsed.data.categories).toEqual(["armor", "weapon"]);
      expect(parsed.data.namePrefix).toBe("Raid");
    }
  });

  it("rejects invalid category", () => {
    const parsed = createSetsFromBuildBodySchema.safeParse({
      categories: ["artifact"],
    });
    expect(parsed.success).toBe(false);
  });
});
