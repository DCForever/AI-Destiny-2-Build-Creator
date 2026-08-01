import { describe, expect, it } from "vitest";

import {
  createPerkGridRefreshState,
  markSyncAttempted,
  markSyncFinished,
  shouldAutoSync,
} from "./perkGridRefresh";

describe("perkGridRefresh", () => {
  it("allows one auto sync per instance per session", () => {
    let state = createPerkGridRefreshState();
    expect(shouldAutoSync(state, "inst-1")).toBe(true);
    state = markSyncAttempted(state, "inst-1");
    expect(shouldAutoSync(state, "inst-1")).toBe(false);
    state = markSyncFinished(state);
    expect(shouldAutoSync(state, "inst-2")).toBe(true);
    expect(shouldAutoSync(state, "inst-1")).toBe(false);
  });

  it("blocks while sync is in flight", () => {
    let state = markSyncAttempted(createPerkGridRefreshState(), "inst-1");
    expect(shouldAutoSync(state, "inst-2")).toBe(false);
    state = markSyncFinished(state);
    expect(shouldAutoSync(state, "inst-2")).toBe(true);
  });
});
