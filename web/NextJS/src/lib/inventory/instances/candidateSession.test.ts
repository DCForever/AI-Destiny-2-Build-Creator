import { describe, expect, it } from "vitest";

import {
  activeCandidate,
  candidateSessionReducer,
  openCandidateSession,
  visibleCandidates,
} from "./candidateSession";
import type { OwnedInstanceDetail } from "./types";

function candidate(instanceId: string, power = 1800): OwnedInstanceDetail {
  return {
    instanceId,
    itemHash: 123,
    kind: "armor",
    bucket: "Helmet",
    location: "vault",
    power,
    isMasterwork: false,
    isCrafted: false,
    rollTags: [],
    plugs: [],
    syncedAt: "2026-07-03T00:00:00.000Z",
  };
}

const copies = [candidate("a", 1810), candidate("b", 1805), candidate("c", 1800)];

describe("candidateSession reducer core", () => {
  it("open initializes the session with all copies visible and no selection", () => {
    const session = openCandidateSession(123, "armor", copies);
    expect(session.itemHash).toBe(123);
    expect(session.kind).toBe("armor");
    expect(visibleCandidates(session)).toHaveLength(3);
    expect(session.activeIndex).toBe(0);
    expect(session.selectedInstanceId).toBeNull();
    expect(activeCandidate(session)?.instanceId).toBe("a");
  });

  it("next/prev clamp within the visible range", () => {
    let session = openCandidateSession(123, "armor", copies);
    session = candidateSessionReducer(session, { type: "next" });
    expect(activeCandidate(session)?.instanceId).toBe("b");
    session = candidateSessionReducer(session, { type: "next" });
    session = candidateSessionReducer(session, { type: "next" });
    expect(activeCandidate(session)?.instanceId).toBe("c");
    session = candidateSessionReducer(session, { type: "prev" });
    session = candidateSessionReducer(session, { type: "prev" });
    session = candidateSessionReducer(session, { type: "prev" });
    expect(activeCandidate(session)?.instanceId).toBe("a");
  });

  it("select records a visible instance and ignores unknown ids", () => {
    let session = openCandidateSession(123, "armor", copies);
    session = candidateSessionReducer(session, { type: "select", instanceId: "b" });
    expect(session.selectedInstanceId).toBe("b");
    session = candidateSessionReducer(session, { type: "select", instanceId: "does-not-exist" });
    expect(session.selectedInstanceId).toBe("b");
  });

  it("open with an empty candidate list yields no visible candidates", () => {
    const session = openCandidateSession(123, "armor", []);
    expect(visibleCandidates(session)).toHaveLength(0);
    expect(activeCandidate(session)).toBeNull();
  });
});

describe("candidateSession remove/reset", () => {
  it("removes a candidate from the session without mutating the source list", () => {
    let session = openCandidateSession(123, "armor", copies);
    session = candidateSessionReducer(session, { type: "remove", instanceId: "b" });
    expect(visibleCandidates(session).map((c) => c.instanceId)).toEqual(["a", "c"]);
    expect(session.all).toHaveLength(3);
  });

  it("clears the selection when the selected candidate is removed", () => {
    let session = openCandidateSession(123, "armor", copies);
    session = candidateSessionReducer(session, { type: "select", instanceId: "b" });
    session = candidateSessionReducer(session, { type: "remove", instanceId: "b" });
    expect(session.selectedInstanceId).toBeNull();
  });

  it("keeps the selection when a different candidate is removed", () => {
    let session = openCandidateSession(123, "armor", copies);
    session = candidateSessionReducer(session, { type: "select", instanceId: "a" });
    session = candidateSessionReducer(session, { type: "remove", instanceId: "b" });
    expect(session.selectedInstanceId).toBe("a");
  });

  it("reset restores all removed candidates", () => {
    let session = openCandidateSession(123, "armor", copies);
    session = candidateSessionReducer(session, { type: "remove", instanceId: "a" });
    session = candidateSessionReducer(session, { type: "remove", instanceId: "b" });
    expect(visibleCandidates(session)).toHaveLength(1);
    session = candidateSessionReducer(session, { type: "reset" });
    expect(visibleCandidates(session)).toHaveLength(3);
  });

  it("clamps the active index after removals", () => {
    let session = openCandidateSession(123, "armor", copies);
    session = candidateSessionReducer(session, { type: "next" });
    session = candidateSessionReducer(session, { type: "next" });
    session = candidateSessionReducer(session, { type: "remove", instanceId: "c" });
    expect(activeCandidate(session)?.instanceId).toBe("b");
  });
});
