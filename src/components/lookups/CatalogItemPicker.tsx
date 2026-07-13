"use client";

import { useState } from "react";

import { ItemIcon } from "@/components/sheet/ItemIcon";
import type { CatalogItem } from "@/lib/catalog/types";
import { setSlotToCatalogBucket } from "@/lib/sets/catalogSlotMap";
import {
  Button,
  Cluster,
  FilterChip,
  Row,
  Stack,
  Text,
  TextField,
} from "@/components/ui";

export type CatalogPick = {
  hash: number;
  name: string;
  slot?: string;
  ownedCount: number;
  instancesHref?: string;
};

export function CatalogItemPicker({
  kind,
  setSlot,
  scope = "all",
  selected,
  onSelect,
  disabled,
}: {
  kind: "weapons" | "armor";
  /** Set domain slot (primary, helmet, …) mapped to catalog bucket. */
  setSlot?: string;
  scope?: "all" | "owned";
  selected?: CatalogPick | null;
  onSelect: (item: CatalogPick | null) => void;
  disabled?: boolean;
}) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<CatalogItem[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  async function runSearch() {
    setBusy(true);
    setError(null);
    setMessage(null);
    try {
      const params = new URLSearchParams({
        scope,
        includeInstancePointer: "1",
        limit: "40",
      });
      if (query.trim()) params.set("q", query.trim());
      const bucket = setSlot ? setSlotToCatalogBucket(setSlot) : null;
      if (bucket) params.set("slot", bucket);
      const res = await fetch(`/api/catalog/${kind}?${params}`);
      const body = (await res.json()) as {
        items?: CatalogItem[];
        error?: string;
        message?: string;
        syncPrompt?: boolean;
      };
      if (!res.ok) {
        setError(body.error ?? "Catalog search failed");
        setResults([]);
        return;
      }
      setResults(body.items ?? []);
      if (body.syncPrompt && body.message) setMessage(body.message);
    } catch {
      setError("Catalog search failed");
      setResults([]);
    } finally {
      setBusy(false);
    }
  }

  return (
    <Stack gap={8}>
      {selected ? (
        <Row justify="between" align="center" gap={8}>
          <Cluster gap={6}>
            <Text size="sm">{selected.name}</Text>
            {selected.ownedCount > 0 ? (
              <Text size="xs" tone="muted" as="span">
                · {selected.ownedCount} owned
              </Text>
            ) : null}
          </Cluster>
          <Button
            size="sm"
            variant="ghost"
            disabled={disabled}
            onClick={() => onSelect(null)}
          >
            Clear
          </Button>
        </Row>
      ) : null}
      <Row gap={8} align="end" wrap>
        <TextField
          label="Catalog search"
          value={query}
          disabled={disabled}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") void runSearch();
          }}
          className="min-w-[200px] flex-1"
          placeholder="Name, perk, frame…"
        />
        <Button size="sm" disabled={disabled || busy} onClick={() => void runSearch()}>
          {busy ? "…" : "Search"}
        </Button>
      </Row>
      <Cluster gap={6}>
        <FilterChip
          label={scope === "owned" ? "Owned" : "Manifest"}
          active
          onClick={() => undefined}
        />
        {setSlot ? <FilterChip label={`Slot · ${setSlot}`} active onClick={() => undefined} /> : null}
      </Cluster>
      {error ? (
        <Text size="xs" tone="danger">
          {error}
        </Text>
      ) : null}
      {message ? (
        <Text size="xs" tone="muted">
          {message}
        </Text>
      ) : null}
      {results.length > 0 ? (
        <Stack gap={4} className="max-h-56 overflow-auto">
          {results.map((item) => (
            <button
              key={item.hash}
              type="button"
              disabled={disabled}
              className="text-left px-2 py-1.5 text-sm border border-line bg-surface-raised hover:border-line-strong disabled:opacity-50"
              onClick={() => {
                onSelect({
                  hash: item.hash,
                  name: item.name,
                  slot: item.slot,
                  ownedCount: item.ownedCount,
                  instancesHref: item.instancesHref,
                });
                setResults([]);
                setQuery("");
              }}
            >
              <span className="flex items-center gap-2 min-w-0">
                <ItemIcon icon={item.icon} name={item.name} size={28} />
                <span className="min-w-0">
                  <span className="font-medium">{item.name}</span>
                  <span className="ml-2 text-xs text-muted">
                    {[item.slot, item.element, item.isExotic ? "Exotic" : null]
                      .filter(Boolean)
                      .join(" · ")}
                    {item.ownedCount > 0 ? ` · ×${item.ownedCount}` : ""}
                  </span>
                </span>
              </span>
            </button>
          ))}
        </Stack>
      ) : null}
    </Stack>
  );
}
