"use client";

import { useCallback, useEffect, useMemo, useState, type ReactNode } from "react";

import { SetsDetail } from "@/components/sets/SetsDetail";
import { SetsEditPanel } from "@/components/sets/SetsEditPanel";
import { SetsLibrary } from "@/components/sets/SetsLibrary";
import { SlotFillPanel } from "@/components/sets/SlotFillPanel";
import type { SetDetail, SetSummary } from "@/components/sets/types";
import {
  Callout,
  Cluster,
  EmptyState,
  FilterChip,
  PageHeader,
  Panel,
  Row,
  SectionLabel,
  Stack,
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
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [typeFilter, setTypeFilter] = useState<string[]>([]);
  const [tagFilter, setTagFilter] = useState<string[]>([]);
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState(false);
  const [fillSlot, setFillSlot] = useState<string | null>(null);
  const [deleteBusy, setDeleteBusy] = useState(false);

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
    setError(null);
    const res = await fetch(`/api/user/sets/${id}`);
    if (!res.ok) {
      const body = (await res.json()) as { error?: string };
      setError(body.error ?? "Failed to load set");
      setDetail(null);
      return;
    }
    const body = (await res.json()) as { set: SetDetail };
    setDetail(body.set);
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
    setCreating(false);
    setEditing(false);
    setFillSlot(null);
  }

  async function handleDelete() {
    if (!detail) return;
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
      setRows((prev) => prev.filter((r) => r.id !== detail.id));
      setSelectedId(null);
      setDetail(null);
      setEditing(false);
      setFillSlot(null);
    } catch {
      setError("Failed to delete set");
    } finally {
      setDeleteBusy(false);
    }
  }

  if (signedIn === false) {
    return (
      <div className="flex-1 max-w-3xl mx-auto px-4 sm:px-6 py-4 sm:py-6">
        <Stack gap={16}>
          <PageHeader
            title="Sets"
            description="Sign in with Bungie to curate weapon, armor, pair, and fashion sets."
          />
        </Stack>
      </div>
    );
  }

  let main: ReactNode;
  if (creating) {
    main = (
      <WorkspaceMain>
        <SetsEditPanel
          key="create"
          mode="create"
          prefillType={typeFilter[0] ?? null}
          onClose={() => setCreating(false)}
          onSaved={applySaved}
        />
      </WorkspaceMain>
    );
  } else if (editing && detail) {
    main = (
      <WorkspaceMain>
        <SetsEditPanel
          key={`edit-${detail.id}`}
          mode="edit"
          initial={detail}
          onClose={() => setEditing(false)}
          onSaved={applySaved}
        />
      </WorkspaceMain>
    );
  } else if (fillSlot && detail) {
    main = (
      <WorkspaceMain>
        <SlotFillPanel
          set={detail}
          slot={fillSlot}
          onClose={() => setFillSlot(null)}
          onFilled={applySaved}
        />
      </WorkspaceMain>
    );
  } else if (!detail) {
    main = (
      <EmptyState
        description={
          loading
            ? "Loading…"
            : "Select a set from the library, or create a new one."
        }
      />
    );
  } else {
    main = (
      <WorkspaceMain>
        <SetsDetail
          set={detail}
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
      </WorkspaceMain>
    );
  }

  return (
    <div className="flex-1 max-w-[1600px] mx-auto px-4 sm:px-6 py-4 sm:py-6">
      <Stack gap={16}>
        <PageHeader
          title="Sets"
          description="Curate reusable weapon, armor, mod, pair, and fashion kits for Build variants."
        />

        {error ? <Callout tone="danger">{error}</Callout> : null}

        <Panel tone="muted" pad="md">
          <Stack gap={10}>
            <SectionLabel>Filters</SectionLabel>
            <TextField
              label="Search"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search name · type · tag…"
            />
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
            <Cluster>
              {CONCEPT_TAGS.slice(0, 14).map((tag) => (
                <FilterChip
                  key={tag.id}
                  label={tag.label}
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
            {(typeFilter.length > 0 || tagFilter.length > 0 || query.trim()) && (
              <Row>
                <button
                  type="button"
                  className="text-[10px] tracking-widest uppercase text-muted hover:text-foreground"
                  onClick={() => {
                    setTypeFilter([]);
                    setTagFilter([]);
                    setQuery("");
                  }}
                >
                  Clear filters
                </button>
              </Row>
            )}
          </Stack>
        </Panel>

        <Workspace
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
              onNew={() => {
                setCreating(true);
                setEditing(false);
                setFillSlot(null);
                setSelectedId(null);
                setDetail(null);
              }}
            />
          }
          main={main}
        />
      </Stack>
    </div>
  );
}
