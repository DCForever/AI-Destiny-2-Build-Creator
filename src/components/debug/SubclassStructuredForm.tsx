"use client";

import { useState } from "react";

import { SUBCLASSES_BY_CLASS } from "@/data/subclasses";

type GuardianClass = "Titan" | "Hunter" | "Warlock";
type AbilityKind = "super" | "classAbility" | "movement" | "melee" | "grenade";
type SearchCategory = "abilities" | "aspects" | "fragments";
type SearchResult = { hash: number; name: string; kind?: string };

export type SubclassFormValue = {
  name: string;
  super: string;
  classAbility: string;
  movement: string;
  melee: string;
  grenade: string;
  aspects: string[];
  fragments: string[];
  rationale: string;
};

type Props = {
  className: GuardianClass;
  value: SubclassFormValue;
  onChange: (next: SubclassFormValue) => void;
};

const ABILITY_FIELDS: Array<{ key: AbilityKind; label: string }> = [
  { key: "super", label: "Super" },
  { key: "classAbility", label: "Class ability" },
  { key: "movement", label: "Movement" },
  { key: "melee", label: "Melee" },
  { key: "grenade", label: "Grenade" },
];

function splitList(value: string): string[] {
  return value.split(",").map((item) => item.trim()).filter(Boolean);
}

function joinUnique(items: string[], next: string): string[] {
  return [...new Set([...items, next])];
}

export function SubclassStructuredForm({ className, value, onChange }: Props) {
  const [searchText, setSearchText] = useState<Record<string, string>>({});
  const [results, setResults] = useState<Record<string, SearchResult[]>>({});
  const [error, setError] = useState<string | null>(null);

  function updateField<K extends keyof SubclassFormValue>(key: K, next: SubclassFormValue[K]) {
    onChange({ ...value, [key]: next });
  }

  async function search(key: string, category: SearchCategory, kind?: AbilityKind) {
    const q = (searchText[key] ?? "").trim();
    if (!q) return;
    setError(null);
    const params = new URLSearchParams({ category, q, limit: "8" });
    if (kind) params.set("kind", kind);
    const res = await fetch(`/api/manifest/search?${params}`);
    const body = await res.json();
    if (!res.ok) {
      setError(body.error ?? "Search failed");
      setResults((current) => ({ ...current, [key]: [] }));
      return;
    }
    setResults((current) => ({ ...current, [key]: body.results ?? [] }));
  }

  return (
    <div className="space-y-3 rounded border border-zinc-800 p-3">
      <label className="block text-sm">
        Subclass
        <select
          className="mt-1 block w-full rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
          value={value.name}
          onChange={(event) => updateField("name", event.target.value)}
        >
          {SUBCLASSES_BY_CLASS[className].map((subclass) => (
            <option key={subclass} value={subclass}>
              {subclass}
            </option>
          ))}
        </select>
      </label>

      {ABILITY_FIELDS.map((field) => (
        <div key={field.key} className="space-y-1">
          <label className="block text-sm">
            {field.label}
            <input
              className="mt-1 block w-full rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
              value={value[field.key]}
              onChange={(event) => updateField(field.key, event.target.value)}
            />
          </label>
          <div className="flex gap-2">
            <input
              className="min-w-0 flex-1 rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
              placeholder={`Search ${field.label.toLowerCase()}`}
              value={searchText[field.key] ?? ""}
              onChange={(event) => setSearchText((current) => ({ ...current, [field.key]: event.target.value }))}
            />
            <button type="button" className="rounded bg-zinc-700 px-3 py-1 text-sm" onClick={() => void search(field.key, "abilities", field.key)}>
              Search
            </button>
          </div>
          <SearchResults results={results[field.key] ?? []} onPick={(item) => updateField(field.key, item.name)} />
        </div>
      ))}

      <ListField
        label="Aspects"
        fieldKey="aspects"
        value={value.aspects}
        searchText={searchText.aspects ?? ""}
        results={results.aspects ?? []}
        onTextChange={(next) => updateField("aspects", splitList(next))}
        onSearchTextChange={(next) => setSearchText((current) => ({ ...current, aspects: next }))}
        onSearch={() => void search("aspects", "aspects")}
        onPick={(item) => updateField("aspects", joinUnique(value.aspects, item.name))}
      />
      <ListField
        label="Fragments"
        fieldKey="fragments"
        value={value.fragments}
        searchText={searchText.fragments ?? ""}
        results={results.fragments ?? []}
        onTextChange={(next) => updateField("fragments", splitList(next))}
        onSearchTextChange={(next) => setSearchText((current) => ({ ...current, fragments: next }))}
        onSearch={() => void search("fragments", "fragments")}
        onPick={(item) => updateField("fragments", joinUnique(value.fragments, item.name))}
      />

      <label className="block text-sm">
        Rationale
        <input
          className="mt-1 block w-full rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
          value={value.rationale}
          onChange={(event) => updateField("rationale", event.target.value)}
        />
      </label>
      {error ? <p className="text-xs text-red-300">{error}</p> : null}
    </div>
  );
}

function SearchResults({ results, onPick }: { results: SearchResult[]; onPick: (item: SearchResult) => void }) {
  if (results.length === 0) return null;
  return (
    <div className="max-h-32 space-y-1 overflow-auto">
      {results.map((item) => (
        <button
          key={`${item.hash}-${item.name}`}
          type="button"
          className="block w-full rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-left text-xs hover:border-zinc-600"
          onClick={() => onPick(item)}
        >
          {item.name}
          {item.kind ? <span className="ml-2 text-zinc-500">{item.kind}</span> : null}
        </button>
      ))}
    </div>
  );
}

function ListField({
  label,
  fieldKey,
  value,
  searchText,
  results,
  onTextChange,
  onSearchTextChange,
  onSearch,
  onPick,
}: {
  label: string;
  fieldKey: string;
  value: string[];
  searchText: string;
  results: SearchResult[];
  onTextChange: (next: string) => void;
  onSearchTextChange: (next: string) => void;
  onSearch: () => void;
  onPick: (item: SearchResult) => void;
}) {
  return (
    <div className="space-y-1">
      <label className="block text-sm">
        {label}
        <input
          className="mt-1 block w-full rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
          value={value.join(", ")}
          onChange={(event) => onTextChange(event.target.value)}
        />
      </label>
      <div className="flex gap-2">
        <input
          className="min-w-0 flex-1 rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
          placeholder={`Search ${fieldKey}`}
          value={searchText}
          onChange={(event) => onSearchTextChange(event.target.value)}
        />
        <button type="button" className="rounded bg-zinc-700 px-3 py-1 text-sm" onClick={onSearch}>
          Search
        </button>
      </div>
      <SearchResults results={results} onPick={onPick} />
    </div>
  );
}
