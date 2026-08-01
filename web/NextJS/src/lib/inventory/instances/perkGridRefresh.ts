export interface PerkGridRefreshState {
  syncAttemptedFor: Set<string>;
  inFlight: boolean;
}

export function createPerkGridRefreshState(): PerkGridRefreshState {
  return { syncAttemptedFor: new Set(), inFlight: false };
}

export function shouldAutoSync(state: PerkGridRefreshState, instanceId: string): boolean {
  if (state.inFlight) return false;
  return !state.syncAttemptedFor.has(instanceId);
}

export function markSyncAttempted(state: PerkGridRefreshState, instanceId: string): PerkGridRefreshState {
  const next = new Set(state.syncAttemptedFor);
  next.add(instanceId);
  return { ...state, syncAttemptedFor: next, inFlight: true };
}

export function markSyncFinished(state: PerkGridRefreshState): PerkGridRefreshState {
  return { ...state, inFlight: false };
}
