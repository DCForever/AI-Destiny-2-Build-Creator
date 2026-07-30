import { describe, expect, it } from "vitest";

import {
  entityLabelParts,
  hashFooter,
  isBareHashLabel,
  primaryEntityLabel,
} from "@/lib/presentation/displayName";

describe("isBareHashLabel", () => {
  it("detects empty and pure-digit labels", () => {
    expect(isBareHashLabel(null)).toBe(true);
    expect(isBareHashLabel("")).toBe(true);
    expect(isBareHashLabel("  ")).toBe(true);
    expect(isBareHashLabel("12345")).toBe(true);
    expect(isBareHashLabel("Sunshot")).toBe(false);
    expect(isBareHashLabel("Unknown (99)")).toBe(false);
  });
});

describe("entityLabelParts / primaryEntityLabel", () => {
  it("uses name as primary and hash as footer", () => {
    const p = entityLabelParts({ name: "Sunshot", hash: 42, kind: "item" });
    expect(p.primary).toBe("Sunshot");
    expect(p.footer).toBe("#42");
    expect(p.unknown).toBe(false);
  });

  it("never uses bare hash as primary", () => {
    expect(primaryEntityLabel("999", 999, "item")).toBe("Unknown item");
    expect(entityLabelParts({ name: "999", hash: 999, kind: "item" })).toEqual({
      primary: "Unknown item",
      footer: "#999",
      unknown: true,
    });
  });

  it("unknown without hash", () => {
    const p = entityLabelParts({ name: null, kind: "plug" });
    expect(p.primary).toBe("Unknown plug");
    expect(p.footer).toBeNull();
    expect(p.unknown).toBe(true);
  });
});

describe("hashFooter", () => {
  it("formats positive hashes", () => {
    expect(hashFooter(10)).toBe("#10");
    expect(hashFooter(null)).toBeNull();
    expect(hashFooter(0)).toBeNull();
  });
});
