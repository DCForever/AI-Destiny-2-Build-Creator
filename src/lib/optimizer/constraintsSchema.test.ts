import { describe, expect, it } from "vitest";

import {
  emptyOptimizerConstraints,
  hasOptimizerConstraintsPayload,
  parseOptimizerConstraints,
  serializeOptimizerConstraints,
} from "./constraintsSchema";

describe("optimizer constraints schema", () => {
  it("round-trips preferReuse default payload", () => {
    const c = emptyOptimizerConstraints();
    expect(c.preferReuse).toBe(false);
    const raw = serializeOptimizerConstraints(c);
    expect(parseOptimizerConstraints(raw)?.preferReuse).toBe(false);
  });

  it("parses exotic + soft thresholds", () => {
    const raw = JSON.stringify({
      lockedExoticItemHash: 42,
      statThresholds: { Melee: 100 },
      preferReuse: true,
    });
    const parsed = parseOptimizerConstraints(raw);
    expect(parsed?.lockedExoticItemHash).toBe(42);
    expect(parsed?.statThresholds?.Melee).toBe(100);
    expect(parsed?.preferReuse).toBe(true);
  });

  it("returns null for invalid JSON or schema", () => {
    expect(parseOptimizerConstraints("not-json")).toBeNull();
    expect(parseOptimizerConstraints(JSON.stringify({ lockedExoticItemHash: "nope" }))).toBeNull();
  });

  it("treats any non-null payload as present for improvement eligibility", () => {
    expect(hasOptimizerConstraintsPayload(null)).toBe(false);
    expect(hasOptimizerConstraintsPayload({ preferReuse: false })).toBe(true);
  });
});
