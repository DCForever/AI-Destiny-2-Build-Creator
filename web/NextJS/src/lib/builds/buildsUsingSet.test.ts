import { describe, expect, it } from "vitest";

import { buildsUsingSet } from "./buildsUsingSet";

describe("buildsUsingSet", () => {
  const builds = [
    {
      id: "b1",
      name: "Pyre",
      variants: [
        {
          id: "v1",
          name: "Default",
          attachments: [{ setId: "set-a" }, { setId: "set-b" }],
        },
        {
          id: "v2",
          name: "GM",
          attachments: [{ setId: "set-a" }],
        },
      ],
    },
    {
      id: "b2",
      name: "Void Anchor",
      variants: [
        {
          id: "v3",
          name: "Default",
          attachments: [{ setId: "set-b" }],
        },
      ],
    },
    {
      id: "b3",
      name: "Unused",
      variants: [{ id: "v4", name: "Default", attachments: [] }],
    },
  ];

  it("lists builds and variant names that attach the set", () => {
    const used = buildsUsingSet("set-a", builds);
    expect(used).toEqual([
      {
        buildId: "b1",
        buildName: "Pyre",
        variantNames: ["Default", "GM"],
      },
    ]);
  });

  it("returns empty when no build uses the set", () => {
    expect(buildsUsingSet("set-z", builds)).toEqual([]);
  });

  it("sorts by build name", () => {
    const used = buildsUsingSet("set-b", builds);
    expect(used.map((u) => u.buildName)).toEqual(["Pyre", "Void Anchor"]);
  });
});
