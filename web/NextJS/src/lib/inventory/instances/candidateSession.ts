import type { InstanceKind, OwnedInstanceDetail } from "./types";

/**
 * Ephemeral, client-only state for the disambiguation carousel. Pure and
 * DOM-free so it can be unit-tested in isolation (see spec US1/US5).
 */
export interface CandidateSession {
  itemHash: number;
  kind: InstanceKind;
  all: OwnedInstanceDetail[];
  removedInstanceIds: ReadonlySet<string>;
  activeIndex: number;
  selectedInstanceId: string | null;
}

export type CandidateAction =
  | { type: "select"; instanceId: string }
  | { type: "next" }
  | { type: "prev" }
  | { type: "remove"; instanceId: string }
  | { type: "reset" };

export function openCandidateSession(
  itemHash: number,
  kind: InstanceKind,
  all: OwnedInstanceDetail[],
): CandidateSession {
  return {
    itemHash,
    kind,
    all,
    removedInstanceIds: new Set<string>(),
    activeIndex: 0,
    selectedInstanceId: null,
  };
}

export function visibleCandidates(session: CandidateSession): OwnedInstanceDetail[] {
  return session.all.filter((candidate) => !session.removedInstanceIds.has(candidate.instanceId));
}

function clampIndex(index: number, length: number): number {
  if (length <= 0) return 0;
  if (index < 0) return 0;
  if (index > length - 1) return length - 1;
  return index;
}

export function activeCandidate(session: CandidateSession): OwnedInstanceDetail | null {
  const visible = visibleCandidates(session);
  if (visible.length === 0) return null;
  return visible[clampIndex(session.activeIndex, visible.length)] ?? null;
}

export function candidateSessionReducer(
  session: CandidateSession,
  action: CandidateAction,
): CandidateSession {
  const visibleLength = visibleCandidates(session).length;

  switch (action.type) {
    case "select": {
      const isVisible = visibleCandidates(session).some(
        (candidate) => candidate.instanceId === action.instanceId,
      );
      if (!isVisible) return session;
      return { ...session, selectedInstanceId: action.instanceId };
    }
    case "next":
      return { ...session, activeIndex: clampIndex(session.activeIndex + 1, visibleLength) };
    case "prev":
      return { ...session, activeIndex: clampIndex(session.activeIndex - 1, visibleLength) };
    case "remove": {
      const removedInstanceIds = new Set(session.removedInstanceIds);
      removedInstanceIds.add(action.instanceId);
      const nextVisibleLength = session.all.filter(
        (candidate) => !removedInstanceIds.has(candidate.instanceId),
      ).length;
      return {
        ...session,
        removedInstanceIds,
        activeIndex: clampIndex(session.activeIndex, nextVisibleLength),
        selectedInstanceId:
          session.selectedInstanceId === action.instanceId ? null : session.selectedInstanceId,
      };
    }
    case "reset":
      return { ...session, removedInstanceIds: new Set<string>() };
    default:
      return session;
  }
}
