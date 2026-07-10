import type { Proposal } from "@/lib/llm/propose/proposalSchemas";

export type StoredProposePass = {
  passId: string;
  createdAt: string;
  proposals: Proposal[];
};

const STORE = new Map<string, StoredProposePass>();
const TTL_MS = 60 * 60 * 1000;

export function clearProposePassStoreForTests(): void {
  STORE.clear();
}

function prune(now = Date.now()): void {
  for (const [id, pass] of STORE) {
    if (now - Date.parse(pass.createdAt) > TTL_MS) STORE.delete(id);
  }
}

export function saveProposePass(pass: StoredProposePass): void {
  prune();
  STORE.set(pass.passId, pass);
}

export function getProposePass(passId: string): StoredProposePass | null {
  prune();
  return STORE.get(passId) ?? null;
}
