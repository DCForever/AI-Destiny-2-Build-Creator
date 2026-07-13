import { describe, expect, it } from "vitest";

import {
  BUILD_QUERY_BUILD,
  BUILD_QUERY_VARIANT,
  buildDetailHref,
} from "./buildDetailHref";

describe("buildDetailHref", () => {
  it("links to build id only when multiple or no variants", () => {
    expect(buildDetailHref("b1")).toBe(`/build?${BUILD_QUERY_BUILD}=b1`);
    expect(buildDetailHref("b1", ["A", "B"])).toBe(
      `/build?${BUILD_QUERY_BUILD}=b1`,
    );
  });

  it("includes variant name when exactly one is provided", () => {
    const href = buildDetailHref("b1", ["Raid Night"]);
    const url = new URL(href, "http://local.test");
    expect(url.pathname).toBe("/build");
    expect(url.searchParams.get(BUILD_QUERY_BUILD)).toBe("b1");
    expect(url.searchParams.get(BUILD_QUERY_VARIANT)).toBe("Raid Night");
  });
});
