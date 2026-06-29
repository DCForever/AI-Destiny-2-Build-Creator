import { describe, expect, it } from "vitest";

import { bucketHashToSlot, slotToBucketHash } from "./slotMap";

describe("slotMap", () => {
  it("maps primary bucket hash", () => {
    expect(bucketHashToSlot(1498876634)).toBe("primary");
  });

  it("round-trips known slots", () => {
    const hash = slotToBucketHash("helmet");
    expect(hash).not.toBeNull();
    expect(bucketHashToSlot(hash!)).toBe("helmet");
  });

  it("returns null for unknown bucket", () => {
    expect(bucketHashToSlot(0)).toBeNull();
  });
});
