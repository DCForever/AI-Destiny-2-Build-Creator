"use client";

import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";

import { SynergyDetail } from "@/components/synergy/SynergyDetail";
import { SynergyEditPanel } from "@/components/synergy/SynergyEditPanel";
import { SynergyFilters } from "@/components/synergy/SynergyFilters";
import { SynergyLibrary } from "@/components/synergy/SynergyLibrary";
import type {
  SynergyDetail as SynergyDetailType,
  SynergySummary,
} from "@/components/synergy/types";
import {
  Badge,
  Button,
  Callout,
  EmptyState,
  PageFrame,
  PageFrameBody,
  PageFrameChrome,
  PageHeader,
  Panel,
  Row,
  SignedOutGate,
  Stack,
  Text,
  Workspace,
  WorkspaceMain,
} from "@/components/ui";
import { formatSynergyTypeDesignation } from "@/lib/synergies/generateSynergyName";
import { filterSynergies } from "@/lib/synergies/filterSynergies";
import { sameSynergyDesignation } from "@/lib/synergies/mergeSynergies";
import { sortByName } from "@/lib/sortByName";

/**
 * Synergy screen composition (board-first).
 *
 * Layout slots:
 *   PageHeader (title only)
 *   Instrument strip → SynergyFilters (search always; facets collapsed)
 *   Workspace
 *     rail  → SynergyLibrary (hygiene mode lives here)
 *     main  → SynergyEditPanel | SynergyDetail | loading | EmptyState
 */
export function SynergyPage() {
  const [signedIn, setSignedIn] = useState<boolean | null>(null);
  const [rows, setRows] = useState<SynergySummary[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [detail, setDetail] = useState<SynergyDetailType | null>(null);
  /** When set, main is loading this id; never show another row's detail. */
  const [detailPendingId, setDetailPendingId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [typeFilter, setTypeFilter] = useState<string[]>([]);
  const [subTypeFilter, setSubTypeFilter] = useState<string[]>([]);
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState(false);
  const [deleteBusy, setDeleteBusy] = useState(false);
  const [checkedIds, setCheckedIds] = useState<Set<string>>(() => new Set());
  /** Explicit merge survivor — only valid when id is in checkedIds. */
  const [survivorId, setSurvivorId] = useState<string | null>(null);
  const [hygieneMode, setHygieneMode] = useState(false);
  const [mergeConfirmOpen, setMergeConfirmOpen] = useState(false);
  const [mergeBusy, setMergeBusy] = useState(false);
  const [duplicateBusy, setDuplicateBusy] = useState(false);
  const [deleteConfirmOpen, setDeleteConfirmOpen] = useState(false);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);

  /** Monotonic token so slower loadDetail responses cannot overwrite newer selection. */
  const detailRequestSeq = useRef(0);

  const loadList = useCallback(async () => {
    const res = await fetch("/api/user/synergies");
    if (res.status === 401) {
      setSignedIn(false);
      setRows([]);
      return false;
    }
    if (!res.ok) {
      const body = (await res.json()) as { error?: string };
      setError(body.error ?? "Failed to load synergies");
      return false;
    }
    setSignedIn(true);
    const body = (await res.json()) as { synergies: SynergySummary[] };
    setRows(sortByName(body.synergies ?? []));
    return true;
  }, []);

  const loadDetail = useCallback(async (id: string) => {
    const seq = ++detailRequestSeq.current;
    setError(null);
    setDetailPendingId(id);
    // Drop stale pane immediately so Edit/Delete never target the previous row.
    setDetail((prev) => (prev?.id === id ? prev : null));
    try {
      const res = await fetch(`/api/user/synergies/${id}`);
      if (seq !== detailRequestSeq.current) return;
      if (!res.ok) {
        const body = (await res.json()) as { error?: string };
        setError(body.error ?? "Failed to load synergy");
        setDetail(null);
        setDetailPendingId(null);
        return;
      }
      const body = (await res.json()) as { synergy: SynergyDetailType };
      if (seq !== detailRequestSeq.current) return;
      if (body.synergy?.id !== id) {
        setError("Loaded synergy did not match the selection.");
        setDetail(null);
        setDetailPendingId(null);
        return;
      }
      setDetail(body.synergy);
      setDetailPendingId(null);
    } catch {
      if (seq !== detailRequestSeq.current) return;
      setError("Failed to load synergy");
      setDetail(null);
      setDetailPendingId(null);
    }
  }, []);

  useEffect(() => {
    void (async () => {
      setLoading(true);
      await loadList();
      setLoading(false);
    })();
  }, [loadList]);

  const filtered = useMemo(
    () =>
      filterSynergies(rows, {
        query,
        types: typeFilter,
        subTypes: subTypeFilter,
      }),
    [rows, query, typeFilter, subTypeFilter],
  );

  const mergeState = useMemo(() => {
    const checked = rows.filter((r) => checkedIds.has(r.id));
    if (checked.length < 2) {
      return {
        enabled: false,
        reason:
          checked.length === 0
            ? "Check two or more synergies to merge."
            : "Check at least one more synergy to merge.",
        survivorId: null as string | null,
        sourceIds: [] as string[],
        survivor: null as SynergySummary | null,
        sources: [] as SynergySummary[],
      };
    }
    const survivor =
      survivorId && checkedIds.has(survivorId)
        ? (rows.find((r) => r.id === survivorId) ?? null)
        : null;
    if (!survivor) {
      return {
        enabled: false,
        reason: "Choose which checked designation survives the merge.",
        survivorId: null as string | null,
        sourceIds: [] as string[],
        survivor: null as SynergySummary | null,
        sources: [] as SynergySummary[],
      };
    }
    const sources = checked.filter((r) => r.id !== survivor.id);
    const same = sources.every((s) => sameSynergyDesignation(survivor, s));
    if (!same) {
      return {
        enabled: false,
        reason:
          "Checked rows must share the same type and subtype (e.g. all Verb: Scorch).",
        survivorId: survivor.id,
        sourceIds: sources.map((s) => s.id),
        survivor,
        sources,
      };
    }
    return {
      enabled: true,
      reason: null as string | null,
      survivorId: survivor.id,
      sourceIds: sources.map((s) => s.id),
      survivor,
      sources,
    };
  }, [rows, checkedIds, survivorId]);

  function clearMergeSelection() {
    setCheckedIds(new Set());
    setSurvivorId(null);
    setMergeConfirmOpen(false);
  }

  function setHygieneModeNext(next: boolean) {
    setHygieneMode(next);
    if (!next) clearMergeSelection();
  }

  function toggleCheck(id: string) {
    setCheckedIds((prev) => {
      const next = new Set(prev);
      if (next.has(id)) {
        next.delete(id);
        setSurvivorId((cur) => (cur === id ? null : cur));
      } else {
        next.add(id);
        setSurvivorId((cur) => (cur && next.has(cur) ? cur : id));
      }
      return next;
    });
    setMergeConfirmOpen(false);
  }

  function clearSelection() {
    detailRequestSeq.current += 1;
    setCreating(false);
    setEditing(false);
    setSelectedId(null);
    setDetail(null);
    setDetailPendingId(null);
    setDeleteConfirmOpen(false);
  }

  function selectRow(id: string) {
    setCreating(false);
    setEditing(false);
    setDeleteConfirmOpen(false);
    setSelectedId(id);
    void loadDetail(id);
  }

  async function handleDuplicate() {
    const sourceId =
      selectedId ??
      (checkedIds.size === 1 ? [...checkedIds][0]! : null);
    if (!sourceId) {
      setError("Select a synergy to duplicate.");
      return;
    }
    setDuplicateBusy(true);
    setError(null);
    setStatusMessage(null);
    try {
      const res = await fetch(`/api/user/synergies/${sourceId}/duplicate`, {
        method: "POST",
      });
      const body = (await res.json()) as {
        error?: string;
        synergy?: SynergyDetailType;
      };
      if (!res.ok || !body.synergy) {
        setError(body.error ?? "Failed to duplicate synergy");
        return;
      }
      detailRequestSeq.current += 1;
      setRows((prev) => sortByName([...prev, body.synergy!]));
      setSelectedId(body.synergy.id);
      setDetail(body.synergy);
      setDetailPendingId(null);
      clearMergeSelection();
      setCreating(false);
      setEditing(true);
      setStatusMessage(
        `Duplicated ${formatSynergyTypeDesignation({
          type: body.synergy.type,
          subType: body.synergy.subType,
        })} — edit the copy.`,
      );
    } catch {
      setError("Failed to duplicate synergy");
    } finally {
      setDuplicateBusy(false);
    }
  }

  function requestMerge() {
    if (!mergeState.enabled || !mergeState.survivorId) return;
    setError(null);
    setMergeConfirmOpen(true);
  }

  async function confirmMerge() {
    if (!mergeState.enabled || !mergeState.survivorId) return;
    setMergeBusy(true);
    setError(null);
    try {
      const res = await fetch("/api/user/synergies/merge", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          survivorId: mergeState.survivorId,
          sourceIds: mergeState.sourceIds,
        }),
      });
      const body = (await res.json()) as {
        error?: string;
        synergy?: SynergyDetailType;
        deletedIds?: string[];
      };
      if (!res.ok) {
        setError(body.error ?? "Failed to merge synergies");
        return;
      }
      const deleted = new Set(body.deletedIds ?? mergeState.sourceIds);
      setRows((prev) => {
        const without = prev.filter((r) => !deleted.has(r.id));
        if (!body.synergy) return sortByName(without);
        return sortByName(
          without.map((r) => (r.id === body.synergy!.id ? body.synergy! : r)),
        );
      });
      clearMergeSelection();
      setCreating(false);
      setEditing(false);
      const nextId = body.synergy?.id ?? mergeState.survivorId;
      setSelectedId(nextId);
      if (body.synergy) {
        detailRequestSeq.current += 1;
        setDetail(body.synergy);
        setDetailPendingId(null);
      } else {
        void loadDetail(mergeState.survivorId);
      }
    } catch {
      setError("Failed to merge synergies");
    } finally {
      setMergeBusy(false);
    }
  }

  function requestDelete() {
    // Only delete the designation currently shown (never a pending/stale row).
    if (!detail || detailPendingId || detail.id !== selectedId) return;
    setError(null);
    setDeleteConfirmOpen(true);
  }

  async function confirmDelete() {
    if (!detail || detailPendingId || detail.id !== selectedId) return;
    setDeleteBusy(true);
    setError(null);
    try {
      const res = await fetch(`/api/user/synergies/${detail.id}`, {
        method: "DELETE",
      });
      const body = (await res.json()) as { error?: string };
      if (!res.ok) {
        setError(body.error ?? "Failed to delete synergy");
        return;
      }
      setRows((prev) => prev.filter((r) => r.id !== detail.id));
      setCheckedIds((prev) => {
        const next = new Set(prev);
        next.delete(detail.id);
        return next;
      });
      setSurvivorId((cur) => (cur === detail.id ? null : cur));
      setMergeConfirmOpen(false);
      setDeleteConfirmOpen(false);
      clearSelection();
    } catch {
      setError("Failed to delete synergy");
    } finally {
      setDeleteBusy(false);
    }
  }

  function handleSaved(synergy: SynergyDetailType) {
    detailRequestSeq.current += 1;
    setRows((prev) => {
      const exists = prev.some((r) => r.id === synergy.id);
      const next = exists
        ? prev.map((r) => (r.id === synergy.id ? synergy : r))
        : [...prev, synergy];
      return sortByName(next);
    });
    setSelectedId(synergy.id);
    setDetail(synergy);
    setDetailPendingId(null);
    setCreating(false);
    setEditing(false);
  }

const pageDescription =
    "Type:Subtype designations Build uses for coverage.";

  if (signedIn === false) {
    return (
      <SignedOutGate
        title="Synergy"
        description={pageDescription}
emptyDescription="Sign in with Bungie (header control) to curate designations Build reads for coverage."
      />
    );
  }

  function startCreate() {
    detailRequestSeq.current += 1;
    setCreating(true);
    setEditing(false);
    setSelectedId(null);
    setDetail(null);
    setDetailPendingId(null);
    setMergeConfirmOpen(false);
    setDeleteConfirmOpen(false);
    setStatusMessage(null);
  }

  const detailReady =
    detail != null &&
    selectedId != null &&
    detail.id === selectedId &&
    detailPendingId == null;

  const pendingLabel = (() => {
    if (!detailPendingId) return null;
    const row = rows.find((r) => r.id === detailPendingId);
    if (!row) return "Loading designation…";
    return `Loading ${formatSynergyTypeDesignation({
      type: row.type,
      subType: row.subType,
    })}…`;
  })();

  let main: ReactNode;
  const createPrefillType =
    typeFilter.length === 1 ? (typeFilter[0] ?? null) : null;

  if (creating) {
    main = (
      <WorkspaceMain>
        <SynergyEditPanel
          mode="create"
          prefillType={createPrefillType}
          onClose={() => setCreating(false)}
          onSaved={handleSaved}
        />
      </WorkspaceMain>
    );
  } else if (editing && detailReady) {
    main = (
      <WorkspaceMain>
        <SynergyEditPanel
          key={detail!.id}
          mode="edit"
          initial={detail!}
          onClose={() => setEditing(false)}
          onSaved={handleSaved}
        />
      </WorkspaceMain>
    );
  } else if (detailPendingId) {
    main = (
      <WorkspaceMain>
        <div aria-busy="true" aria-live="polite">
          <Panel tone="muted" pad="lg">
            <Stack gap={8}>
              <Text size="sm" weight="medium">
                Loading designation
              </Text>
              <Text size="sm" tone="muted">
                {pendingLabel}
              </Text>
            </Stack>
          </Panel>
        </div>
      </WorkspaceMain>
    );
  } else if (detailReady) {
    const listMeta = rows.find((r) => r.id === detail!.id);
    main = (
      <WorkspaceMain>
        <div aria-busy="false">
          <SynergyDetail
synergy={{
              ...detail!,
              buildCount:
                detail!.usedByBuilds?.length ??
                listMeta?.buildCount ??
                detail!.buildCount,
              objectCount:
                listMeta?.objectCount ??
                detail!.objectCount ??
                detail!.links.length,
              usedByBuilds: detail!.usedByBuilds,
            }}
            onEdit={() => {
              setDeleteConfirmOpen(false);
              setEditing(true);
            }}
            onDelete={requestDelete}
            deleteBusy={deleteBusy}
          />
        </div>
      </WorkspaceMain>
    );
  } else {
    main = (
      <WorkspaceMain>
<EmptyState
          title={loading ? "Loading library" : "No designation open"}
          description={
            loading
              ? "Fetching your synergy library…"
              : "Pick a row on the board, or create a designation."
          }
          action={
            loading ? undefined : (
              <Button variant="accent" size="sm" onClick={startCreate}>
                New designation
              </Button>
            )
          }
        />
      </WorkspaceMain>
    );
  }

  const focusMain = Boolean(
    creating || editing || detailReady || detailPendingId,
  );

  return (
<PageFrame>
      <PageFrameChrome>
        <Stack gap={8}>
          <PageHeader title="Synergy" />
          {error ? <Callout tone="danger">{error}</Callout> : null}
          {statusMessage ? (
            <Callout tone="success">{statusMessage}</Callout>
          ) : null}
          {deleteConfirmOpen && detailReady && detail ? (
            <div role="region" aria-label="Confirm delete">
              <Panel tone="warning" pad="md">
                <Stack gap={8}>
                  <Row gap={8} align="center" wrap>
                    <Text size="sm" weight="medium" tone="warning">
                      Delete designation?
                    </Text>
                    <Badge tone="danger">Permanent</Badge>
                  </Row>
                  <Text size="sm" tone="muted">
                    Remove{" "}
                    <strong>
                      {formatSynergyTypeDesignation({
                        type: detail.type,
                        subType: detail.subType,
                      })}
                    </strong>{" "}
                    from the library. This cannot be undone.
                  </Text>
                  <Text size="xs" tone="muted">
                    {(detail.buildCount ??
                      rows.find((r) => r.id === detail.id)?.buildCount ??
                      0) === 0
                      ? "No builds currently list this designation."
                      : `${detail.buildCount ?? rows.find((r) => r.id === detail.id)?.buildCount ?? 0} build(s) list this designation — they keep the type/subtype string; only this library row and its links are deleted.`}
                    {" · "}
                    {detail.links.length} linked object
                    {detail.links.length === 1 ? "" : "s"} on this row.
                  </Text>
                  <Row gap={8} wrap>
                    <Button
                      size="sm"
                      variant="danger"
                      disabled={deleteBusy}
                      onClick={() => void confirmDelete()}
                    >
                      {deleteBusy ? "Deleting…" : "Delete designation"}
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      disabled={deleteBusy}
                      onClick={() => setDeleteConfirmOpen(false)}
                    >
                      Cancel
                    </Button>
                  </Row>
                </Stack>
              </Panel>
            </div>
          ) : null}
          {mergeConfirmOpen && mergeState.enabled && mergeState.survivor ? (
            <div role="region" aria-label="Confirm merge">
              <Panel tone="warning" pad="md">
                <Stack gap={8}>
                  <Row gap={8} align="center" wrap>
                    <Text size="sm" weight="medium" tone="warning">
                      Confirm merge
                    </Text>
                    <Badge tone="warning">Hygiene</Badge>
                  </Row>
                  <Text size="sm" tone="muted">
                    Keep{" "}
                    <strong>
                      {formatSynergyTypeDesignation({
                        type: mergeState.survivor.type,
                        subType: mergeState.survivor.subType,
                      })}
                    </strong>{" "}
                    and absorb {mergeState.sources.length} other designation
                    {mergeState.sources.length === 1 ? "" : "s"}. Links combine
                    into the survivor; absorbed rows are deleted. Builds that use
                    this type/subtype stay linked by designation.
                  </Text>
                  <Stack gap={4}>
                    <Text size="xs" tone="muted">
                      Survivor
                    </Text>
                    <Text size="sm" weight="medium">
                      {formatSynergyTypeDesignation({
                        type: mergeState.survivor.type,
                        subType: mergeState.survivor.subType,
                      })}
                      {" · "}
                      {mergeState.survivor.buildCount ?? 0} builds ·{" "}
                      {mergeState.survivor.objectCount ??
                        mergeState.survivor.links?.length ??
                        0}{" "}
                      objects
                    </Text>
                    <Text size="xs" tone="muted">
                      Absorbed ({mergeState.sources.length})
                    </Text>
                    <ul className="list-none m-0 p-0 space-y-1">
                      {mergeState.sources.map((s) => (
                        <li key={s.id}>
                          <Text size="sm" tone="muted">
                            {formatSynergyTypeDesignation({
                              type: s.type,
                              subType: s.subType,
                            })}
                            {" · "}
                            {s.buildCount ?? 0} builds ·{" "}
                            {s.objectCount ?? s.links?.length ?? 0} objects
                          </Text>
                        </li>
                      ))}
                    </ul>
                  </Stack>
                  <Row gap={8} wrap>
                    <Button
                      size="sm"
                      variant="accent"
                      disabled={mergeBusy}
                      onClick={() => void confirmMerge()}
                    >
                      {mergeBusy ? "Merging…" : "Confirm merge"}
                    </Button>
                    <Button
                      size="sm"
                      variant="ghost"
                      disabled={mergeBusy}
                      onClick={() => setMergeConfirmOpen(false)}
                    >
                      Cancel
                    </Button>
                  </Row>
                </Stack>
              </Panel>
            </div>
          ) : null}
          <SynergyFilters
            query={query}
            onQueryChange={setQuery}
            typeFilter={typeFilter}
            onTypeFilterChange={setTypeFilter}
            subTypeFilter={subTypeFilter}
            onSubTypeFilterChange={setSubTypeFilter}
          />
        </Stack>
      </PageFrameChrome>
      <PageFrameBody>
        <Workspace railWidth={320}
          focusMain={focusMain}
          onBackToLibrary={() => {
            clearSelection();
          }}
          rail={
            <SynergyLibrary
              synergies={filtered}
              selectedId={selectedId}
              checkedIds={checkedIds}
              survivorId={
                survivorId && checkedIds.has(survivorId) ? survivorId : null
              }
              hygieneMode={hygieneMode}
              onHygieneModeChange={setHygieneModeNext}
              loading={loading}
              mergeBusy={mergeBusy}
              duplicateBusy={duplicateBusy}
              mergeEnabled={mergeState.enabled}
              mergeBlockedReason={mergeState.reason}
              onSelect={selectRow}
              onToggleCheck={toggleCheck}
              onCheckAllVisible={() => {
                const ids = filtered.map((r) => r.id);
                setCheckedIds(new Set(ids));
                setSurvivorId((cur) =>
                  cur && ids.includes(cur) ? cur : (ids[0] ?? null),
                );
                setMergeConfirmOpen(false);
              }}
              onClearChecked={() => clearMergeSelection()}
              onSurvivorChange={(id) => {
                if (!checkedIds.has(id)) return;
                setSurvivorId(id);
                setMergeConfirmOpen(false);
              }}
              onMerge={requestMerge}
              onDuplicate={() => void handleDuplicate()}
              onNew={startCreate}
            />
          }
          main={main}
        />
      </PageFrameBody>
    </PageFrame>
  );
}

