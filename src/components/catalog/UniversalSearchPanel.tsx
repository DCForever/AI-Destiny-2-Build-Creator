"use client";

import { useCallback, useEffect, useState } from "react";

import { ItemIcon } from "@/components/sheet/ItemIcon";
import {
  Badge,
  Button,
  Callout,
  Chip,
  Cluster,
  EmptyState,
  FilterChip,
  Panel,
  Row,
  SectionLabel,
  Stack,
  Text,
  TextField,
} from "@/components/ui";
import {
  COMPOSITION_KINDS,
  compositionKindLabel,
  type CompositionKind,
} from "@/lib/catalog/compositionKinds";
import type { CompositionSearchHit } from "@/lib/catalog/universalSearch";
import {
  catalogBodyRootClasses,
  catalogDetailPaneClasses,
  catalogResultsPaneClasses,
} from "@/lib/ui/viewportLayout";

import { UniversalHitDetail } from "./UniversalHitDetail";

type SearchCode = "NEED_QUERY" | "FILTERED_EMPTY" | "MANIFEST_NOT_READY" | undefined;

export function UniversalSearchPanel() {
  const [q, setQ] = useState("");
  const [debouncedQ, setDebouncedQ] = useState("");
  const [kindFilter, setKindFilter] = useState<CompositionKind[]>([]);
  const [hits, setHits] = useState<CompositionSearchHit[]>([]);
  const [selected, setSelected] = useState<CompositionSearchHit | null>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [code, setCode] = useState<SearchCode>(undefined);
  const [truncated, setTruncated] = useState(false);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  useEffect(() => {
    const t = window.setTimeout(() => setDebouncedQ(q), 220);
    return () => window.clearTimeout(t);
  }, [q]);

  const runSearch = useCallback(
    async (signal?: AbortSignal) => {
      const trimmed = debouncedQ.trim();
      if (!trimmed) {
        setHits([]);
        setCode("NEED_QUERY");
        setError(null);
        setLoading(false);
        setTruncated(false);
        return;
      }

      setLoading(true);
      setError(null);
      try {
        const params = new URLSearchParams({
          q: trimmed,
          limit: "48",
          includeOwned: "1",
        });
        if (kindFilter.length > 0) {
          params.set("kinds", kindFilter.join(","));
        }
        const res = await fetch(`/api/catalog/universal-search?${params}`, {
          signal,
        });
        const body = (await res.json().catch(() => ({}))) as {
          hits?: CompositionSearchHit[];
          code?: SearchCode;
          error?: string;
          truncated?: boolean;
        };

        if (signal?.aborted) return;

        if (res.status === 503 || body.code === "MANIFEST_NOT_READY") {
          setHits([]);
          setCode("MANIFEST_NOT_READY");
          setError(
            body.error ??
              "Manifest entity cache is not ready. Refresh the manifest and try again.",
          );
          setTruncated(false);
          return;
        }

        if (!res.ok) {
          setHits([]);
          setCode(undefined);
          setError(body.error ?? "Universal search failed");
          setTruncated(false);
          return;
        }

        setHits(body.hits ?? []);
        setCode(body.code);
        setTruncated(Boolean(body.truncated));
        setError(null);
      } catch (e) {
        if (e instanceof DOMException && e.name === "AbortError") return;
        setHits([]);
        setCode(undefined);
        setError("Universal search failed");
        setTruncated(false);
      } finally {
        if (!signal?.aborted) setLoading(false);
      }
    },
    [debouncedQ, kindFilter],
  );

  useEffect(() => {
    const ac = new AbortController();
    void runSearch(ac.signal);
    return () => ac.abort();
  }, [runSearch]);

  // Drop selection if it disappears from the current hit list (filter change).
  useEffect(() => {
    if (!selected) return;
    if (!hits.some((h) => h.id === selected.id)) {
      // Keep selection when viewing detail even if list reloads empty due to NEED_QUERY race —
      // only clear when we have a non-empty result set that excludes it, or FILTERED_EMPTY.
      if (hits.length > 0 || code === "FILTERED_EMPTY") {
        setSelected(null);
      }
    }
  }, [hits, selected, code]);

  function toggleKind(kind: CompositionKind) {
    setKindFilter((prev) => {
      if (prev.includes(kind)) return prev.filter((k) => k !== kind);
      return [...prev, kind];
    });
  }

  function clearKinds() {
    setKindFilter([]);
  }

  const hasSelection = selected != null;

  function emptyMessage(): { title: string; description: string } {
    if (code === "MANIFEST_NOT_READY") {
      return {
        title: "Manifest not ready",
        description:
          error ??
          "Entity cache is unavailable. Refresh the manifest, then search again.",
      };
    }
    if (code === "NEED_QUERY" || !debouncedQ.trim()) {
      return {
        title: "Type to search",
        description:
          "Search weapons, armor, mods, perks, traits, artifact perks, set bonuses, and subclass kit across the catalog.",
      };
    }
    if (code === "FILTERED_EMPTY") {
      return {
        title: "No matches for these kinds",
        description:
          "Your kind filters may be too narrow for this query. Clear kinds or broaden the filter.",
      };
    }
    if (error) {
      return {
        title: "Search failed",
        description: error,
      };
    }
    return {
      title: "No matches",
      description: `Nothing matched “${debouncedQ.trim()}”. Try another name or description fragment.`,
    };
  }

  const empty = emptyMessage();

  function renderHitCard(hit: CompositionSearchHit) {
    const active = selected?.id === hit.id;
    return (
      <button
        key={hit.id}
        type="button"
        className="text-left w-full min-w-0"
        title={hit.name}
        onClick={() => {
          setSelected(hit);
          setSuccessMessage(null);
        }}
      >
        <Panel
          tone={active ? "accent" : "muted"}
          pad="sm"
          className={active ? "" : "hover:border-line-strong transition-colors"}
        >
          <Row gap={8} align="start">
            <ItemIcon icon={hit.icon} name={hit.name} size={36} />
            <Stack gap={3} className="min-w-0 flex-1">
              <Row gap={6} align="center" className="min-w-0">
                <Text size="sm" weight="medium" className="truncate min-w-0">
                  {hit.name}
                </Text>
                {hit.owned && hit.owned.count > 0 ? (
                  <Badge tone="verified" title="Owned">
                    ×{hit.owned.count}
                  </Badge>
                ) : null}
              </Row>
              <Cluster gap={4}>
                <Chip>{compositionKindLabel(hit.kind)}</Chip>
              </Cluster>
              {hit.description ? (
                <Text size="xs" tone="muted" className="line-clamp-2">
                  {hit.description}
                </Text>
              ) : null}
            </Stack>
          </Row>
        </Panel>
      </button>
    );
  }

  const resultsPane = (
    <Panel as="aside" className="h-full min-h-0 flex flex-col overflow-hidden">
      <div className="shrink-0">
        <SectionLabel>
          Results
          {hits.length > 0 ? ` · ${hits.length}` : ""}
          {truncated ? " · truncated" : ""}
          {loading ? " · …" : ""}
        </SectionLabel>
      </div>
      <div className="flex-1 min-h-0 overflow-y-auto mt-3 overscroll-contain">
        {loading && hits.length === 0 && debouncedQ.trim() ? (
          <Text size="sm" tone="muted">
            Searching…
          </Text>
        ) : hits.length === 0 ? (
          <EmptyState title={empty.title} description={empty.description} pad="md" />
        ) : (
          <Stack gap={6}>{hits.map((h) => renderHitCard(h))}</Stack>
        )}
      </div>
    </Panel>
  );

  const detailPane = selected ? (
    <UniversalHitDetail
      hit={selected}
      onBack={() => setSelected(null)}
      onSuccess={(msg) => setSuccessMessage(msg)}
    />
  ) : null;

  return (
    <div className="h-full min-h-0 flex flex-col overflow-hidden w-full">
      <div className="shrink-0 max-h-[min(36dvh,16rem)] overflow-y-auto overscroll-contain pb-2">
        <Stack gap={8}>
          {error && code !== "MANIFEST_NOT_READY" ? (
            <Callout tone="danger">{error}</Callout>
          ) : null}
          {code === "MANIFEST_NOT_READY" ? (
            <Callout tone="warning" title="Manifest not ready">
              {error ?? "Refresh the manifest, then try again."}
            </Callout>
          ) : null}
          {successMessage ? (
            <Callout tone="success" title="Saved">
              {successMessage}
            </Callout>
          ) : null}

          <Panel tone="muted" pad="sm">
            <Stack gap={8}>
              <TextField
                label="Universal search"
                value={q}
                onChange={(e) => setQ(e.target.value)}
                placeholder="Name or description…"
                className="min-w-0 w-full"
              />
              <Stack gap={4}>
                <Row justify="between" align="center" gap={8}>
                  <Text size="xs" tone="muted" className="uppercase tracking-wide">
                    Kinds
                    {kindFilter.length > 0 ? ` · ${kindFilter.length}` : ""}
                  </Text>
                  {kindFilter.length > 0 ? (
                    <Button size="sm" variant="ghost" onClick={clearKinds}>
                      Clear kinds
                    </Button>
                  ) : null}
                </Row>
                <Cluster gap={3}>
                  {COMPOSITION_KINDS.map((kind) => (
                    <FilterChip
                      key={kind}
                      size="xs"
                      label={compositionKindLabel(kind)}
                      active={kindFilter.includes(kind)}
                      onClick={() => toggleKind(kind)}
                    />
                  ))}
                </Cluster>
              </Stack>
            </Stack>
          </Panel>
        </Stack>
      </div>

      <div className="flex-1 min-h-0 overflow-hidden basis-0">
        <div className={catalogBodyRootClasses(hasSelection)}>
          <div className={catalogResultsPaneClasses(hasSelection)}>{resultsPane}</div>
          {hasSelection && detailPane ? (
            <div className={catalogDetailPaneClasses()}>{detailPane}</div>
          ) : null}
        </div>
      </div>
    </div>
  );
}
