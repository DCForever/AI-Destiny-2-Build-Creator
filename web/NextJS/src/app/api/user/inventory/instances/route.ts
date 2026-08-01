import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/auth/requireUser";
import { getDb } from "@/lib/db/client";
import { listInventoryItems } from "@/lib/db/repositories/inventoryRepository";
import { collectEquipmentPlugHashes } from "@/lib/inventory/instances/collectPlugHashes";
import { loadInstanceListContext } from "@/lib/inventory/instances/loadInstanceContext";
import { listUserInstances } from "@/lib/inventory/instances/listUserInstances";
import {
  buildInventorySearchNameMap,
  resolveCatalogItemSearchName,
} from "@/lib/inventory/instances/matchItemIdentity";
import {
  InvalidInstanceFilterError,
  parseInstanceFilterQuery,
} from "@/lib/inventory/instances/parseFilterQuery";
import { getServices } from "@/lib/services";

export const runtime = "nodejs";

function unauthorized() {
  return NextResponse.json({ error: "Not signed in" }, { status: 401 });
}

export async function GET(request: Request): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorized();

  let criteria;
  try {
    criteria = parseInstanceFilterQuery(new URL(request.url).searchParams);
  } catch (error) {
    if (error instanceof InvalidInstanceFilterError) {
      return NextResponse.json({ error: "INVALID_FILTER" }, { status: 400 });
    }
    throw error;
  }

  const db = getDb();
  const inventoryRows = listInventoryItems(db, auth.user.id);

  let itemIdentity:
    | {
        itemSearchName: string | null;
        inventorySearchNames: Map<number, string>;
      }
    | undefined;
  if (criteria.itemHash !== undefined) {
    const { entityCache, manifest } = await getServices();
    const manifestStatus = await manifest.getStatus();
    const itemSearchName = await resolveCatalogItemSearchName(
      criteria.itemHash,
      entityCache,
      manifest,
      manifestStatus.cachedVersion,
    );
    // Only map search names for inventory hashes (not full catalog) — same identity match.
    const inventoryHashes = inventoryRows.map((item) => item.itemHash);
    const inventorySearchNames = await buildInventorySearchNameMap(
      inventoryHashes,
      entityCache,
      manifest,
      manifestStatus.cachedVersion,
    );
    itemIdentity = { itemSearchName, inventorySearchNames };
  }

  // Scope plug presentation work to items that will appear in the response
  // (e.g. one weapon's copies) instead of every plug in the full vault.
  const rowsForPlugs =
    criteria.itemHash !== undefined
      ? inventoryRows.filter((item) => {
          if (item.itemHash === criteria.itemHash) return true;
          if (!itemIdentity?.itemSearchName) return false;
          return (
            itemIdentity.inventorySearchNames.get(item.itemHash) ===
            itemIdentity.itemSearchName
          );
        })
      : inventoryRows;
  const plugHashes = collectEquipmentPlugHashes(rowsForPlugs);
  const context = await loadInstanceListContext(auth, plugHashes);

  const body = listUserInstances({
    db,
    userId: auth.user.id,
    criteria,
    plugMap: context.plugMap,
    characterLabels: context.characterLabels,
    membershipDisplayName: context.membershipDisplayName,
    armorMeta: context.armorMeta,
    itemIdentity,
  });

  return NextResponse.json(body);
}
