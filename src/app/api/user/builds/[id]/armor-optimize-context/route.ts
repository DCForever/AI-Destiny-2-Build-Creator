import { NextResponse } from "next/server";

import { requireAuthenticatedUser } from "@/lib/api/requireUser";
import { unauthorizedResponse } from "@/lib/api/response";
import { resolveDesignatedSynergies } from "@/lib/builds/resolveDesignatedSynergies";
import { getDb } from "@/lib/db/client";
import { getBuild } from "@/lib/db/repositories/buildRepository";
import {
  rankSetBonusesForBuild,
  type SetBonusCatalogEntry,
} from "@/lib/optimizer/rankSetBonusesForBuild";
import { composeOptimizerConstraints } from "@/lib/optimizer/composeOptimizerConstraints";
import { getServices } from "@/lib/services";

export const runtime = "nodejs";

type RouteContext = { params: Promise<{ id: string }> };

export async function GET(request: Request, context: RouteContext): Promise<NextResponse> {
  const auth = await requireAuthenticatedUser(request);
  if (!auth) return unauthorizedResponse();

  const { id: buildId } = await context.params;
  const url = new URL(request.url);
  const setId = url.searchParams.get("setId") ?? undefined;

  const db = getDb();
  const build = getBuild(db, auth.user.id, buildId);
  if (!build) {
    return NextResponse.json({ error: "Build not found" }, { status: 404 });
  }

  const bridge = resolveDesignatedSynergies(db, auth.user.id, build.synergyTypes ?? []);

  let catalog: SetBonusCatalogEntry[] = [];
  try {
    const { entityCache } = await getServices();
    const bonuses = await entityCache.getStore("set-bonuses");
    catalog = bonuses.map((b) => ({
      setBonusKey: String(b.hash),
      label: b.name,
      armorSetHash: b.hash,
      armorSetName: b.name,
    }));
  } catch {
    catalog = [];
  }

  const ranked = rankSetBonusesForBuild({
    matchedSynergies: bridge.matchedSynergies.map((s) => ({
      name: s.name,
      links: s.links.map((l) => ({
        kind: l.kind,
        displayName: l.displayName,
        armorSetHash: l.armorSetHash,
        armorSetName: l.armorSetName,
        bonusName: l.bonusName,
        bonusPieces: l.bonusPieces === 2 || l.bonusPieces === 4 ? l.bonusPieces : undefined,
      })),
    })),
    catalog,
  });

  const seedConstraints = composeOptimizerConstraints({
    seed: {
      exoticArmorHash: build.exoticArmorHash,
      softStatTargets: build.softStatTargets,
    },
  });

  return NextResponse.json({
    buildId,
    className: build.className,
    setId: setId ?? null,
    seedConstraints,
    rankedSetBonuses: ranked,
  });
}
