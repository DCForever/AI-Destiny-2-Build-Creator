"use client";

import {
  useCallback,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from "react";

import { SetsDetail } from "@/components/sets/SetsDetail";
import { SetsEditPanel } from "@/components/sets/SetsEditPanel";
import { SetsLibrary } from "@/components/sets/SetsLibrary";
import { SlotFillPanel } from "@/components/sets/SlotFillPanel";
import type { SetDetail, SetSummary } from "@/components/sets/types";
import {
  Button,
  Callout,
  Cluster,
  CollapsibleFilterSection,
  ConceptTagFilterChip,
  EmptyState,
  FilterChip,
  PageFrame,
  PageFrameBody,
  PageFrameChrome,
  PageHeader,
  Panel,
  SectionLabel,
  SignedOutGate,
  Stack,
  Text,
  TextField,
  Workspace,
  WorkspaceMain,
} from "@/components/ui";
import { CONCEPT_TAGS } from "@/data/conceptTags";
import { filterSets } from "@/lib/sets/filterSets";
import { SET_TYPES } from "@/lib/sets/schemas";
import { sortByName } from "@/lib/sortByName";

/**
 * Sets screen composition.
 *
 * Layout: PageHeader · Filters · Workspace(rail library · main detail/edit/fill)
 */
export function SetsPage() {
  const [signedIn, setSignedIn] = useState<boolean | null>(null);
  const [rows, setRows] = useState<SetSummary[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [detail, setDetail] = useState<SetDetail | null>(null);
  /** When set, main is loading this id; never show another row's detail. */
  const [detailPendingId, setDetailPendingId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [typeFilter, setTypeFilter] = useState<string[]>([]);
  const [tagFilter, setTagFilter] = useState<string[]>([]);
  const [filtersOpen, setFiltersOpen] = useState(false);
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState(false);
  const [fillSlot, setFillSlot] = useState<string | null>(null);
  const [deleteBusy, setDeleteBusy] = useState(false);

  /** Monotonic token so slower loadDetail responses cannot overwrite newer selection. */
  const detailRequestSeq = useRef(0);

  const loadList = useCallback(async () => {
    const res = await fetch("/api/user/sets");
    if (res.status === 401) {
      setSignedIn(false);
      setRows([]);
      return false;
    }
    if (!res.ok) {
      const body = (await res.json()) as { error?: string };
      setError(body.error ?? "Failed to load sets");
      return false;
    }
    setSignedIn(true);
    const body = (await res.json()) as { sets: SetSummary[] };
    setRows(sortByName(body.sets ?? []));
    return true;
  }, []);

  const loadDetail = useCallback(async (id: string) => {
    const seq = ++detailRequestSeq.current;
    setError(null);
    setDetailPendingId(id);
    // Drop stale pane immediately so Edit/Delete never target the previous row.
    setDetail((prev) => (prev?.id === id ? prev : null));
    try {
      const res = await fetch(`/api/user/sets/${id}`);
      if (seq !== detailRequestSeq.current) return;
      if (!res.ok) {
        const body = (await res.json()) as { error?: string };
        setError(body.error ?? "Failed to load set");
        setDetail(null);
        setDetailPendingId(null);
        return;
      }
      const body = (await res.json()) as { set: SetDetail };
      if (seq !== detailRequestSeq.current) return;
      if (body.set?.id !== id) {
        setError("Loaded set did not match the selection.");
        setDetail(null);
        setDetailPendingId(null);
        return;
      }
      setDetail(body.set);
      setDetailPendingId(null);
    } catch {
      if (seq !== detailRequestSeq.current) return;
      setError("Failed to load set");
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
      filterSets(rows, {
        query,
        types: typeFilter,
        tags: tagFilter,
      }),
    [rows, query, typeFilter, tagFilter],
  );

  function applySaved(set: SetDetail) {
    detailRequestSeq.current += 1;
    setRows((prev) => {
      const exists = prev.some((r) => r.id === set.id);
      const summary: SetSummary = {
        id: set.id,
        name: set.name,
        type: set.type,
        tagIds: set.tagIds ?? [],
      };
      const next = exists
        ? prev.map((r) => (r.id === set.id ? summary : r))
        : [...prev, summary];
      return sortByName(next);
    });
    setSelectedId(set.id);
    setDetail(set);
    setDetailPendingId(null);
    setCreating(false);
    setEditing(false);
    setFillSlot(null);
  }

  async function handleDelete() {
    if (!detail || detailPendingId || detail.id !== selectedId) return;
    const confirmed = window.confirm(
      `Delete set “${detail.name}”? This cannot be undone.`,
    );
    if (!confirmed) return;
    setDeleteBusy(true);
    setError(null);
    try {
      const res = await fetch(`/api/user/sets/${detail.id}`, { method: "DELETE" });
      const body = (await res.json()) as { error?: string };
      if (!res.ok) {
        setError(body.error ?? "Failed to delete set");
        return;
      }
      detailRequestSeq.current += 1;
      setRows((prev) => prev.filter((r) => r.id !== detail.id));
      setSelectedId(null);
      setDetail(null);
      setDetailPendingId(null);
      setEditing(false);
      setFillSlot(null);
    } catch {
      setError("Failed to delete set");
    } finally {
      setDeleteBusy(false);
    }
  }

  const pageDescription =
    "Curate reusable weapon, armor, mod, pair, and fashion kits for Build variants.";

  if (signedIn === false) {
    return (
      <SignedOutGate
        title="Sets"
        description={pageDescription}
        emptyDescription="Sign in with Bungie using the control in the header to curate weapon, armor, pair, and fashion sets."
      />
    );
  }

  function startCreate() {
    detailRequestSeq.current += 1;
    setCreating(true);
    setEditing(false);
    setFillSlot(null);
    setSelectedId(null);
    setDetail(null);
    setDetailPendingId(null);
  }

  const detailReady =
    detail != null &&
    selectedId != null &&
    detail.id === selectedId &&
    detailPendingId == null;

  const pendingLabel = (() => {
    if (!detailPendingId) return null;
    const row = rows.find((r) => r.id === detailPendingId);
    if (!row) return "Loading set…";
    return `Loading ${row.name}…`;
  })();

  const createPrefillType =
    typeFilter.length === 1 ? (typeFilter[0] ?? null) : null;

  let main: ReactNode;
  if (creating) {
    main = (
      <WorkspaceMain>
        <SetsEditPanel
          key="create"
          mode="create"
          prefillType={createPrefillType}
          onClose={() => setCreating(false)}
          onSaved={applySaved}
        />
      </WorkspaceMain>
    );
  } else if (editing && detailReady) {
    main = (
      <WorkspaceMain>
        <SetsEditPanel
          key={`edit-${detail!.id}`}
          mode="edit"
          initial={detail!}
          onClose={() => setEditing(false)}
          onSaved={applySaved}
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
                Loading set
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
    main = (
      <WorkspaceMain>
        <div aria-busy="false">
          <SetsDetail
            set={detail!}
            onEdit={() => {
              setFillSlot(null);
              setEditing(true);
            }}
            onFillSlot={(slot) => {
              setEditing(false);
              setFillSlot(slot);
            }}
            onUpdated={applySaved}
            onDelete={() => void handleDelete()}
            deleteBusy={deleteBusy}
          />
        </div>
      </WorkspaceMain>
    );
  } else {
    main = (
      <WorkspaceMain>
        <EmptyState
          title={loading ? "Loading library" : "No set open"}
          description={
            loading
              ? "Fetching your set library…"
              : "Pick a kit in the library, or create a set so Build variants can attach weapon, armor, mod, pair, or fashion loadouts."
          }
          action={
            loading ? undefined : (
              <Button variant="accent" size="sm" onClick={startCreate}>
                New set
              </Button>
            )
          }
        />
      </WorkspaceMain>
    );
  }

  // Set-fill: single full-pane Catalog (no Sets filters + library rail + embed).
  // Nested triple chrome left ~0px for catalog body on short phones.
  if (fillSlot && detailReady && detail) {
    return (
      <PageFrame>
        <PageFrameBody>
          <div className="h-full min-h-0 overflow-hidden flex flex-col">
            {error ? (
              <div className="shrink-0 pb-2">
                <Callout tone="danger">{error}</Callout>
              </div>
            ) : null}
            <div className="flex-1 min-h-0 overflow-hidden">
              <SlotFillPanel
                set={detail}
                slot={fillSlot}
                onClose={() => setFillSlot(null)}
                onFilled={applySaved}
              />
            </div>
          </div>
        </PageFrameBody>
      </PageFrame>
    );
  }

  const focusMain = Boolean(
    creating || editing || detailReady || detailPendingId,
  );

  return (
    <PageFrame>
      <PageFrameChrome>
        <Stack gap={12}>
          <PageHeader title="Sets" description={pageDescription} />
          {error ? <Callout tone="danger">{error}</Callout> : null}
          <CollapsibleFilterSection
            open={filtersOpen}
            onOpenChange={setFiltersOpen}
            activeCount={
              typeFilter.length +
              tagFilter.length +
              (query.trim() ? 1 : 0)
            }
            onClear={() => {
              setTypeFilter([]);
              setTagFilter([]);
              setQuery("");
            }}
            summary={
              <Cluster gap={3}>
                {query.trim() ? (
                  <FilterChip
                    size="xs"
                    label={
                      query.trim().length > 18
                        ? `${query.trim().slice(0, 16)}…`
                        : query.trim()
                    }
                    active
                    onClick={() => setQuery("")}
                  />
                ) : null}
                {typeFilter.map((t) => (
                  <FilterChip
                    key={t}
                    size="xs"
                    label={t}
                    active
                    onClick={() =>
                      setTypeFilter((prev) => prev.filter((x) => x !== t))
                    }
                  />
                ))}
                {tagFilter.map((id) => (
                  <ConceptTagFilterChip
                    key={id}
                    tagId={id}
                    active
                    onClick={() =>
                      setTagFilter((prev) => prev.filter((x) => x !== id))
                    }
                  />
                ))}
              </Cluster>
            }
          >
            <Stack gap={10}>
              <TextField
                label="Search"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder="Search name · type · tag…"
              />
              <Stack gap={4}>
                <SectionLabel>Type</SectionLabel>
                <Cluster>
                  {SET_TYPES.map((t) => (
                    <FilterChip
                      key={t}
                      label={t}
                      active={typeFilter.includes(t)}
                      onClick={() =>
                        setTypeFilter((prev) =>
                          prev.includes(t)
                            ? prev.filter((x) => x !== t)
                            : [...prev, t],
                        )
                      }
                    />
                  ))}
                </Cluster>
              </Stack>
              <Stack gap={4}>
                <SectionLabel>Tags</SectionLabel>
                <Cluster>
                  {CONCEPT_TAGS.slice(0, 14).map((tag) => (
                    <ConceptTagFilterChip
                      key={tag.id}
                      tagId={tag.id}
                      active={tagFilter.includes(tag.id)}
                      onClick={() =>
                        setTagFilter((prev) =>
                          prev.includes(tag.id)
                            ? prev.filter((x) => x !== tag.id)
                            : [...prev, tag.id],
                        )
                      }
                    />
                  ))}
                </Cluster>
              </Stack>
            </Stack>
          </CollapsibleFilterSection>
        </Stack>
      </PageFrameChrome>
      <PageFrameBody>
        <Workspace
          focusMain={focusMain}
          onBackToLibrary={() => {
            detailRequestSeq.current += 1;
            setCreating(false);
            setEditing(false);
            setFillSlot(null);
            setSelectedId(null);
            setDetail(null);
            setDetailPendingId(null);
          }}
          rail={
            <SetsLibrary
              sets={filtered}
              selectedId={selectedId}
              loading={loading}
              onSelect={(id) => {
                setCreating(false);
                setEditing(false);
                setFillSlot(null);
                setSelectedId(id);
                void loadDetail(id);
              }}
              onNew={startCreate}
            />
          }
          main={main}
        />
      </PageFrameBody>
    </PageFrame>
  );
}
