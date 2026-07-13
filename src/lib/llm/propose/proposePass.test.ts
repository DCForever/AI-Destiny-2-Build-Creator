import { describe, expect, it, beforeEach } from "vitest";

import { createTestDb } from "@/lib/db/client";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { listSynergies } from "@/lib/db/repositories/synergyRepository";
import { clearProposePassStoreForTests } from "@/lib/llm/propose/proposalStore";
import { runProposePass } from "@/lib/llm/propose/runProposePass";
import { confirmProposals } from "@/lib/llm/propose/confirmProposals";

describe("llm propose-for-confirm", () => {
  beforeEach(() => {
    clearProposePassStoreForTests();
  });

  it("starts a mock pass without persisting synergies", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "llm1", 3, "G");
    const { passId, proposals } = await runProposePass("Solar scorch loop with Sunshot", {
      useMock: true,
    });
    expect(passId).toBeTruthy();
    expect(proposals.length).toBeGreaterThan(0);
    expect(listSynergies(db, user.id)).toHaveLength(0);
  });

  it("confirms one synergy and skips the rest", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "llm2", 3, "G");
    const { passId, proposals } = await runProposePass("descriptions", { useMock: true });
    const synergy = proposals.find((p) => p.kind === "synergy");
    expect(synergy).toBeTruthy();

    const result = await confirmProposals(
      db,
      user.id,
      passId,
      [synergy!.id],
      proposals.filter((p) => p.id !== synergy!.id).map((p) => p.id),
    );

    expect(result.created).toHaveLength(1);
    expect(result.created[0]?.synergyId).toBeTruthy();
    expect(listSynergies(db, user.id)).toHaveLength(1);
  });

  it("confirms from client proposals fallback when pass is missing", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "llm3", 3, "G");
    const { proposals } = await runProposePass("descriptions", { useMock: true });
    const synergy = proposals.find((p) => p.kind === "synergy");
    expect(synergy).toBeTruthy();

    clearProposePassStoreForTests();

    const result = await confirmProposals(
      db,
      user.id,
      "00000000-0000-0000-0000-000000000099",
      [synergy!.id],
      [],
      proposals,
    );

    expect(result.created).toHaveLength(1);
    expect(listSynergies(db, user.id)).toHaveLength(1);
  });
});
