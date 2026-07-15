import { describe, expect, it } from "vitest";

import { createTestSqlite } from "./client";

describe("schema migrations", () => {
  it("creates build_variants with notes column", () => {
    const sqlite = createTestSqlite();
    const row = sqlite.prepare("PRAGMA table_info(build_variants)").all() as Array<{ name: string }>;
    const columns = row.map((c) => c.name);
    expect(columns).toContain("notes");
  });

  it("creates sets table with unique user type name index", () => {
    const sqlite = createTestSqlite();
    const indexes = sqlite.prepare("PRAGMA index_list(sets)").all() as Array<{ name: string }>;
    expect(indexes.some((i) => i.name === "idx_sets_user_type_name")).toBe(true);
  });

  it("adds nullable set_items.instance_id column", () => {
    const sqlite = createTestSqlite();
    const cols = sqlite.prepare("PRAGMA table_info(set_items)").all() as Array<{
      name: string;
      notnull: number;
    }>;
    const col = cols.find((c) => c.name === "instance_id");
    expect(col).toBeDefined();
    expect(col?.notnull).toBe(0);
  });

  it("adds nullable inventory_items.gear_tier column", () => {
    const sqlite = createTestSqlite();
    const cols = sqlite.prepare("PRAGMA table_info(inventory_items)").all() as Array<{
      name: string;
      notnull: number;
    }>;
    const col = cols.find((c) => c.name === "gear_tier");
    expect(col).toBeDefined();
    expect(col?.notnull).toBe(0);
  });

  it("adds nullable inventory_items.socket_plugs column", () => {
    const sqlite = createTestSqlite();
    const cols = sqlite.prepare("PRAGMA table_info(inventory_items)").all() as Array<{
      name: string;
      notnull: number;
    }>;
    const col = cols.find((c) => c.name === "socket_plugs");
    expect(col).toBeDefined();
    expect(col?.notnull).toBe(0);
  });

  it("adds nullable sets.optimizer_constraints and linked_mod_set_id columns", () => {
    const sqlite = createTestSqlite();
    const cols = sqlite.prepare("PRAGMA table_info(sets)").all() as Array<{
      name: string;
      notnull: number;
    }>;
    const constraints = cols.find((c) => c.name === "optimizer_constraints");
    const linked = cols.find((c) => c.name === "linked_mod_set_id");
    expect(constraints).toBeDefined();
    expect(constraints?.notnull).toBe(0);
    expect(linked).toBeDefined();
    expect(linked?.notnull).toBe(0);
  });
});
