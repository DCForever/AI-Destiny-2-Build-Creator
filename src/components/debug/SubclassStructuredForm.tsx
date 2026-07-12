"use client";

import { useCallback, useEffect, useState } from "react";

import { SUBCLASSES_BY_CLASS } from "@/data/subclasses";
import { SYNERGY_VERB_NAMES } from "@/data/synergyVerbs";
import {
  clearIncompatibleSubclassSelections,
  type SubclassValidNames,
} from "@/lib/debug/subclassScope";
import { buildSubclassSearchParams } from "@/lib/debug/subclassSearchParams";
import { addPickedName, removePickedName } from "@/lib/debug/pickOnlyList";

type GuardianClass = "Titan" | "Hunter" | "Warlock";
type AbilityKind = "super" | "classAbility" | "movement" | "melee" | "grenade";
type SearchCategory = "abilities" | "aspects" | "fragments";
type SearchResult = {
  hash: number;
  name: string;
  kind?: string;
  subclassAffinities?: string[];
  verbs?: string[];
};

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

async function fetchResults(
  formValue: SubclassFormValue,
  key: string,
  category: SearchCategory,
  q: string,
  kind?: AbilityKind,
  filters?: { subclassAffinity?: string; verb?: string },
): Promise<SearchResult[]> {
  const params = buildSubclassSearchParams({
    category,
    q,
    subclassName: formValue.name,
    kind,
    filters,
  });
  const res = await fetch(`/api/manifest/search?${params}`);
  const body = await res.json();
  if (!res.ok) throw new Error(body.error ?? `Search failed for ${key}`);
  return body.results ?? [];
}

async function fetchValidNames(formValue: SubclassFormValue): Promise<SubclassValidNames> {
  const [abilities, aspects, fragments] = await Promise.all([
    fetchResults(formValue, "abilities", "abilities", ""),
    fetchResults(formValue, "aspects", "aspects", ""),
    fetchResults(formValue, "fragments", "fragments", ""),
  ]);
  return {
    abilities: new Set(abilities.map((item) => item.name)),
    aspects: new Set(aspects.map((item) => item.name)),
    fragments: new Set(fragments.map((item) => item.name)),
  };
}

export function SubclassStructuredForm({ className, value, onChange }: Props) {
  const [searchText, setSearchText] = useState<Record<string, string>>({});
  const [results, setResults] = useState<Record<string, SearchResult[]>>({});
  const [error, setError] = useState<string | null>(null);
  const [affinityFilter, setAffinityFilter] = useState("");
  const [verbFilter, setVerbFilter] = useState("");

  function updateField<K extends keyof SubclassFormValue>(key: K, next: SubclassFormValue[K]) {
    onChange({ ...value, [key]: next });
  }

  function clearSearch(key: string) {
    setResults((current) => ({ ...current, [key]: [] }));
    setSearchText((current) => ({ ...current, [key]: "" }));
  }

  function pickAbility(key: AbilityKind, name: string) {
    updateField(key, name);
    clearSearch(key);
  }

  function pickListItem(key: "aspects" | "fragments", name: string) {
    updateField(key, addPickedName(value[key], name));
    clearSearch(key);
  }

  const refreshOpenResults = useCallback(
    async (nextValue: SubclassFormValue) => {
      const enrichmentFilters = {
        subclassAffinity: affinityFilter || undefined,
        verb: verbFilter || undefined,
      };
      const openKeys = Object.keys(results).filter((key) => results[key]?.length);
      const nextResults = await Promise.all(
        openKeys.map(async (key) => {
          const field = ABILITY_FIELDS.find((item) => item.key === key);
          const category = field ? "abilities" : (key as SearchCategory);
          const found = await fetchResults(
            nextValue,
            key,
            category,
            searchText[key] ?? "",
            field?.key,
            enrichmentFilters,
          );
          return [key, found] as const;
        }),
      );
      setResults((current) => ({ ...current, ...Object.fromEntries(nextResults) }));
    },
    [affinityFilter, results, searchText, verbFilter],
  );

  const applyScopedValue = useCallback(
    async (nextValue: SubclassFormValue) => {
      onChange(nextValue);
      setError(null);
      try {
        const validNames = await fetchValidNames(nextValue);
        const cleaned = clearIncompatibleSubclassSelections(nextValue, validNames);
        onChange(cleaned);
        await refreshOpenResults(cleaned);
      } catch (err) {
        setError(err instanceof Error ? err.message : "Failed to refresh subclass scope");
      }
    },
    [onChange, refreshOpenResults],
  );

  useEffect(() => {
    const subclassNames: readonly string[] = SUBCLASSES_BY_CLASS[className];
    if (subclassNames.includes(value.name)) return;
    queueMicrotask(() => {
      void applyScopedValue({ ...value, name: subclassNames[0] });
    });
  }, [applyScopedValue, className, value]);

  async function search(key: string, category: SearchCategory, kind?: AbilityKind) {
    const q = (searchText[key] ?? "").trim();
    setError(null);
    try {
      const found = await fetchResults(value, key, category, q, kind, {
        subclassAffinity: affinityFilter || undefined,
        verb: verbFilter || undefined,
      });
      setResults((current) => ({ ...current, [key]: found }));
    } catch (err) {
      setError(err instanceof Error ? err.message : "Search failed");
      setResults((current) => ({ ...current, [key]: [] }));
    }
  }

  return (
    <div className="space-y-3 rounded border border-zinc-800 p-3">
      <label className="block text-sm">
        Subclass
        <select
          className="mt-1 block w-full rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
          value={value.name}
          onChange={(event) => void applyScopedValue({ ...value, name: event.target.value })}
        >
          {SUBCLASSES_BY_CLASS[className].map((subclass) => (
            <option key={subclass} value={subclass}>
              {subclass}
            </option>
          ))}
        </select>
      </label>

      <div className="grid gap-2 sm:grid-cols-2">
        <label className="block text-sm">
          Affinity filter (optional)
          <input
            className="mt-1 block w-full rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
            placeholder="e.g. Dawnblade or Prismatic Warlock"
            value={affinityFilter}
            onChange={(event) => setAffinityFilter(event.target.value)}
          />
        </label>
        <label className="block text-sm">
          Verb filter (optional)
          <select
            className="mt-1 block w-full rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
            value={verbFilter}
            onChange={(event) => setVerbFilter(event.target.value)}
          >
            <option value="">Any verb</option>
            {SYNERGY_VERB_NAMES.map((verb) => (
              <option key={verb} value={verb}>
                {verb}
              </option>
            ))}
          </select>
        </label>
      </div>

      {ABILITY_FIELDS.map((field) => (
        <div key={field.key} className="space-y-1">
          <div className="flex items-center justify-between gap-2">
            <span className="text-sm">{field.label}</span>
            {value[field.key] ? (
              <button
                type="button"
                className="rounded bg-zinc-800 px-2 py-0.5 text-xs"
                onClick={() => updateField(field.key, "")}
              >
                Clear
              </button>
            ) : null}
          </div>
          <p className="rounded border border-zinc-800 bg-zinc-950 px-2 py-1 text-sm text-zinc-200">
            {value[field.key] || <span className="text-zinc-500">Pick from search…</span>}
          </p>
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
          <SearchResults results={results[field.key] ?? []} onPick={(item) => pickAbility(field.key, item.name)} />
        </div>
      ))}

      <ListField
        label="Aspects"
        fieldKey="aspects"
        value={value.aspects}
        searchText={searchText.aspects ?? ""}
        results={results.aspects ?? []}
        onRemove={(name) => updateField("aspects", removePickedName(value.aspects, name))}
        onSearchTextChange={(next) => setSearchText((current) => ({ ...current, aspects: next }))}
        onSearch={() => void search("aspects", "aspects")}
        onPick={(item) => pickListItem("aspects", item.name)}
      />
      <ListField
        label="Fragments"
        fieldKey="fragments"
        value={value.fragments}
        searchText={searchText.fragments ?? ""}
        results={results.fragments ?? []}
        onRemove={(name) => updateField("fragments", removePickedName(value.fragments, name))}
        onSearchTextChange={(next) => setSearchText((current) => ({ ...current, fragments: next }))}
        onSearch={() => void search("fragments", "fragments")}
        onPick={(item) => pickListItem("fragments", item.name)}
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
          {item.verbs?.length ? (
            <span className="ml-2 text-zinc-500">{item.verbs.join(", ")}</span>
          ) : null}
          {item.subclassAffinities?.length ? (
            <span className="ml-2 text-zinc-600">{item.subclassAffinities.join(", ")}</span>
          ) : null}
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
  onRemove,
  onSearchTextChange,
  onSearch,
  onPick,
}: {
  label: string;
  fieldKey: string;
  value: string[];
  searchText: string;
  results: SearchResult[];
  onRemove: (name: string) => void;
  onSearchTextChange: (next: string) => void;
  onSearch: () => void;
  onPick: (item: SearchResult) => void;
}) {
  return (
    <div className="space-y-1">
      <span className="block text-sm">{label}</span>
      <div className="flex flex-wrap gap-1">
        {value.length === 0 ? (
          <span className="text-xs text-zinc-500">Pick from search…</span>
        ) : (
          value.map((name) => (
            <button
              key={name}
              type="button"
              className="rounded border border-zinc-700 bg-zinc-900 px-2 py-0.5 text-xs hover:border-red-700"
              onClick={() => onRemove(name)}
              title="Remove"
            >
              {name} ×
            </button>
          ))
        )}
      </div>
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
