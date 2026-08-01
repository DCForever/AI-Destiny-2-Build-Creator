"use client";

import { useMemo, useState } from "react";

import { CONCEPT_TAGS } from "@/data/conceptTags";
import { emptyLookupMessage, setIdentityFields } from "@/lib/debug/lookupParity";
import { sortByName } from "@/lib/sortByName";

type SetType = "weapon" | "armor" | "mod" | "pair" | "fashion";
type AttachMode = "live" | "snapshot";
type SetSummary = { id: string; name: string; type: string };

type Props = {
  onAttach: (
    attachment: { setId: string; mode: AttachMode },
    setMeta: SetSummary,
  ) => void;
  disabled?: boolean;
};

const SET_TYPES: SetType[] = ["weapon", "armor", "mod", "pair", "fashion"];

export function SetAttachPicker({ onAttach, disabled = false }: Props) {
  const [type, setType] = useState<SetType>("weapon");
  const [tags, setTags] = useState("");
  const [sets, setSets] = useState<SetSummary[]>([]);
  const [selectedSetId, setSelectedSetId] = useState("");
  const [mode, setMode] = useState<AttachMode>("live");
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const selectedSet = useMemo(
    () => sets.find((set) => set.id === selectedSetId) ?? null,
    [selectedSetId, sets],
  );

  async function loadSets() {
    setIsLoading(true);
    setError(null);
    const params = new URLSearchParams({ type });
    if (tags.trim()) params.set("tags", tags.trim());
    const res = await fetch(`/api/user/sets?${params}`);
    const body = await res.json();
    setIsLoading(false);

    if (!res.ok) {
      setError(body.error ?? "Failed to load sets");
      setSets([]);
      setSelectedSetId("");
      return;
    }

    const rows = sortByName((body.sets ?? []) as SetSummary[]);
    setSets(rows);
    setSelectedSetId((current) => (rows.some((set) => set.id === current) ? current : rows[0]?.id ?? ""));
  }

  function toggleTag(tagId: string, checked: boolean) {
    const current = tags.split(",").map((tag) => tag.trim()).filter(Boolean);
    const next = checked ? [...new Set([...current, tagId])] : current.filter((tag) => tag !== tagId);
    setTags(next.join(","));
  }

  return (
    <div className="space-y-2 rounded border border-zinc-800 p-3">
      <div className="grid gap-2 sm:grid-cols-2">
        <select
          className="rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
          value={type}
          disabled={disabled}
          onChange={(event) => setType(event.target.value as SetType)}
        >
          {SET_TYPES.map((setType) => (
            <option key={setType} value={setType}>
              {setType}
            </option>
          ))}
        </select>
        <input
          className="rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
          placeholder="Tags comma filter"
          value={tags}
          disabled={disabled}
          onChange={(event) => setTags(event.target.value)}
        />
      </div>
      <div className="flex flex-wrap gap-2 text-xs text-zinc-300">
        {CONCEPT_TAGS.map((tag) => (
          <label key={tag.id} className="flex items-center gap-1">
            <input
              type="checkbox"
              disabled={disabled}
              checked={tags.split(",").map((value) => value.trim()).includes(tag.id)}
              onChange={(event) => toggleTag(tag.id, event.target.checked)}
            />
            {tag.label}
          </label>
        ))}
      </div>
      <button type="button" className="rounded bg-zinc-700 px-3 py-1 text-sm disabled:opacity-50" disabled={disabled || isLoading} onClick={() => void loadSets()}>
        {isLoading ? "Loading..." : "Load sets"}
      </button>
      {error ? <p className="text-xs text-red-300">{error}</p> : null}
      {!isLoading && sets.length === 0 ? (
        <p className="text-xs text-zinc-500">
          {emptyLookupMessage("set")}{" "}
          <a className="text-emerald-300 underline" href="/debug/sets">
            Create a set first
          </a>
        </p>
      ) : null}
      {sets.length > 0 ? (
        <div className="grid gap-2 sm:grid-cols-[1fr_auto_auto]">
          <select
            className="min-w-0 rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
            value={selectedSetId}
            disabled={disabled}
            onChange={(event) => setSelectedSetId(event.target.value)}
          >
            {sets.map((set) => {
              const identity = setIdentityFields(set);
              return (
                <option key={identity.id} value={identity.id}>
                  {identity.name} ({identity.type})
                </option>
              );
            })}
          </select>
          <select
            className="rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
            value={mode}
            disabled={disabled}
            onChange={(event) => setMode(event.target.value as AttachMode)}
          >
            <option value="live">live</option>
            <option value="snapshot">snapshot</option>
          </select>
          <button
            type="button"
            className="rounded bg-emerald-700 px-3 py-1 text-sm disabled:opacity-50"
            disabled={disabled || !selectedSet}
            onClick={() => {
              if (selectedSet) onAttach({ setId: selectedSet.id, mode }, selectedSet);
            }}
          >
            Attach
          </button>
        </div>
      ) : null}
    </div>
  );
}
