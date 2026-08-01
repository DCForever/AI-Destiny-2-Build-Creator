import { describe, expect, it } from "vitest";
import { readFileSync } from "node:fs";
import { join } from "node:path";

describe("US4 identity vs artifact", () => {
  it("identityFieldsChanged does not treat artifact as identity", () => {
    const src = readFileSync(join(process.cwd(), "src/lib/builds/buildService.ts"), "utf8");
    const start = src.indexOf("function identityFieldsChanged");
    const end = src.indexOf("\n}", start);
    const fn = src.slice(start, end);
    expect(fn).not.toMatch(/artifact/i);
  });
});
