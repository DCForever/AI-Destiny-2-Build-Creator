"use client";

import { useState } from "react";

import { emptyLookupMessage, mapExoticSelection } from "@/lib/debug/lookupParity";

type ExoticSelection = { hash: number; name: string };
type SearchResult = ExoticSelection & { icon?: string | null; slot?: string };

type Props = {
  className?: string;
  selected?: ExoticSelection | null;
  onSelect: (item: ExoticSelection | null) => void;
};

export function ExoticArmorLookup({ className, selected, onSelect }: Props) {
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
    const params = new URLSearchParams({ category: "exotic-armor", q, limit: q ? "12" : "50" });
    if (className) params.set("classType", className);
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
    <div className="space-y-2 rounded border border-zinc-800 p-3">
      <div className="flex items-center justify-between gap-2">
        <label className="text-sm font-medium">Exotic armor</label>
        {className ? <span className="text-xs text-zinc-500">Class hint: {className}</span> : null}
      </div>
      {selected ? (
        <div className="flex items-center justify-between gap-2 rounded border border-emerald-900/60 bg-emerald-950/30 px-2 py-1 text-sm">
          <span>
            {selected.name} <span className="text-zinc-500">({selected.hash})</span>
          </span>
          <button type="button" className="rounded bg-zinc-800 px-2 py-0.5 text-xs" onClick={() => onSelect(null)}>
            Clear
          </button>
        </div>
      ) : null}
      <div className="flex gap-2">
        <input
          className="min-w-0 flex-1 rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
          placeholder="Search exotic armor"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
          onKeyDown={(event) => {
            if (event.key === "Enter") void runSearch();
          }}
        />
        <button type="button" className="rounded bg-zinc-700 px-3 py-1 text-sm" onClick={() => void runSearch()}>
          Search
        </button>
      </div>
      {error ? <p className="text-xs text-red-300">{error}</p> : null}
      {!isLoading && hasSearched && results.length === 0 && !error ? (
        <p className="text-xs text-zinc-500">{emptyLookupMessage("exotic_armor")}</p>
      ) : null}
      {isLoading ? <p className="text-xs text-zinc-500">Searching...</p> : null}
      <div className="max-h-48 space-y-1 overflow-auto">
        {results.map((item) => (
          <button
            key={item.hash}
            type="button"
            className="block w-full rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-left text-sm hover:border-zinc-600"
            onClick={() => onSelect(mapExoticSelection(item))}
          >
            <span className="font-medium">{item.name}</span>
            <span className="ml-2 text-xs text-zinc-500">{item.slot ?? item.hash}</span>
          </button>
        ))}
      </div>
    </div>
  );
}
