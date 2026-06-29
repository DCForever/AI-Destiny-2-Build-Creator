import { describe, expect, it } from "vitest";

import {
  crownWarlockLoadout,
  hallowfireTitanLoadout,
  manifestStores,
  witherLoadout,
} from "./__fixtures__/loadoutFixtures";
import { buildDiscoveryMatches, buildFilteredLoadoutList } from "./loadoutListApi";

describe("loadoutListApi", () => {
  it("returns exotic summaries on each row", () => {
    const { loadouts, filter } = buildFilteredLoadoutList(
      [crownWarlockLoadout],
      {},
      manifestStores,
    );
    expect(filter.applied).toBe(false);
    expect(loadouts[0]?.exoticSummary.exoticArmor?.name).toBe("Crown of Tempests");
  });

  it("filters armor on server-shaped response", () => {
    const { loadouts, filter } = buildFilteredLoadoutList(
      [crownWarlockLoadout, hallowfireTitanLoadout],
      { armor: { mode: "slot", slot: "Helmet" } },
      manifestStores,
    );
    expect(filter.applied).toBe(true);
    expect(loadouts).toHaveLength(1);
    expect(loadouts[0]?.id).toBe("crown");
  });

  it("builds discovery overlay matches excluding current loadout", () => {
    const { loadouts } = buildFilteredLoadoutList(
      [crownWarlockLoadout, hallowfireTitanLoadout],
      {},
      manifestStores,
    );
    const matches = buildDiscoveryMatches(
      loadouts,
      { armor: { mode: "exact", hash: 2001 } },
      "crown",
    );
    expect(matches).toHaveLength(0);
  });

  it("builds discovery matches for weapon exact", () => {
    const { loadouts } = buildFilteredLoadoutList([witherLoadout, crownWarlockLoadout], {}, manifestStores);
    const matches = buildDiscoveryMatches(loadouts, {
      weapon: { mode: "exact", name: "Witherhoard" },
    });
    expect(matches.map((m) => m.id)).toEqual(["wither"]);
  });
});
