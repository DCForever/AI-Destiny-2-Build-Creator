import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/auth/requireUser";
import { isWeaponBucketLabel } from "@/lib/bungie/inventoryBuckets";
import { getDb } from "@/lib/db/client";
import { listInventoryItems } from "@/lib/db/repositories/inventoryRepository";
import { buildPlugMapForInventory } from "@/lib/inventory/instances/loadInstanceContext";
import { resolveInstancePerkGrid } from "@/lib/inventory/instances/resolveInstancePerkGrid";
import { loadWeaponSocketContext } from "@/lib/inventory/instances/weaponSocketContext";
import { weaponStatLines } from "@/lib/inventory/instances/weaponStats";
import { getServices } from "@/lib/services";

export const runtime = "nodejs";

function unauthorized() {
  return NextResponse.json({ error: "Not signed in" }, { status: 401 });
}

export async function GET(
  request: Request,
  context: { params: Promise<{ instanceId: string }> },
): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorized();

  const { instanceId } = await context.params;
  const db = getDb();
  const item = listInventoryItems(db, auth.user.id).find((row) => row.instanceId === instanceId);
  if (!item) {
    return NextResponse.json({ error: "Instance not found" }, { status: 404 });
  }

  if (!isWeaponBucketLabel(item.bucket)) {
    return NextResponse.json({ error: "Not a weapon" }, { status: 400 });
  }

  const plugHashes = [
    ...new Set([
      ...item.plugHashes,
      ...(item.socketPlugs?.flatMap((socket) => [
        socket.equippedPlugHash,
        ...socket.reusablePlugHashes,
      ]) ?? []),
    ]),
  ];

  const { entityCache, manifest } = await getServices();
  const manifestStatus = await manifest.getStatus();
  const version = manifestStatus.cachedVersion ?? "0";

  const [plugMap, plugCtx] = await Promise.all([
    buildPlugMapForInventory(entityCache, manifest, version, plugHashes),
    loadWeaponSocketContext(manifest, version, item.itemHash, plugHashes),
  ]);

  const grid = resolveInstancePerkGrid({
    item,
    plugMap,
    plugCategoryByHash: plugCtx.plugCategoryByHash,
    weaponPerkSocketIndexes: plugCtx.weaponPerkSocketIndexes,
  });

  const stats = weaponStatLines(item.statValues);
  const intrinsicColumn = grid.columns.find((c) => c.columnKind === "intrinsic");
  const intrinsic = intrinsicColumn?.options.find((o) => o.isEquipped) ??
    intrinsicColumn?.options[0] ??
    null;

  return NextResponse.json({
    ...grid,
    power: item.power,
    location: item.location,
    isMasterwork: item.isMasterwork,
    isCrafted: item.isCrafted,
    stats,
    intrinsic: intrinsic
      ? {
          name: intrinsic.displayName,
          description: intrinsic.description ?? "",
          icon: intrinsic.icon ?? null,
        }
      : null,
  });
}
