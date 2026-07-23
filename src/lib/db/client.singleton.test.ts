import { afterEach, describe, expect, it } from "vitest";

import {
  createTestDb,
  createTestSqlite,
  getAppSqliteForTests,
  getDb,
  resetAppSqliteForTests,
} from "./client";

describe("process SQLite singleton", () => {
  afterEach(() => {
    resetAppSqliteForTests();
  });

  it("reuses one native handle across repeated getDb calls", () => {
    resetAppSqliteForTests();
    getDb();
    const a = getAppSqliteForTests();
    getDb();
    const b = getAppSqliteForTests();
    expect(a).toBe(b);
  });

  it("reuses one native handle after reset and reopen", () => {
    resetAppSqliteForTests();
    getDb();
    const first = getAppSqliteForTests();
    resetAppSqliteForTests();
    getDb();
    const second = getAppSqliteForTests();
    expect(second).not.toBe(first);
    getDb();
    expect(getAppSqliteForTests()).toBe(second);
  });

  it("keeps createTestSqlite isolated from the process singleton", () => {
    resetAppSqliteForTests();
    getDb();
    const appHandle = getAppSqliteForTests();
    const testHandle = createTestSqlite();
    expect(testHandle).not.toBe(appHandle);
    testHandle.close();
  });

  it("keeps createTestDb from replacing the process singleton", () => {
    resetAppSqliteForTests();
    getDb();
    const appHandle = getAppSqliteForTests();
    createTestDb();
    expect(getAppSqliteForTests()).toBe(appHandle);
  });
});
