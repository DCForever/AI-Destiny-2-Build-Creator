"use client";

import { useMemo, useState } from "react";

import { emptyLookupMessage, synergyIdentityFields } from "@/lib/debug/lookupParity";
import { sortByName } from "@/lib/sortByName";

type Synergy = { id: string; name: string; type: string };

type Props = {
  synergies: Synergy[];
  selectedIds: string[];
  onChange: (ids: string[]) => void;
  filterType?: string;
};

function toggleId(selectedIds: string[], id: string, checked: boolean): string[] {
  if (checked) return selectedIds.includes(id) ? selectedIds : [...selectedIds, id];
  return selectedIds.filter((selectedId) => selectedId !== id);
}

export function SynergyMultiSelect({ synergies, selectedIds, onChange, filterType }: Props) {
  const [nameFilter, setNameFilter] = useState("");
  const [internalType, setInternalType] = useState("");
  const activeType = filterType ?? internalType;
  const typeOptions = useMemo(
    () => [...new Set(synergies.map((synergy) => synergy.type))].sort(),
    [synergies],
  );
  const filtered = useMemo(() => {
    const name = nameFilter.trim().toLowerCase();
    return sortByName(
      synergies.filter((synergy) => {
        const identity = synergyIdentityFields(synergy);
        const matchesName = !name || identity.name.toLowerCase().includes(name);
        const matchesType = !activeType || identity.type === activeType;
        return matchesName && matchesType;
      }),
    );
  }, [activeType, nameFilter, synergies]);

  if (synergies.length === 0) {
    return (
      <div className="rounded border border-zinc-800 p-3 text-sm">
        <p className="text-zinc-400">{emptyLookupMessage("synergy")}</p>
        <a className="text-emerald-300 underline" href="/debug/synergies">
          Create a synergy first
        </a>
      </div>
    );
  }

  return (
    <div className="space-y-2 rounded border border-zinc-800 p-3">
      <div className="grid gap-2 sm:grid-cols-2">
        <input
          className="rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
          placeholder="Filter synergies by name"
          value={nameFilter}
          onChange={(event) => setNameFilter(event.target.value)}
        />
        <select
          className="rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
          value={activeType}
          disabled={filterType !== undefined}
          onChange={(event) => setInternalType(event.target.value)}
        >
          <option value="">All synergy types</option>
          {typeOptions.map((type) => (
            <option key={type} value={type}>
              {type}
            </option>
          ))}
        </select>
      </div>
      {filtered.length === 0 ? <p className="text-xs text-zinc-500">{emptyLookupMessage("synergy")}</p> : null}
      <div className="max-h-56 space-y-1 overflow-auto">
        {filtered.map((synergy) => {
          const identity = synergyIdentityFields(synergy);
          return (
            <label
              key={identity.id}
              className="flex items-start gap-2 rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
            >
              <input
                type="checkbox"
                className="mt-1"
                checked={selectedIds.includes(identity.id)}
                onChange={(event) => onChange(toggleId(selectedIds, identity.id, event.target.checked))}
              />
              <span>
                <span className="font-medium">{identity.name}</span>
                <span className="ml-2 text-xs text-zinc-500">
                  {identity.type} · {identity.id}
                </span>
              </span>
            </label>
          );
        })}
      </div>
    </div>
  );
}
