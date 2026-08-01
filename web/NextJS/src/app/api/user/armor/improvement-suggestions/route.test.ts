import { describe, expect, it } from "vitest";

import { parseImprovementSuggestionsQuery } from "@/lib/optimizer/improvementSuggestions";

function query(search: string) {
  return parseImprovementSuggestionsQuery(new URL(`https://x.test/api${search}`));
}

describe("GET /api/user/armor/improvement-suggestions query", () => {
  it("defaults to no afterSync and no armorSetId", () => {
    expect(query("")).toEqual({ afterSync: false });
  });

  it("parses afterSync=1 as a boolean hint", () => {
    expect(query("?afterSync=1").afterSync).toBe(true);
  });

  it("parses a single armorSetId for on-open checks", () => {
    expect(query("?armorSetId=set-9")).toEqual({ afterSync: false, armorSetId: "set-9" });
  });
});
