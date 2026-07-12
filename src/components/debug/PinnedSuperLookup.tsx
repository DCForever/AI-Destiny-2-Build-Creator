"use client";

import { useState } from "react";

import { buildSubclassSearchParams } from "@/lib/debug/subclassSearchParams";

type SearchResult = {
  hash: number;
  name: string;
  kind?: string;
};

type Props = {
  subclassName: string;
  selected: string | null;
  onSelect: (name: string | null) => void;
};

export function PinnedSuperLookup({ subclassName, selected, onSelect }: Props) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<SearchResult[]>([]);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [hasSearched, setHasSearched] = useState(false);

  async function runSearch() {
    setIsLoading(true);
    setError(null);
    setHasSearched(true);
    const params = buildSubclassSearchParams({
      category: "abilities",
      q: query.trim(),
      subclassName,
      kind: "super",
    });
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
      <div className="flex items-center justify-between gap-2">
        <span className="text-sm font-medium">Pinned super (optional)</span>
      </div>
      {selected ? (
        <div className="flex items-center justify-between gap-2 rounded border border-line bg-panel px-2 py-1 text-sm">
          <span>{selected}</span>
          <button type="button" className="rounded bg-panel-raised px-2 py-0.5 text-xs" onClick={() => onSelect(null)}>
            Clear
          </button>
        </div>
      ) : (
        <p className="text-xs text-muted">Search and pick a super for {subclassName || "the subclass"}.</p>
      )}
      <div className="flex gap-2">
        <input
          className="min-w-0 flex-1 rounded border border-line bg-background px-2 py-1 text-sm"
          placeholder="Search supers"
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
        <p className="text-xs text-muted">No supers found.</p>
      ) : null}
      {isLoading ? <p className="text-xs text-muted">Searching…</p> : null}
      <div className="max-h-40 space-y-1 overflow-auto">
        {results.map((item) => (
          <button
            key={`${item.hash}-${item.name}`}
            type="button"
            className="block w-full rounded border border-line bg-background px-2 py-1 text-left text-sm hover:border-accent"
            onClick={() => onSelect(item.name)}
          >
            {item.name}
          </button>
        ))}
      </div>
    </div>
  );
}
