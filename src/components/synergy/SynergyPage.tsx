"use client";

import { useCallback, useEffect, useMemo, useState, type ReactNode } from "react";

import { SynergyDetail } from "@/components/synergy/SynergyDetail";
import { SynergyEditPanel } from "@/components/synergy/SynergyEditPanel";
import { SynergyFilters } from "@/components/synergy/SynergyFilters";
import { SynergyLibrary } from "@/components/synergy/SynergyLibrary";
import type { SynergyDetail as SynergyDetailType, SynergySummary } from "@/components/synergy/types";
import {
  Callout,
  EmptyState,
  PageHeader,
  Stack,
  Workspace,
  WorkspaceMain,
} from "@/components/ui";
import { filterSynergies } from "@/lib/synergies/filterSynergies";
import { sameSynergyDesignation } from "@/lib/synergies/mergeSynergies";
import { sortByName } from "@/lib/sortByName";

/**
 * Synergy screen composition.
 *
 * Layout slots:
 *   PageHeader
 *   Filters panel
 *   Workspace
 *     rail  → SynergyLibrary
 *     main  → SynergyEditPanel | SynergyDetail | EmptyState
 */
export function SynergyPage() {
  const [signedIn, setSignedIn] = useState<boolean | null>(null);
  const [rows, setRows] = useState<SynergySummary[]>([]);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [detail, setDetail] = useState<SynergyDetailType | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [query, setQuery] = useState("");
  const [typeFilter, setTypeFilter] = useState<string[]>([]);
  const [subTypeFilter, setSubTypeFilter] = useState<string[]>([]);
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState(false);
  const [deleteBusy, setDeleteBusy] = useState(false);
  const [checkedIds, setCheckedIds] = useState<Set<string>>(() => new Set());
  const [mergeBusy, setMergeBusy] = useState(false);

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
    setError(null);
    const res = await fetch(`/api/user/synergies/${id}`);
    if (!res.ok) {
      const body = (await res.json()) as { error?: string };
      setError(body.error ?? "Failed to load synergy");
      setDetail(null);
      return;
    }
    const body = (await res.json()) as { synergy: SynergyDetailType };
    setDetail(body.synergy);
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
      };
    }
    const survivor =
      (selectedId && checkedIds.has(selectedId)
        ? rows.find((r) => r.id === selectedId)
        : null) ?? checked[0]!;
    const sources = checked.filter((r) => r.id !== survivor.id);
    const same = sources.every((s) => sameSynergyDesignation(survivor, s));
    if (!same) {
      return {
        enabled: false,
        reason:
          "Checked rows must share the same type and subtype (e.g. all Verb: Scorch).",
        survivorId: survivor.id,
        sourceIds: sources.map((s) => s.id),
      };
    }
    return {
      enabled: true,
      reason: null as string | null,
      survivorId: survivor.id,
      sourceIds: sources.map((s) => s.id),
    };
  }, [rows, checkedIds, selectedId]);

  async function handleMerge() {
    if (!mergeState.enabled || !mergeState.survivorId) return;
    const survivor = rows.find((r) => r.id === mergeState.survivorId);
    const confirmed = window.confirm(
      `Merge ${mergeState.sourceIds.length + 1} synergies into “${survivor?.name ?? "selected"}”?\n\n` +
        `Links will be combined; the other ${mergeState.sourceIds.length} row(s) will be deleted. Builds that use this type/subtype are unaffected.`,
    );
    if (!confirmed) return;
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
      setCheckedIds(new Set());
      setSelectedId(body.synergy?.id ?? mergeState.survivorId);
      if (body.synergy) {
        setDetail(body.synergy);
      } else {
        void loadDetail(mergeState.survivorId);
      }
      setCreating(false);
      setEditing(false);
    } catch {
      setError("Failed to merge synergies");
    } finally {
      setMergeBusy(false);
    }
  }

  async function handleDelete() {
    if (!detail) return;
    const confirmed = window.confirm(
      `Delete synergy “${detail.name}”? This cannot be undone.`,
    );
    if (!confirmed) return;
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
      setSelectedId(null);
      setDetail(null);
      setEditing(false);
    } catch {
      setError("Failed to delete synergy");
    } finally {
      setDeleteBusy(false);
    }
  }

  function handleSaved(synergy: SynergyDetailType) {
    setRows((prev) => {
      const exists = prev.some((r) => r.id === synergy.id);
      const next = exists
        ? prev.map((r) => (r.id === synergy.id ? synergy : r))
        : [...prev, synergy];
      return sortByName(next);
    });
    setSelectedId(synergy.id);
    setDetail(synergy);
    setCreating(false);
    setEditing(false);
  }

  if (signedIn === false) {
    return (
      <div className="flex-1 max-w-3xl mx-auto p-6">
        <Stack gap={16}>
          <PageHeader
            title="Synergy"
            description="Sign in with Bungie to curate synergies used by Build."
          />
        </Stack>
      </div>
    );
  }

  let main: ReactNode;
  if (creating) {
    main = (
      <WorkspaceMain>
        <SynergyEditPanel
          mode="create"
          prefillType={typeFilter[0] ?? null}
          onClose={() => setCreating(false)}
          onSaved={handleSaved}
        />
      </WorkspaceMain>
    );
  } else if (editing && detail) {
    main = (
      <WorkspaceMain>
        <SynergyEditPanel
          mode="edit"
          initial={detail}
          onClose={() => setEditing(false)}
          onSaved={handleSaved}
        />
      </WorkspaceMain>
    );
  } else if (!detail) {
    main = (
      <EmptyState
        description={
          loading
            ? "Loading…"
            : "Select a synergy from the library, or create a new one."
        }
      />
    );
  } else {
    main = (
      <WorkspaceMain>
        <SynergyDetail
          synergy={detail}
          onEdit={() => setEditing(true)}
          onDelete={() => void handleDelete()}
          deleteBusy={deleteBusy}
        />
      </WorkspaceMain>
    );
  }

  return (
    <div className="flex-1 max-w-[1600px] mx-auto p-6">
      <Stack gap={16}>
        <PageHeader
          title="Synergy"
          description="Curate designations Build uses — filter by type and subtype submenu, open detail, create or edit links."
        />

        {error ? <Callout tone="danger">{error}</Callout> : null}

        <SynergyFilters
          query={query}
          onQueryChange={setQuery}
          typeFilter={typeFilter}
          onTypeFilterChange={setTypeFilter}
          subTypeFilter={subTypeFilter}
          onSubTypeFilterChange={setSubTypeFilter}
        />

        <Workspace
          rail={
            <SynergyLibrary
              synergies={filtered}
              selectedId={selectedId}
              checkedIds={checkedIds}
              loading={loading}
              mergeBusy={mergeBusy}
              mergeEnabled={mergeState.enabled}
              mergeBlockedReason={mergeState.reason}
              onSelect={(id) => {
                setCreating(false);
                setEditing(false);
                setSelectedId(id);
                void loadDetail(id);
              }}
              onToggleCheck={(id) => {
                setCheckedIds((prev) => {
                  const next = new Set(prev);
                  if (next.has(id)) next.delete(id);
                  else next.add(id);
                  return next;
                });
              }}
              onCheckAllVisible={() => {
                setCheckedIds(new Set(filtered.map((r) => r.id)));
              }}
              onClearChecked={() => setCheckedIds(new Set())}
              onMerge={() => void handleMerge()}
              onNew={() => {
                setCreating(true);
                setEditing(false);
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
