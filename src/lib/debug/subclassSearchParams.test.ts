import { describe, expect, it } from "vitest";

import { buildSubclassSearchParams } from "./subclassSearchParams";

describe("buildSubclassSearchParams", () => {
  it("includes class/element/kind and auto-scopes subclass affinities for abilities", () => {
    const params = buildSubclassSearchParams({
      category: "abilities",
      q: "",
      subclassName: "Stormcaller",
      kind: "super",
    });
    expect(params.get("category")).toBe("abilities");
    expect(params.get("classType")).toBe("Warlock");
    expect(params.get("element")).toBe("Arc");
    expect(params.get("kind")).toBe("super");
    expect(params.get("subclass")).toBe("Stormcaller");
  });

  it("lets optional affinity filter override the selected subclass", () => {
    const params = buildSubclassSearchParams({
      category: "abilities",
      q: "",
      subclassName: "Dawnblade",
      kind: "classAbility",
      filters: { subclassAffinity: "Prismatic Warlock", verb: "Cure" },
    });
    expect(params.get("subclass")).toBe("Prismatic Warlock");
    expect(params.get("verb")).toBe("Cure");
  });

  it("does not pass subclass/verb for aspects", () => {
    const params = buildSubclassSearchParams({
      category: "aspects",
      q: "touch",
      subclassName: "Stormcaller",
      filters: { subclassAffinity: "Stormcaller", verb: "Jolt" },
    });
    expect(params.get("subclass")).toBeNull();
    expect(params.get("verb")).toBeNull();
  });
});
