/** Short-lived in-memory OAuth CSRF states (dev-friendly across localhost/127.0.0.1). */
const pendingStates = new Map<string, number>();
const TTL_MS = 10 * 60 * 1000;

function pruneExpired(): void {
  const now = Date.now();
  for (const [state, created] of pendingStates) {
    if (now - created > TTL_MS) pendingStates.delete(state);
  }
}

export function storeOAuthState(state: string): void {
  pruneExpired();
  pendingStates.set(state, Date.now());
}

export function consumeOAuthState(state: string): boolean {
  pruneExpired();
  if (!pendingStates.has(state)) return false;
  pendingStates.delete(state);
  return true;
}
