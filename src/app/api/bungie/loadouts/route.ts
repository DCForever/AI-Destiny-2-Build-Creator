import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import type { BungieInGameLoadout } from "@/lib/bungie/characterLoadouts";
import { createBungieProfileClient } from "@/lib/bungie/profile";
import { fetchInGameLoadouts } from "@/lib/bungie/fetchInGameLoadouts";
import { getBungieOAuthConfig, getSessionSecret } from "@/lib/config/env";
import { getDb } from "@/lib/db/client";
import { listInventoryItems } from "@/lib/db/repositories/inventoryRepository";
import {
  buildExoticCatalogIndex,
  instanceHashMapFromInventory,
  resolveLoadoutExoticsFromInstances,
} from "@/lib/loadouts/resolveLoadoutExoticsFromInstances";
import { getServices } from "@/lib/services";

export const runtime = "nodejs";

const NOT_CONFIGURED = {
  error:
    "Bungie sign-in is not configured. Set BUNGIE_* and SESSION_SECRET in .env.local.",
};

/**
 * Live Bungie character loadouts (component 206) with icon/color resolved
 * from DestinyLoadout*Definition — same presentation path as DIM.
 * When inventory is synced, attaches exotic armor/weapon hashes for build matching.
 */
export async function GET(request: Request): Promise<NextResponse> {
  if (!getBungieOAuthConfig() || !getSessionSecret()) {
    return NextResponse.json(NOT_CONFIGURED, { status: 503 });
  }

  const auth = await requireAuthenticatedUser(request);
  if (!auth) {
    return NextResponse.json({ error: "Not signed in" }, { status: 401 });
  }

  const profileClient = createBungieProfileClient();
  if (!profileClient) {
    return NextResponse.json(NOT_CONFIGURED, { status: 503 });
  }

  try {
    const { manifest, entityCache } = await getServices();
    const result = await fetchInGameLoadouts({
      accessToken: auth.tokens.accessToken,
      profileClient,
      manifest,
    });

    const loadouts = await enrichLoadoutsWithExotics(
      result.loadouts,
      auth.user.id,
      entityCache,
    );

    return NextResponse.json({
      membershipDisplayName: result.membershipDisplayName,
      manifestVersion: result.manifestVersion,
      loadouts,
    });
  } catch (error) {
    const message =
      error instanceof Error ? error.message : "Failed to fetch Bungie loadouts";
    // Missing loadout presentation tables until next manifest refresh
    if (/Raw table|not on disk|ensureCurrent/i.test(message)) {
      return NextResponse.json(
        {
          error:
            "Loadout icon tables are not downloaded yet. Refresh the Destiny manifest from Settings, then try again.",
          detail: message,
        },
        { status: 503 },
      );
    }
    return NextResponse.json({ error: message }, { status: 502 });
  }
}

async function enrichLoadoutsWithExotics(
  loadouts: BungieInGameLoadout[],
  userId: number,
  entityCache: {
    getStore: (
      name: "exotic-armor" | "exotic-weapons",
    ) => Promise<Array<{ hash: number; name: string }>>;
  },
): Promise<BungieInGameLoadout[]> {
  if (loadouts.length === 0) return loadouts;

  try {
    const db = getDb();
    const inventory = listInventoryItems(db, userId);
    if (inventory.length === 0) {
      return loadouts.map((lo) => ({
        ...lo,
        exoticArmorHash: null,
        exoticWeaponHash: null,
        exoticArmorName: null,
        exoticWeaponName: null,
      }));
    }

    const [exoticArmor, exoticWeapons] = await Promise.all([
      entityCache.getStore("exotic-armor"),
      entityCache.getStore("exotic-weapons"),
    ]);
    const catalog = buildExoticCatalogIndex(exoticArmor, exoticWeapons);
    const instanceMap = instanceHashMapFromInventory(inventory);

    return loadouts.map((lo) => {
      const exo = resolveLoadoutExoticsFromInstances(
        lo.itemInstanceIds,
        instanceMap,
        catalog,
      );
      return {
        ...lo,
        exoticArmorHash: exo.exoticArmorHash,
        exoticWeaponHash: exo.exoticWeaponHash,
        exoticArmorName: exo.exoticArmorName,
        exoticWeaponName: exo.exoticWeaponName,
      };
    });
  } catch {
    return loadouts;
  }
}
