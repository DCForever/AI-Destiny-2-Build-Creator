import { describe, expect, it } from "vitest";

import { InvalidLoadoutFilterError, parseLoadoutFilterQuery } from "./parseFilterQuery";

describe("parseLoadoutFilterQuery", () => {
  it("parses armor exact hash", () => {
    const params = new URLSearchParams("armorMode=exact&armorHash=2001");
    expect(parseLoadoutFilterQuery(params)).toEqual({
      armor: { mode: "exact", hash: 2001, name: undefined },
      weapon: undefined,
    });
  });

  it("parses armor exact name", () => {
    const params = new URLSearchParams("armorMode=exact&armorName=Crown%20of%20Tempests");
    expect(parseLoadoutFilterQuery(params).armor).toEqual({
      mode: "exact",
      name: "Crown of Tempests",
      hash: undefined,
    });
  });

  it("parses armor slot", () => {
    const params = new URLSearchParams("armorMode=slot&armorSlot=Helmet");
    expect(parseLoadoutFilterQuery(params).armor).toEqual({
      mode: "slot",
      slot: "Helmet",
    });
  });

  it("parses weapon filters", () => {
    const params = new URLSearchParams("weaponMode=slot&weaponSlot=Power");
    expect(parseLoadoutFilterQuery(params).weapon).toEqual({
      mode: "slot",
      slot: "Power",
    });
  });

  it("throws INVALID_FILTER when exact armor missing identity", () => {
    expect(() => parseLoadoutFilterQuery(new URLSearchParams("armorMode=exact"))).toThrow(
      InvalidLoadoutFilterError,
    );
  });

  it("throws INVALID_FILTER for bad slot", () => {
    expect(() =>
      parseLoadoutFilterQuery(new URLSearchParams("armorMode=slot&armorSlot=Bad")),
    ).toThrow(InvalidLoadoutFilterError);
  });
});
