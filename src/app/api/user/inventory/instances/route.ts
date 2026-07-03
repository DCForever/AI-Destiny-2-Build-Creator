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
  const plugHashes = collectEquipmentPlugHashes(inventoryRows);
  const context = await loadInstanceListContext(auth, plugHashes);

  let itemIdentity:
    | {
        itemSearchName: string | null;
        inventorySearchNames: Map<number, string>;
      }
    | undefined;
  let itemSearchName: string | null = null;
  if (criteria.itemHash !== undefined) {
    const { entityCache, manifest } = await getServices();
    const manifestStatus = await manifest.getStatus();
    itemSearchName = await resolveCatalogItemSearchName(
      criteria.itemHash,
      entityCache,
      manifest,
      manifestStatus.cachedVersion,
    );
    const inventoryHashes = listInventoryItems(db, auth.user.id).map((item) => item.itemHash);
    const inventorySearchNames = await buildInventorySearchNameMap(
      inventoryHashes,
      entityCache,
      manifest,
      manifestStatus.cachedVersion,
    );
    itemIdentity = { itemSearchName, inventorySearchNames };
  }

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
