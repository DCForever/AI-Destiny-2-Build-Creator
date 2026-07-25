import { describe, expect, it } from "vitest";
import { CONCEPT_TAGS } from "@/data/conceptTags";
import { conceptTagIdsFromSynergyDesignations } from "./synergyConceptTags";

describe("conceptTagIdsFromSynergyDesignations", () => {
  it("matches known labels case-insensitively", () => {
    const sample = CONCEPT_TAGS[0];
    if (!sample) return;
    const ids = conceptTagIdsFromSynergyDesignations([
      { type: sample.label },
      { type: "NotARealTagXYZ" },
    ]);
    expect(ids).toContain(sample.id);
  });
});
