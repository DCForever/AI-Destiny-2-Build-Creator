import { NextResponse } from "next/server";

import { resolveOwnedCatalogContext } from "@/app/api/catalog/_ownedFilter";
import { COMPOSITION_KINDS } from "@/lib/catalog/compositionKinds";
import { loadLegendaryArmorRows } from "@/lib/catalog/legendaryArmor";
import { searchCompositionCatalog } from "@/lib/catalog/universalSearch";
import { parseUniversalSearchQuery } from "@/lib/catalog/universalSearchSchema";
import { getDb } from "@/lib/db/client";
import { getServices } from "@/lib/services";

export const runtime = "nodejs";

function mergeOwnedHashes(
  a: Map<number, number>,
  b: Map<number, number>,
): Map<number, number> {
  const out = new Map(a);
  for (const [hash, count] of b) {
    out.set(hash, (out.get(hash) ?? 0) + count);
  }
  return out;
}

export async function GET(request: Request): Promise<NextResponse> {
  const url = new URL(request.url);
  const parsed = parseUniversalSearchQuery({
    q: url.searchParams.get("q") ?? undefined,
    kinds: url.searchParams.get("kinds") ?? undefined,
    limit: url.searchParams.get("limit") ?? undefined,
    includeOwned: url.searchParams.get("includeOwned") ?? undefined,
  });

  if (!parsed.ok) {
    return NextResponse.json({ error: parsed.error }, { status: 400 });
  }

  const { q, kinds, limit, includeOwned } = parsed.data;

  try {
    const { entityCache, manifest } = await getServices();
    const meta = await entityCache.getMeta();
    if (!meta) {
      return NextResponse.json(
        {
          error: "Manifest entity cache is not ready. Refresh the manifest and try again.",
          code: "MANIFEST_NOT_READY",
        },
        { status: 503 },
      );
    }

    let ownedHashes: Map<number, number> | undefined;
    const wantOwned = includeOwned !== "0";
    if (wantOwned) {
      const db = getDb();
      const [weaponsOwned, armorOwned] = await Promise.all([
        resolveOwnedCatalogContext(request, db, "weapons"),
        resolveOwnedCatalogContext(request, db, "armor"),
      ]);
      if (weaponsOwned || armorOwned) {
        ownedHashes = mergeOwnedHashes(
          weaponsOwned?.ownedHashes ?? new Map(),
          armorOwned?.ownedHashes ?? new Map(),
        );
      }
    }

    const kindsForSearch = kinds ?? [...COMPOSITION_KINDS];
    const needsLegendaryArmor = kindsForSearch.includes("armor");
    let legendaryArmor: Awaited<ReturnType<typeof loadLegendaryArmorRows>> | undefined;
    if (needsLegendaryArmor) {
      const manifestStatus = await manifest.getStatus();
      if (manifestStatus.cachedVersion) {
        const setBonuses = await entityCache.getStore("set-bonuses");
        legendaryArmor = await loadLegendaryArmorRows(
          setBonuses,
          manifest,
          manifestStatus.cachedVersion,
        );
      }
    }

    // Pass kinds only when the client filtered; omit → all kinds without FILTERED_EMPTY on miss.
    const result = await searchCompositionCatalog(
      (name) => entityCache.getStore(name),
      {
        q,
        ...(kinds !== undefined ? { kinds } : {}),
        limit,
        ownedHashes,
        legendaryArmor,
      },
    );

    return NextResponse.json({
      query: result.query,
      kinds: result.kinds,
      hits: result.hits,
      truncated: result.truncated,
      manifestReady: true,
      ...(result.code ? { code: result.code } : {}),
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Universal search failed";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
