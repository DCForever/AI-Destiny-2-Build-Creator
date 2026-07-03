import { describe, expect, it } from "vitest";

import { setItemInputSchema } from "./schemas";

describe("setItemInputSchema instanceId", () => {
  it("accepts an optional instanceId", () => {
    const parsed = setItemInputSchema.parse({
      slot: "primary",
      itemHash: 100,
      instanceId: "inst-1",
    });
    expect(parsed.instanceId).toBe("inst-1");
  });

  it("allows instanceId to be omitted", () => {
    const parsed = setItemInputSchema.parse({ slot: "primary", itemHash: 100 });
    expect(parsed.instanceId).toBeUndefined();
  });

  it("rejects an empty instanceId", () => {
    const result = setItemInputSchema.safeParse({
      slot: "primary",
      itemHash: 100,
      instanceId: "",
    });
    expect(result.success).toBe(false);
  });
});
