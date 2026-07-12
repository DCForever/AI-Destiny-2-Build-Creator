import { describe, expect, it } from "vitest";

import { addPickedName, ignoreFreeTextList, removePickedName } from "./pickOnlyList";

describe("pickOnlyList", () => {
  it("adds a picked name once", () => {
    expect(addPickedName([], "Roaring Flames")).toEqual(["Roaring Flames"]);
    expect(addPickedName(["Roaring Flames"], "Roaring Flames")).toEqual(["Roaring Flames"]);
  });

  it("removes a picked name", () => {
    expect(removePickedName(["A", "B"], "A")).toEqual(["B"]);
  });

  it("ignores free-text identity edits", () => {
    expect(ignoreFreeTextList("A, B, Invented", ["Roaring Flames"])).toEqual(["Roaring Flames"]);
  });
});
