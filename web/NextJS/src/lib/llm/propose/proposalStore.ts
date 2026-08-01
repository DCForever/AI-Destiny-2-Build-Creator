import type { Proposal } from "@/lib/llm/propose/proposalSchemas";

export type StoredProposePass = {
  passId: string;
  createdAt: string;
  proposals: Proposal[];
  /** Authenticated user that created the pass; confirm must match when set. */
  userId?: number;
};

/**
 * In-memory propose-pass store. Bound to globalThis so Next.js HMR and
 * route-module re-evaluation do not drop passes mid-session (which caused
 * "Unknown propose pass <uuid>" on confirm after a gap scan).
 */
const globalForPropose = globalThis as typeof globalThis & {
  __destinyProposePassStore?: Map<string, StoredProposePass>;
};

function store(): Map<string, StoredProposePass> {
  if (!globalForPropose.__destinyProposePassStore) {
    globalForPropose.__destinyProposePassStore = new Map();
  }
  return globalForPropose.__destinyProposePassStore;
}

const TTL_MS = 60 * 60 * 1000;

export function clearProposePassStoreForTests(): void {
  store().clear();
}

function prune(now = Date.now()): void {
  for (const [id, pass] of store()) {
    if (now - Date.parse(pass.createdAt) > TTL_MS) store().delete(id);
  }
}

export function saveProposePass(pass: StoredProposePass): void {
  prune();
  store().set(pass.passId, pass);
}

export function getProposePass(passId: string): StoredProposePass | null {
  prune();
  return store().get(passId) ?? null;
}
