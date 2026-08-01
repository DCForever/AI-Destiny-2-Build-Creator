import { describe, expect, it } from "vitest";

import {
  isEmptyLoadoutItems,
  parseCharacterLoadoutsResponse,
  presentationTablesFromRaw,
  resolveLoadoutPresentation,
} from "./characterLoadouts";
import type { CharacterSummary } from "./types";

const characters: CharacterSummary[] = [
  {
    characterId: "char1",
    classType: "Titan",
    light: 2000,
    emblemPath: "/common/emblem.png",
    dateLastPlayed: "2026-01-01",
  },
];

const tables = presentationTablesFromRaw({
  icons: {
    "111": { iconImagePath: "/common/destiny2_content/icons/loadout_a.png" },
  },
  colors: {
    "222": { colorImagePath: "/common/destiny2_content/icons/color_a.png" },
  },
  names: {
    "333": { name: "Pyre Onslaught" },
  },
});

describe("resolveLoadoutPresentation", () => {
  it("maps hashes to CDN URLs and names", () => {
    const p = resolveLoadoutPresentation(
      { iconHash: 111, colorHash: 222, nameHash: 333 },
      tables,
      "Fallback",
    );
    expect(p.name).toBe("Pyre Onslaught");
    expect(p.iconUrl).toBe(
      "https://www.bungie.net/common/destiny2_content/icons/loadout_a.png",
    );
    expect(p.colorUrl).toBe(
      "https://www.bungie.net/common/destiny2_content/icons/color_a.png",
    );
  });

  it("uses fallback name when nameHash unknown", () => {
    const p = resolveLoadoutPresentation(
      { iconHash: 0, colorHash: 0, nameHash: 0 },
      tables,
      "Loadout 2",
    );
    expect(p.name).toBe("Loadout 2");
    expect(p.iconUrl).toBeNull();
  });
});

describe("isEmptyLoadoutItems", () => {
  it("treats zero instance ids as empty", () => {
    expect(isEmptyLoadoutItems([])).toBe(true);
    expect(isEmptyLoadoutItems([{ itemInstanceId: "0" }])).toBe(true);
    expect(isEmptyLoadoutItems([{ itemInstanceId: "123" }])).toBe(false);
  });
});

describe("parseCharacterLoadoutsResponse", () => {
  it("parses component 206 characterLoadouts data", () => {
    const response = {
      characterLoadouts: {
        data: {
          char1: {
            loadouts: [
              {
                iconHash: 111,
                colorHash: 222,
                nameHash: 333,
                items: [
                  { itemInstanceId: "999", plugItemHashes: [] },
                  { itemInstanceId: "0", plugItemHashes: [] },
                ],
              },
              {
                iconHash: 0,
                colorHash: 0,
                nameHash: 0,
                items: [],
              },
            ],
          },
        },
      },
    };

    const list = parseCharacterLoadoutsResponse(response, characters, tables);
    expect(list).toHaveLength(2);
    expect(list[0]?.id).toBe("char1:0");
    expect(list[0]?.name).toBe("Pyre Onslaught");
    expect(list[0]?.iconUrl).toContain("loadout_a.png");
    expect(list[0]?.empty).toBe(false);
    expect(list[0]?.itemInstanceIds).toEqual(["999"]);
    expect(list[1]?.name).toBe("Loadout 2");
    expect(list[1]?.empty).toBe(true);
  });
});
