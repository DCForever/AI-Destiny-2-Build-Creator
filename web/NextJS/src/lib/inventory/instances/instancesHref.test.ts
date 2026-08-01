import { describe, expect, it } from "vitest";

import { buildInstancesHref } from "./instancesHref";

describe("instancesHref", () => {
  it("builds itemHash query path", () => {
    expect(buildInstancesHref(1363886209)).toBe(
      "/api/user/inventory/instances?itemHash=1363886209",
    );
  });
});
