"use client";

import { useCallback, useEffect, useState } from "react";
import { ItemIcon } from "./ItemIcon";

export interface WeaponSearchResult {
  name: string;
  hash: number;
  icon: string | null;
  slot?: string;
  isExotic?: boolean;
  confidence: number;
}

interface WeaponPickerProps {
  slot: "Kinetic" | "Energy" | "Power";
  open: boolean;
  onClose: () => void;
  onSelect: (result: WeaponSearchResult) => void;
}

export function WeaponPicker({ slot, open, onClose, onSelect }: WeaponPickerProps) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<WeaponSearchResult[]>([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleClose = () => {
    setQuery("");
    setResults([]);
    setError(null);
    onClose();
  };

  const search = useCallback(async (q: string) => {
    if (!q.trim()) {
      setResults([]);
      return;
    }
    setLoading(true);
    setError(null);
    try {
      const params = new URLSearchParams({ q: q.trim(), slot, limit: "10" });
      const res = await fetch(`/api/manifest/search?${params}`);
      if (!res.ok) {
        const body = await res.json() as { error?: string };
        setError(body.error ?? "Search failed");
        return;
      }
      const body = await res.json() as { results: WeaponSearchResult[] };
      setResults(body.results);
    } catch {
      setError("Search failed");
    } finally {
      setLoading(false);
    }
  }, [slot]);

  useEffect(() => {
    if (!open) return;
    const handle = window.setTimeout(() => void search(query), 250);
    return () => window.clearTimeout(handle);
  }, [open, query, search]);

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-background/80 p-4"
      role="dialog"
      aria-modal="true"
      aria-label={`Pick ${slot} weapon`}
    >
      <div className="panel-notch w-full max-w-md p-4 space-y-4 bg-background border border-line shadow-lg">
        <div className="flex items-center justify-between gap-3">
          <h3 className="text-sm text-foreground">Pick {slot} weapon</h3>
          <button
            type="button"
            onClick={handleClose}
            className="text-xs text-muted hover:text-foreground focus-visible:outline-accent"
          >
            Close
          </button>
        </div>

        <input
          type="search"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search weapons…"
          autoFocus
          className="w-full bg-background border border-line px-3 py-2 text-sm text-foreground placeholder-muted focus-visible:outline-accent focus-visible:border-accent"
        />

        {loading && <p className="text-xs text-muted">Searching…</p>}
        {error && <p className="text-xs text-danger">{error}</p>}

        <ul className="max-h-64 overflow-y-auto divide-y divide-line/50">
          {results.map((result) => (
            <li key={result.hash}>
              <button
                type="button"
                onClick={() => {
                  onSelect(result);
                  handleClose();
                }}
                className="w-full flex items-center gap-3 px-2 py-2 text-left hover:bg-foreground/5 transition-colors focus-visible:outline-accent"
              >
                <ItemIcon icon={result.icon} name={result.name} size={32} />
                <span className="text-sm text-foreground truncate">{result.name}</span>
              </button>
            </li>
          ))}
          {!loading && query.trim() && results.length === 0 && (
            <li className="px-2 py-3 text-xs text-muted">No matches for &ldquo;{query}&rdquo;</li>
          )}
        </ul>
      </div>
    </div>
  );
}
