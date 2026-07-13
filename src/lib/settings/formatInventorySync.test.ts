import { describe, expect, it } from "vitest";

import {
  formatLastSyncLabel,
  inventorySyncSummary,
  resolveLastSyncIso,
} from "./formatInventorySync";

describe("formatInventorySync", () => {
  it("prefers lastFullSyncAt over lastSyncAt", () => {
    expect(
      resolveLastSyncIso({
        itemCount: 10,
        syncVersion: 1,
        lastFullSyncAt: "2026-07-12T14:40:00.000Z",
        lastSyncAt: "2026-07-01T00:00:00.000Z",
      }),
    ).toBe("2026-07-12T14:40:00.000Z");
  });

  it("returns Never when no timestamps", () => {
    expect(formatLastSyncLabel(null)).toBe("Never");
    expect(
      formatLastSyncLabel({
        itemCount: 0,
        syncVersion: 0,
        lastFullSyncAt: null,
        lastSyncAt: null,
      }),
    ).toBe("Never");
  });

  it("summarizes item count only after a sync", () => {
    expect(inventorySyncSummary(null)).toEqual({
      lastSyncLabel: "Never",
      itemCountLabel: "—",
      hasSynced: false,
    });
    expect(
      inventorySyncSummary({
        itemCount: 428,
        syncVersion: 3,
        lastFullSyncAt: "2026-07-12T14:40:00.000Z",
        lastSyncAt: null,
      }).itemCountLabel,
    ).toBe("428 items");
  });
});
