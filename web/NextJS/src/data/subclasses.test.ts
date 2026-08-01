import { describe, expect, it } from "vitest";

import { isKnownVerbSubType } from "@/data/synergyVerbs";
import type { BuildRequest } from "@/lib/llm/buildSchema";

import { SUBCLASSES_BY_CLASS, formatSubclassLabel, getSubclassMeta } from "./subclasses";

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

  it("exposes metadata helpers for every listed subclass", () => {
    for (const cls of CLASSES) {
      for (const name of SUBCLASSES_BY_CLASS[cls]) {
        const meta = getSubclassMeta(name);
        expect(meta?.element).toBeTruthy();
        expect(meta?.verbs.length).toBeGreaterThan(0);
        expect(formatSubclassLabel(name)).toContain(meta!.element);
        for (const verb of meta!.verbs) {
          expect(isKnownVerbSubType(verb.name)).toBe(true);
        }
      }
    }
  });
});
