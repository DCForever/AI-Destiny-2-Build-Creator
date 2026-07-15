import { describe, expect, it } from "vitest";

import { refreshOptimizeBodySchema } from "@/lib/optimizer/optimizeFromSet";

describe("POST /api/user/sets/[id]/optimize body schema", () => {
  it("accepts an empty body (uses stored constraints)", () => {
    expect(refreshOptimizeBodySchema.safeParse({}).success).toBe(true);
  });

  it("accepts per-run overrides and maxResults", () => {
    const parsed = refreshOptimizeBodySchema.safeParse({
      overrides: { preferReuse: true, statPriorities: ["Melee"] },
      maxResults: 10,
    });
    expect(parsed.success).toBe(true);
  });

  it("rejects maxResults above 50", () => {
    expect(refreshOptimizeBodySchema.safeParse({ maxResults: 51 }).success).toBe(false);
  });

  it("rejects unknown stat names in overrides", () => {
    const parsed = refreshOptimizeBodySchema.safeParse({
      overrides: { statPriorities: ["Mobility"] },
    });
    expect(parsed.success).toBe(false);
  });
});
