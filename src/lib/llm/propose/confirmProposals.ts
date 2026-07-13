import type { AppDatabase } from "@/lib/db/client";
import {
  getProposePass,
  saveProposePass,
} from "@/lib/llm/propose/proposalStore";
import type { Proposal } from "@/lib/llm/propose/proposalSchemas";
import { createUserSynergy } from "@/lib/synergies/synergyService";
import { API_ERROR_CODES, ApiError } from "@/lib/api/errors";

export type ConfirmResult = {
  created: Array<{ proposalId: string; synergyId: string }>;
  skipped: string[];
  ignoredKeywords: string[];
};

export async function confirmProposals(
  db: AppDatabase,
  userId: number,
  passId: string,
  acceptedIds: string[],
  skippedIds: string[] = [],
  /** Client-held proposals when the server pass map no longer has this id. */
  proposalsFallback?: Proposal[],
): Promise<ConfirmResult> {
  let pass = getProposePass(passId);
  if (!pass && proposalsFallback && proposalsFallback.length > 0) {
    // Recover from lost in-memory pass (HMR / restart) using the scan response body.
    pass = {
      passId,
      createdAt: new Date().toISOString(),
      proposals: proposalsFallback,
    };
    saveProposePass(pass);
  }
  if (!pass) {
    throw new ApiError(
      API_ERROR_CODES.INVALID_ITEM,
      `Unknown propose pass ${passId}. Re-run the scan and confirm without refreshing or restarting the server.`,
      undefined,
      404,
    );
  }

  const byId = new Map(pass.proposals.map((p) => [p.id, p]));
  const created: ConfirmResult["created"] = [];
  const ignoredKeywords: string[] = [];
  const skipped = [...skippedIds];

  for (const id of acceptedIds) {
    const proposal = byId.get(id);
    if (!proposal) continue;
    if (proposal.kind === "synergy" && proposal.synergy) {
      const synergy = await createUserSynergy(db, userId, proposal.synergy);
      created.push({ proposalId: id, synergyId: synergy.id });
      continue;
    }
    if (proposal.kind === "keyword") {
      // v1: no personal-keyword table — accept acknowledges but does not persist alone
      ignoredKeywords.push(id);
      continue;
    }
    if (proposal.kind === "evidence") {
      // evidence alone needs a target synergy; skip persist in v1
      ignoredKeywords.push(id);
    }
  }

  return { created, skipped, ignoredKeywords };
}

export function listPassProposals(passId: string): Proposal[] | null {
  return getProposePass(passId)?.proposals ?? null;
}
