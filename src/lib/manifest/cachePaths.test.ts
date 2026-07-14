import { afterEach, describe, expect, it } from "vitest";
import os from "node:os";
import path from "node:path";

import {
  CACHE_ROOT_ENV,
  appDbPath,
  getCacheRoot,
  rawTablePath,
  userPreferencesPath,
} from "./cachePaths";

const ORIGINAL = process.env[CACHE_ROOT_ENV];

afterEach(() => {
  if (ORIGINAL === undefined) {
    delete process.env[CACHE_ROOT_ENV];
  } else {
    process.env[CACHE_ROOT_ENV] = ORIGINAL;
  }
});

describe("getCacheRoot", () => {
  it("defaults to <cwd>/.cache when D2BC_CACHE_ROOT is unset", () => {
    delete process.env[CACHE_ROOT_ENV];
    expect(getCacheRoot()).toBe(path.join(process.cwd(), ".cache"));
  });

  it("uses absolute D2BC_CACHE_ROOT when set", () => {
    const root = path.join(os.tmpdir(), "d2bc-cache-test-abs");
    process.env[CACHE_ROOT_ENV] = root;
    expect(getCacheRoot()).toBe(path.resolve(root));
    expect(appDbPath()).toBe(path.join(path.resolve(root), "app.db"));
  });

  it("resolves relative D2BC_CACHE_ROOT against cwd", () => {
    process.env[CACHE_ROOT_ENV] = "tmp-packaged-cache";
    expect(getCacheRoot()).toBe(path.resolve("tmp-packaged-cache"));
  });

  it("keeps derived paths under the override root", () => {
    const root = path.join(os.tmpdir(), "d2bc-cache-test-derived");
    process.env[CACHE_ROOT_ENV] = root;
    const resolved = path.resolve(root);
    expect(rawTablePath("1.2.3", "DestinyInventoryItemDefinition")).toBe(
      path.join(
        resolved,
        "manifest",
        "1.2.3",
        "DestinyInventoryItemDefinition.json",
      ),
    );
    expect(userPreferencesPath("123")).toBe(
      path.join(resolved, "users", "123", "preferences.json"),
    );
  });
});
