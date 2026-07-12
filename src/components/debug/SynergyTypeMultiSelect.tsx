"use client";

import { useEffect, useMemo, useState } from "react";

import { CREATABLE_SYNERGY_TYPES } from "@/lib/synergies/schemas";
import {
  formatSynergyTypeDesignation,
  getSynergyTypeLabel,
  synergyTypeDesignationKey,
} from "@/lib/synergies/generateSynergyName";
import { requiresSubType } from "@/lib/synergies/synergyTypeRules";
import { compareDisplayName } from "@/lib/sortByName";

export type SynergyTypeSelection = {
  type: (typeof CREATABLE_SYNERGY_TYPES)[number];
  subType: string | null;
};

type SubTypeOption = { name: string; value?: string };

const SORTED_TYPES = [...CREATABLE_SYNERGY_TYPES].sort((a, b) =>
  compareDisplayName(getSynergyTypeLabel(a), getSynergyTypeLabel(b)),
);

type Props = {
  selected: SynergyTypeSelection[];
  onChange: (next: SynergyTypeSelection[]) => void;
};

function selectionKey(s: SynergyTypeSelection): string {
  return synergyTypeDesignationKey(s);
}

export function SynergyTypeMultiSelect({ selected, onChange }: Props) {
  const [draftType, setDraftType] = useState<(typeof CREATABLE_SYNERGY_TYPES)[number]>("verb");
  const [draftSubType, setDraftSubType] = useState("");
  const [subTypeOptions, setSubTypeOptions] = useState<SubTypeOption[]>([]);
  const needsSub = requiresSubType(draftType);

  useEffect(() => {
    if (!needsSub) return;
    let cancelled = false;
    void (async () => {
      const res = await fetch(
        `/api/catalog/synergy-pickers/subtypes?category=${encodeURIComponent(draftType)}`,
      );
      if (!res.ok || cancelled) return;
      const body = (await res.json()) as { options?: SubTypeOption[] };
      const options = body.options ?? [];
      setSubTypeOptions(options);
      setDraftSubType((prev) => prev || options[0]?.name || "");
    })();
    return () => {
      cancelled = true;
    };
  }, [draftType, needsSub]);

  function changeDraftType(next: (typeof CREATABLE_SYNERGY_TYPES)[number]) {
    setDraftType(next);
    if (!requiresSubType(next)) {
      setSubTypeOptions([]);
      setDraftSubType("");
    } else {
      setDraftSubType("");
      setSubTypeOptions([]);
    }
  }

  const selectedKeys = useMemo(() => new Set(selected.map(selectionKey)), [selected]);

  function addDraft() {
    if (needsSub && !draftSubType.trim()) return;
    const next: SynergyTypeSelection = {
      type: draftType,
      subType: needsSub ? draftSubType.trim() : null,
    };
    const key = selectionKey(next);
    if (selectedKeys.has(key)) return;
    onChange([...selected, next]);
  }

  function remove(key: string) {
    onChange(selected.filter((s) => selectionKey(s) !== key));
  }

  return (
    <div className="space-y-2 rounded border border-zinc-800 p-3">
      <div className="grid gap-2 sm:grid-cols-3">
        <select
          className="rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
          value={draftType}
          onChange={(e) =>
            changeDraftType(e.target.value as (typeof CREATABLE_SYNERGY_TYPES)[number])
          }
        >
          {SORTED_TYPES.map((t) => (
            <option key={t} value={t}>
              {getSynergyTypeLabel(t)}
            </option>
          ))}
        </select>
        {needsSub ? (
          <select
            className="rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
            value={draftSubType}
            onChange={(e) => setDraftSubType(e.target.value)}
          >
            {subTypeOptions.length === 0 ? <option value="">Loading…</option> : null}
            {subTypeOptions.map((o) => (
              <option key={o.name} value={o.name}>
                {o.name}
              </option>
            ))}
          </select>
        ) : (
          <div className="rounded border border-zinc-800 bg-zinc-950 px-2 py-1 text-xs text-zinc-500">
            No sub-type for this category
          </div>
        )}
        <button
          type="button"
          className="rounded border border-emerald-800 bg-emerald-950 px-2 py-1 text-sm text-emerald-200"
          onClick={addDraft}
          disabled={needsSub && !draftSubType.trim()}
        >
          Add type
        </button>
      </div>
      {selected.length === 0 ? (
        <p className="text-xs text-zinc-500">Designate at least one Synergy Type (intent).</p>
      ) : (
        <ul className="space-y-1">
          {selected.map((s) => {
            const key = selectionKey(s);
            return (
              <li
                key={key}
                className="flex items-center justify-between gap-2 rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
              >
                <span>{formatSynergyTypeDesignation(s)}</span>
                <button
                  type="button"
                  className="text-xs text-zinc-400 underline"
                  onClick={() => remove(key)}
                >
                  Remove
                </button>
              </li>
            );
          })}
        </ul>
      )}
    </div>
  );
}
