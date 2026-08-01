import { describe, expect, it } from "vitest";

import type { CatalogItem } from "@/lib/catalog/types";
import { attachInstancePointers } from "./catalogPointer";
import { buildInstancesHref } from "./instancesHref";

describe("catalogPointer", () => {
  const row: CatalogItem = {
    hash: 100,
    name: "Test",
    icon: null,
    isExotic: false,
    owned: true,
    ownedCount: 2,
  };

  it("leaves items unchanged when disabled", () => {
    expect(attachInstancePointers([row], false)).toEqual([row]);
  });

  it("adds instancesHref for owned rows when enabled", () => {
    const result = attachInstancePointers([row], true);
    expect(result[0]?.instancesHref).toBe(buildInstancesHref(100));
  });

  it("skips pointer when ownedCount is zero", () => {
    const unowned = { ...row, owned: false, ownedCount: 0 };
    const result = attachInstancePointers([unowned], true);
    expect(result[0]?.instancesHref).toBeUndefined();
  });
});
