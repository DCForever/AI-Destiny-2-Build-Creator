import { describe, expect, it, beforeEach } from "vitest";

import { createTestDb } from "@/lib/db/client";
import { ensureUser } from "@/lib/db/repositories/userRepository";
import { listSynergies } from "@/lib/db/repositories/synergyRepository";
import { ApiError } from "@/lib/api/errors";
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
      userId: user.id,
    });
    expect(passId).toBeTruthy();
    expect(proposals.length).toBeGreaterThan(0);
    expect(listSynergies(db, user.id)).toHaveLength(0);
  });

  it("confirms one synergy and skips the rest", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "llm2", 3, "G");
    const { passId, proposals } = await runProposePass("descriptions", {
      useMock: true,
      userId: user.id,
    });
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

  it("rejects missing pass without creating synergies even if client holds proposals", async () => {
    const db = createTestDb();
    const user = ensureUser(db, "llm3", 3, "G");
    const { proposals } = await runProposePass("descriptions", {
      useMock: true,
      userId: user.id,
    });
    const synergy = proposals.find((p) => p.kind === "synergy");
    expect(synergy).toBeTruthy();
    // Malicious client still has proposal bodies, but the server pass is gone.
    expect(proposals.length).toBeGreaterThan(0);

    clearProposePassStoreForTests();

    await expect(
      confirmProposals(
        db,
        user.id,
        "00000000-0000-0000-0000-000000000099",
        [synergy!.id],
        [],
      ),
    ).rejects.toMatchObject({
      status: 404,
      message: expect.stringMatching(/Unknown propose pass|Re-run the scan/i),
    } satisfies Partial<ApiError>);

    expect(listSynergies(db, user.id)).toHaveLength(0);
  });

  it("rejects confirm when pass belongs to another user", async () => {
    const db = createTestDb();
    const owner = ensureUser(db, "llm-owner", 3, "G");
    const other = ensureUser(db, "llm-other", 3, "G");
    const { passId, proposals } = await runProposePass("descriptions", {
      useMock: true,
      userId: owner.id,
    });
    const synergy = proposals.find((p) => p.kind === "synergy");
    expect(synergy).toBeTruthy();

    await expect(
      confirmProposals(db, other.id, passId, [synergy!.id], []),
    ).rejects.toMatchObject({ status: 404 });

    expect(listSynergies(db, owner.id)).toHaveLength(0);
    expect(listSynergies(db, other.id)).toHaveLength(0);
  });
});
