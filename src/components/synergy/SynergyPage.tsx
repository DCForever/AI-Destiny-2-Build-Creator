"use client";

import { useCallback, useEffect, useMemo, useState, type ReactNode } from "react";

import { SynergyDetail } from "@/components/synergy/SynergyDetail";
import { SynergyEditPanel } from "@/components/synergy/SynergyEditPanel";
import { SynergyLibrary } from "@/components/synergy/SynergyLibrary";
import type { SynergyDetail as SynergyDetailType, SynergySummary } from "@/components/synergy/types";
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
  Text,
  TextField,
  Workspace,
  WorkspaceMain,
} from "@/components/ui";
import { getSynergyTypeLabel } from "@/lib/synergies/generateSynergyName";
import { CREATABLE_SYNERGY_TYPES } from "@/lib/synergies/schemas";
import { compareDisplayName, sortByName } from "@/lib/sortByName";

const SORTED_TYPES = [...CREATABLE_SYNERGY_TYPES].sort((a, b) =>
  compareDisplayName(getSynergyTypeLabel(a), getSynergyTypeLabel(b)),
);

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
  const [creating, setCreating] = useState(false);
  const [editing, setEditing] = useState(false);
  const [deleteBusy, setDeleteBusy] = useState(false);

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

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return rows.filter((row) => {
      if (typeFilter.length > 0 && !typeFilter.includes(row.type)) return false;
      if (!q) return true;
      const hay = `${row.name} ${row.type} ${row.subType ?? ""}`.toLowerCase();
      return hay.includes(q);
    });
  }, [rows, query, typeFilter]);

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
          description="Curate designations Build uses — filter by type, open detail, create or edit links."
        />

        {error ? <Callout tone="danger">{error}</Callout> : null}

        <Panel tone="muted" pad="md">
          <Stack gap={10}>
            <SectionLabel>Filters</SectionLabel>
            <TextField
              label="Search"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="Search name · type · subtype…"
            />
            <Cluster>
              {SORTED_TYPES.map((t) => (
                <FilterChip
                  key={t}
                  label={getSynergyTypeLabel(t)}
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
            {(typeFilter.length > 0 || query.trim()) && (
              <Row>
                <button
                  type="button"
                  className="text-[10px] tracking-widest uppercase text-muted hover:text-foreground"
                  onClick={() => {
                    setTypeFilter([]);
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
            <SynergyLibrary
              synergies={filtered}
              selectedId={selectedId}
              loading={loading}
              onSelect={(id) => {
                setCreating(false);
                setEditing(false);
                setSelectedId(id);
                void loadDetail(id);
              }}
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
