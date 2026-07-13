"use client";

import { useState } from "react";

import { ItemIcon } from "@/components/sheet/ItemIcon";
import {
  Button,
  Cluster,
  FilterChip,
  Row,
  Stack,
  Text,
  TextField,
} from "@/components/ui";

export type ManifestPick = {
  hash: number;
  name: string;
  icon?: string | null;
  kind?: string;
  description?: string;
  perks?: Array<{ hash: number; name: string; column?: number; row?: number }>;
};

type Category =
  | "weapons"
  | "exotic-weapons"
  | "mods"
  | "exotic-armor"
  | "aspects"
  | "fragments"
  | "abilities"
  | "artifacts";

export function ManifestSearchPicker({
  label,
  category,
  kind,
  classType,
  subclass,
  selected,
  onSelect,
  multi,
  selectedNames,
  onToggleName,
  disabled,
  emptyBrowse = true,
}: {
  label: string;
  category: Category;
  kind?: "super" | "grenade" | "melee" | "classAbility" | "movement";
  classType?: "Titan" | "Hunter" | "Warlock";
  subclass?: string;
  selected?: ManifestPick | null;
  onSelect?: (item: ManifestPick | null) => void;
  multi?: boolean;
  selectedNames?: string[];
  onToggleName?: (name: string) => void;
  disabled?: boolean;
  emptyBrowse?: boolean;
}) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<ManifestPick[]>([]);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function runSearch(forceEmpty = false) {
    const q = query.trim();
    if (!q && !emptyBrowse && !forceEmpty) return;
    setBusy(true);
    setError(null);
    try {
      const params = new URLSearchParams({
        category,
        q,
        limit: q ? "20" : "50",
      });
      if (kind) params.set("kind", kind);
      if (classType) params.set("classType", classType);
      if (subclass) params.set("subclass", subclass);
      const res = await fetch(`/api/manifest/search?${params}`);
      const body = (await res.json()) as {
        results?: ManifestPick[];
        error?: string;
      };
      if (!res.ok) {
        setError(body.error ?? "Search failed");
        setResults([]);
        return;
      }
      setResults(body.results ?? []);
    } catch {
      setError("Search failed");
      setResults([]);
    } finally {
      setBusy(false);
    }
  }

  return (
    <Stack gap={8}>
      <Text size="xs" tone="muted">
        {label}
      </Text>
      {!multi && selected ? (
        <Row justify="between" align="center" gap={8}>
          <Row gap={8} align="center" className="min-w-0">
            <ItemIcon icon={selected.icon ?? null} name={selected.name} size={28} />
            <Text size="sm" className="truncate">
              {selected.name}
            </Text>
          </Row>
          <Button
            size="sm"
            variant="ghost"
            disabled={disabled}
            onClick={() => onSelect?.(null)}
          >
            Clear
          </Button>
        </Row>
      ) : null}
      {multi && (selectedNames?.length ?? 0) > 0 ? (
        <Cluster gap={6}>
          {selectedNames!.map((name) => (
            <FilterChip
              key={name}
              label={name}
              active
              onClick={() => onToggleName?.(name)}
            />
          ))}
        </Cluster>
      ) : null}
      <Row gap={8} align="end" wrap>
        <TextField
          label="Search"
          value={query}
          disabled={disabled}
          onChange={(e) => setQuery(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") void runSearch();
          }}
          className="min-w-[200px] flex-1"
        />
        <Button size="sm" disabled={disabled || busy} onClick={() => void runSearch()}>
          {busy ? "…" : emptyBrowse && !query.trim() ? "Browse" : "Search"}
        </Button>
      </Row>
      {error ? (
        <Text size="xs" tone="danger">
          {error}
        </Text>
      ) : null}
      {results.length > 0 ? (
        <Stack gap={4} className="max-h-48 overflow-auto">
          {results.map((item) => {
            const active = multi
              ? selectedNames?.includes(item.name)
              : selected?.hash === item.hash;
            return (
              <button
                key={`${item.hash}-${item.name}`}
                type="button"
                disabled={disabled}
                className={`text-left px-2 py-1.5 text-sm border ${
                  active
                    ? "border-accent bg-accent/10 text-foreground"
                    : "border-line bg-surface-raised hover:border-line-strong text-foreground"
                } disabled:opacity-50`}
                onClick={() => {
                  if (multi) {
                    onToggleName?.(item.name);
                  } else {
                    onSelect?.(item);
                    setResults([]);
                    setQuery("");
                  }
                }}
              >
                <span className="flex items-center gap-2 min-w-0">
                  <ItemIcon icon={item.icon ?? null} name={item.name} size={28} />
                  <span className="min-w-0">
                    <span className="font-medium">{item.name}</span>
                    {item.kind ? (
                      <span className="ml-2 text-xs text-muted">{item.kind}</span>
                    ) : null}
                  </span>
                </span>
              </button>
            );
          })}
        </Stack>
      ) : null}
    </Stack>
  );
}
