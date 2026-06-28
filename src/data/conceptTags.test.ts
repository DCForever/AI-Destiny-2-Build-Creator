import { describe, expect, it } from "vitest";
import {
  CONCEPT_TAGS,
  conceptTagIdsSchema,
  conceptTagsByFacet,
  formatTagFilterLabel,
  getConceptTag,
  isConceptTagId,
} from "./conceptTags";

describe("conceptTags", () => {
  it("defines unique tag ids", () => {
    const ids = CONCEPT_TAGS.map((t) => t.id);
    expect(new Set(ids).size).toBe(ids.length);
  });

  it("validates tag id arrays", () => {
    expect(conceptTagIdsSchema.safeParse(["solar", "melee"]).success).toBe(true);
    expect(conceptTagIdsSchema.safeParse(["solar", "invalid"]).success).toBe(false);
    expect(conceptTagIdsSchema.safeParse(["solar", "solar"]).success).toBe(false);
  });

  it("groups tags by facet", () => {
    const grouped = conceptTagsByFacet();
    expect(grouped.activity.some((t) => t.id === "pve")).toBe(true);
    expect(grouped.element.some((t) => t.id === "solar")).toBe(true);
    expect(grouped.playstyle.some((t) => t.id === "melee")).toBe(true);
  });

  it("formats multi-tag filter labels", () => {
    expect(formatTagFilterLabel(["solar", "melee"])).toBe("Solar · Melee");
  });

  it("looks up tags by id", () => {
    expect(getConceptTag("solar")?.label).toBe("Solar");
    expect(isConceptTagId("melee")).toBe(true);
    expect(isConceptTagId("custom")).toBe(false);
  });
});
