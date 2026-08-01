import { describe, expect, it } from "vitest";

import { armorStatSortSchema, instanceFilterQuerySchema } from "@/lib/inventory/instances/schemas";

describe("instanceFilterQuerySchema", () => {
  it("accepts armor stat sortBy values", () => {
    expect(instanceFilterQuerySchema.safeParse({ sortBy: "Melee" }).success).toBe(true);
    expect(instanceFilterQuerySchema.safeParse({ sortBy: "total" }).success).toBe(true);
  });

  it("rejects invalid sortBy", () => {
    expect(instanceFilterQuerySchema.safeParse({ sortBy: "Resilience" }).success).toBe(false);
  });
});

describe("armorStatSortSchema", () => {
  it("includes all Armor 3.0 stat names", () => {
    for (const value of armorStatSortSchema.options) {
      expect(typeof value).toBe("string");
    }
  });
});
