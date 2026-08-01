import { describe, expect, it } from "vitest";

import { catalogBucketForSetType, setSlotToCatalogBucket } from "./catalogSlotMap";

describe("setSlotToCatalogBucket", () => {
  it("maps weapon set slots to catalog buckets", () => {
    expect(setSlotToCatalogBucket("primary")).toBe("Kinetic");
    expect(setSlotToCatalogBucket("special")).toBe("Energy");
    expect(setSlotToCatalogBucket("heavy")).toBe("Power");
  });

  it("maps armor set slots to catalog buckets", () => {
    expect(setSlotToCatalogBucket("helmet")).toBe("Helmet");
    expect(setSlotToCatalogBucket("arms")).toBe("Gauntlets");
    expect(setSlotToCatalogBucket("chest")).toBe("Chest");
    expect(setSlotToCatalogBucket("legs")).toBe("Legs");
    expect(setSlotToCatalogBucket("class_item")).toBe("ClassItem");
  });

  it("returns null for unsupported slots", () => {
    expect(setSlotToCatalogBucket("exotic_weapon")).toBeNull();
    expect(setSlotToCatalogBucket("unknown")).toBeNull();
  });
});

describe("catalogBucketForSetType", () => {
  it("returns weapons kind for weapon sets", () => {
    expect(catalogBucketForSetType("weapon")).toBe("weapons");
  });

  it("returns armor kind for armor sets", () => {
    expect(catalogBucketForSetType("armor")).toBe("armor");
  });

  it("returns null for unsupported set types", () => {
    expect(catalogBucketForSetType("mod")).toBeNull();
    expect(catalogBucketForSetType("fashion")).toBeNull();
  });
});
