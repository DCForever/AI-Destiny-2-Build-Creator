import { describe, expect, it } from "vitest";

import type { BuildRequest } from "@/lib/llm/buildSchema";

import { SUBCLASSES_BY_CLASS } from "./subclasses";

const CLASSES: BuildRequest["className"][] = ["Titan", "Hunter", "Warlock"];

describe("SUBCLASSES_BY_CLASS", () => {
  it("defines subclasses for every guardian class", () => {
    for (const cls of CLASSES) {
      expect(SUBCLASSES_BY_CLASS[cls].length).toBeGreaterThan(0);
    }
  });

  it("keeps prismatic subclasses class-specific", () => {
    expect(SUBCLASSES_BY_CLASS.Titan).toContain("Prismatic Titan");
    expect(SUBCLASSES_BY_CLASS.Hunter).toContain("Prismatic Hunter");
    expect(SUBCLASSES_BY_CLASS.Warlock).toContain("Prismatic Warlock");
  });
});
