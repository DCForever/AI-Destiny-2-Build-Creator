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
});
