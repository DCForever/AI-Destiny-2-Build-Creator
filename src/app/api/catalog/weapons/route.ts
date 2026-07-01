import { NextResponse } from "next/server";
import { z } from "zod";

import { resolveOwnedCatalogContext } from "@/app/api/catalog/_ownedFilter";
import { emptyFilterMessage } from "@/lib/catalog/emptyFilterResult";
import { filterWeaponCatalog } from "@/lib/catalog/filterItems";
import { resolveInventoryHashProjections } from "@/lib/catalog/inventoryHashProjections";
import {
  combineWeaponAllowlists,
  resolveOriginTraitFilter,
  resolvePerkFilter,
} from "@/lib/catalog/perkTraitFilters";
import { attachInstancePointers } from "@/lib/inventory/instances/catalogPointer";
import { loadPerkWeaponIndex } from "@/lib/manifest/perkWeaponIndex";
import { getDb } from "@/lib/db/client";
import { getServices } from "@/lib/services";

export const runtime = "nodejs";

const querySchema = z.object({
  scope: z.enum(["all", "owned"]).default("all"),
  q: z.string().trim().optional(),
  slot: z.enum(["Kinetic", "Energy", "Power"]).optional(),
  itemType: z.string().trim().optional(),
  frame: z.string().trim().optional(),
  perk: z.string().trim().optional(),
  originTrait: z.string().trim().optional(),
  limit: z.coerce.number().int().min(1).max(500).default(100),
  includeInstancePointer: z.enum(["0", "1"]).optional(),
});

export async function GET(request: Request): Promise<NextResponse> {
  const url = new URL(request.url);
  const parsed = querySchema.safeParse({
    scope: url.searchParams.get("scope") ?? "all",
    q: url.searchParams.get("q") ?? undefined,
    itemType: url.searchParams.get("itemType") ?? undefined,
    frame: url.searchParams.get("frame") ?? undefined,
    slot: url.searchParams.get("slot") ?? undefined,
    perk: url.searchParams.get("perk") ?? undefined,
    originTrait: url.searchParams.get("originTrait") ?? undefined,
    limit: url.searchParams.get("limit") ?? "100",
    includeInstancePointer: url.searchParams.get("includeInstancePointer") ?? undefined,
  });

  if (!parsed.success) {
    return NextResponse.json(
      { error: parsed.error.issues.map((i) => i.message).join("; ") },
      { status: 400 },
    );
  }

  const db = getDb();
  let ownedHashes = new Map<number, number>();
  let syncPrompt = false;

  const ownedContext = await resolveOwnedCatalogContext(request, db, "weapons");

  if (parsed.data.scope === "owned") {
    if (!ownedContext) {
      return NextResponse.json({
        items: [],
        syncPrompt: true,
        message: "Sign in and sync inventory for owned weapons",
      });
    }
    ownedHashes = ownedContext.ownedHashes;
    syncPrompt = ownedContext.syncPrompt;
  } else if (ownedContext) {
    ownedHashes = ownedContext.ownedHashes;
  }

  try {
    const { entityCache, manifest } = await getServices();
    const manifestStatus = await manifest.getStatus();
    const [weapons, exoticWeapons, weaponPerks, originTraits] = await Promise.all([
      entityCache.getStore("weapons"),
      entityCache.getStore("exotic-weapons"),
      entityCache.getStore("weapon-perks"),
      entityCache.getStore("origin-traits"),
    ]);

    let weaponHashAllowlist: Set<number> | undefined;
    let filterMessage: string | null = null;

    if (parsed.data.perk?.trim() || parsed.data.originTrait?.trim()) {
      const perkIndex =
        parsed.data.perk?.trim() && manifestStatus.cachedVersion
          ? await loadPerkWeaponIndex(manifestStatus.cachedVersion)
          : null;

      const perkResolution = parsed.data.perk?.trim()
        ? resolvePerkFilter(parsed.data.perk, weaponPerks, perkIndex)
        : null;
      const traitResolution = parsed.data.originTrait?.trim()
        ? resolveOriginTraitFilter(parsed.data.originTrait, originTraits, weapons)
        : null;

      if (perkResolution && !perkResolution.ok) {
        filterMessage = emptyFilterMessage({ perk: parsed.data.perk });
      } else if (traitResolution && !traitResolution.ok) {
        filterMessage = emptyFilterMessage({ originTrait: parsed.data.originTrait });
      } else {
        weaponHashAllowlist = combineWeaponAllowlists(
          perkResolution?.ok ? perkResolution.weaponHashes : undefined,
          traitResolution?.ok ? traitResolution.weaponHashes : undefined,
        );
        if (weaponHashAllowlist && weaponHashAllowlist.size === 0) {
          filterMessage =
            emptyFilterMessage({
              perk: parsed.data.perk,
              originTrait: parsed.data.originTrait,
            }) ?? "No matching weapons";
        }
      }
    }

    if (filterMessage) {
      return NextResponse.json({
        items: [],
        count: 0,
        scope: parsed.data.scope,
        syncPrompt: parsed.data.scope === "owned" ? syncPrompt : false,
        message: filterMessage,
      });
    }

    const storeHashes = new Set([...weapons, ...exoticWeapons].map((weapon) => weapon.hash));
    const unknownOwnedHashes = [...ownedHashes.keys()].filter((hash) => !storeHashes.has(hash));
    const inventoryProjections =
      unknownOwnedHashes.length > 0 && manifestStatus.cachedVersion
        ? await resolveInventoryHashProjections(
            manifest,
            manifestStatus.cachedVersion,
            unknownOwnedHashes,
          )
        : new Map();

    const filtered = filterWeaponCatalog(
      { weapons, exoticWeapons },
      {
        ...parsed.data,
        ownedHashes,
        inventoryProjections,
        weaponHashAllowlist,
      },
    );

    const includePointer =
      parsed.data.scope === "owned" && parsed.data.includeInstancePointer === "1";
    const items = attachInstancePointers(filtered, includePointer);

    return NextResponse.json({
      items,
      count: items.length,
      scope: parsed.data.scope,
      syncPrompt: parsed.data.scope === "owned" ? syncPrompt : false,
    });
  } catch (error) {
    const message = error instanceof Error ? error.message : "Catalog filter failed";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
