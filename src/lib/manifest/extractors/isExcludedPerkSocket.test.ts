import { describe, expect, it } from "vitest";

import { isExcludedPerkSocket } from "./common";
import type { RawTable } from "../types/services";
import type { RawSocketEntry } from "./rawTypes";

function tableWithPlugs(
  plugs: Record<
    number,
    { cat: string; typeName?: string }
  >,
): RawTable {
  const table: RawTable = {};
  for (const [hash, p] of Object.entries(plugs)) {
    table[hash] = {
      hash: Number(hash),
      displayProperties: { name: "p", description: "" },
      itemTypeDisplayName: p.typeName ?? "",
      plug: { plugCategoryIdentifier: p.cat },
    };
  }
  return table;
}

describe("isExcludedPerkSocket", () => {
  it("keeps trait plugs that use frames category (Arc Alignment / Voltshot)", () => {
    const itemTable = tableWithPlugs({
      2174503023: { cat: "frames", typeName: "Trait" },
    });
    const socket: RawSocketEntry = { singleInitialItemHash: 2174503023 };
    expect(isExcludedPerkSocket(socket, itemTable)).toBe(false);
  });

  it("excludes Intrinsic frame plugs (Precision Frame)", () => {
    const itemTable = tableWithPlugs({
      1008: { cat: "frames", typeName: "Intrinsic" },
    });
    const socket: RawSocketEntry = { singleInitialItemHash: 1008 };
    expect(isExcludedPerkSocket(socket, itemTable)).toBe(true);
  });

  it("excludes true intrinsic sockets", () => {
    const itemTable = tableWithPlugs({
      3505: { cat: "intrinsics", typeName: "Intrinsic" },
    });
    const socket: RawSocketEntry = { singleInitialItemHash: 3505 };
    expect(isExcludedPerkSocket(socket, itemTable)).toBe(true);
  });
});
