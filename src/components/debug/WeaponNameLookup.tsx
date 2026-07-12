"use client";

import { useState } from "react";

import { mapExoticSelection } from "@/lib/debug/lookupParity";

type Selection = { hash: number; name: string };
type SearchResult = Selection & { icon?: string | null; slot?: string };

type Props = {
  label?: string;
  selected?: Selection | null;
  onSelect: (item: Selection | null) => void;
};

/** Catalog weapon search-then-pick (any weapon, not exotic-only). */
export function WeaponNameLookup({ label = "Preferred weapon", selected, onSelect }: Props) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<SearchResult[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [hasSearched, setHasSearched] = useState(false);

  async function runSearch() {
    const q = query.trim();
    setIsLoading(true);
    setError(null);
    setHasSearched(true);
    const params = new URLSearchParams({ category: "weapons", q, limit: q ? "12" : "50" });
    const res = await fetch(`/api/manifest/search?${params}`);
    const body = await res.json();
    setIsLoading(false);
    if (!res.ok) {
      setError(body.error ?? "Search failed");
      setResults([]);
      return;
    }
    setResults(body.results ?? []);
  }

  return (
    <div className="space-y-2 rounded border border-line p-3">
      <label className="text-sm font-medium">{label}</label>
      {selected ? (
        <div className="flex items-center justify-between gap-2 rounded border border-line bg-panel px-2 py-1 text-sm">
          <span>{selected.name}</span>
          <button type="button" className="rounded bg-panel-raised px-2 py-0.5 text-xs" onClick={() => onSelect(null)}>
            Clear
          </button>
        </div>
      ) : null}
      <div className="flex gap-2">
        <input
          className="min-w-0 flex-1 rounded border border-line bg-background px-2 py-1 text-sm"
          placeholder="Search weapons"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          onKeyDown={(event) => {
            if (event.key === "Enter") {
              event.preventDefault();
              void runSearch();
            }
          }}
        />
        <button type="button" className="rounded bg-panel-raised px-3 py-1 text-sm" onClick={() => void runSearch()}>
          Search
        </button>
      </div>
      {error ? <p className="text-xs text-danger">{error}</p> : null}
      {!isLoading && hasSearched && results.length === 0 && !error ? (
        <p className="text-xs text-muted">No weapons matched the current lookup.</p>
      ) : null}
      {isLoading ? <p className="text-xs text-muted">Searching…</p> : null}
      <div className="max-h-40 space-y-1 overflow-auto">
        {results.map((item) => (
          <button
            key={item.hash}
            type="button"
            className="block w-full rounded border border-line bg-background px-2 py-1 text-left text-sm hover:border-accent"
            onClick={() => onSelect(mapExoticSelection(item))}
          >
            {item.name}
          </button>
        ))}
      </div>
    </div>
  );
}
