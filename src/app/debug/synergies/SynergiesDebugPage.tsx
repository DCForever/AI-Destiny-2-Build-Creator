"use client";

import { useState } from "react";

import { SYNERGY_TYPES } from "@/lib/synergies/schemas";

type JsonPanel = {
  label: string;
  request?: unknown;
  response?: unknown;
  error?: unknown;
};

const LINK_KINDS = ["weapon", "weapon_perk", "origin_trait", "armor_set_bonus"] as const;

export function SynergiesDebugPage() {
  const [panel, setPanel] = useState<JsonPanel>({ label: "Ready" });
  const [synergies, setSynergies] = useState<Array<{ id: string; name: string; type: string }>>([]);
  const [selectedId, setSelectedId] = useState("");
  const [filterType, setFilterType] = useState("");

  const [form, setForm] = useState({
    name: "Melee — Cast No Shadows",
    type: "melee",
    description: "",
    linkKind: "origin_trait" as (typeof LINK_KINDS)[number],
    displayName: "Cast No Shadows",
    originTraitName: "Cast No Shadows",
    armorSetName: "Eutechnology",
    bonusPieces: "2",
    bonusName: "Gift of the Ley Lines",
    itemHash: "",
    perkHash: "",
  });

  const [lookupKind, setLookupKind] = useState("origin_trait");
  const [lookupName, setLookupName] = useState("Cast No Shadows");

  function buildLink() {
    const base = { kind: form.linkKind, displayName: form.displayName };
    switch (form.linkKind) {
      case "origin_trait":
        return { ...base, originTraitName: form.originTraitName };
      case "armor_set_bonus":
        return {
          ...base,
          armorSetName: form.armorSetName,
          bonusPieces: Number(form.bonusPieces) as 2 | 4,
          bonusName: form.bonusName,
        };
      case "weapon":
        return { ...base, itemHash: Number(form.itemHash) };
      case "weapon_perk":
        return { ...base, perkHash: Number(form.perkHash) };
    }
  }

  async function loadSynergies() {
    const params = filterType ? `?type=${filterType}` : "";
    const url = `/api/user/synergies${params}`;
    const res = await fetch(url);
    const body = await res.json();
    if (res.ok) setSynergies(body.synergies ?? []);
    setPanel({ label: `GET ${url}`, response: body, error: res.ok ? undefined : body });
  }

  async function createSynergy() {
    const payload = {
      name: form.name,
      type: form.type,
      description: form.description,
      links: [buildLink()],
    };
    setPanel({ label: "POST /api/user/synergies", request: payload });
    const res = await fetch("/api/user/synergies", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    if (res.ok) {
      setSelectedId(body.synergy?.id ?? "");
      await loadSynergies();
    }
    setPanel({ label: "POST /api/user/synergies", request: payload, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function deleteSynergy() {
    if (!selectedId) return;
    const url = `/api/user/synergies/${selectedId}`;
    const res = await fetch(url, { method: "DELETE" });
    const body = await res.json();
    setPanel({ label: "DELETE " + url, response: body, error: res.ok ? undefined : body });
    if (res.ok) {
      setSelectedId("");
      await loadSynergies();
    }
  }

  async function reverseLookup() {
    const params = new URLSearchParams({ kind: lookupKind });
    if (lookupName.trim()) params.set("name", lookupName.trim());
    const url = `/api/user/synergies/by-target?${params}`;
    const res = await fetch(url);
    const body = await res.json();
    setPanel({ label: "GET " + url, response: body, error: res.ok ? undefined : body });
  }

  return (
    <div className="grid gap-6 lg:grid-cols-2">
      <section className="space-y-4">
        <h1 className="text-lg font-semibold">Synergies</h1>

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">List</legend>
          <select className="rounded bg-zinc-900 px-2 py-1 text-sm" value={filterType} onChange={(e) => setFilterType(e.target.value)}>
            <option value="">(any type)</option>
            {SYNERGY_TYPES.map((t) => (
              <option key={t} value={t}>{t}</option>
            ))}
          </select>
          <button type="button" className="ml-2 rounded bg-zinc-700 px-3 py-1 text-sm" onClick={() => void loadSynergies()}>
            Load
          </button>
          <select className="mt-2 block w-full rounded bg-zinc-900 px-2 py-1 text-sm" value={selectedId} onChange={(e) => setSelectedId(e.target.value)}>
            <option value="">—</option>
            {synergies.map((s) => (
              <option key={s.id} value={s.id}>{s.name} ({s.type})</option>
            ))}
          </select>
          <button type="button" className="rounded bg-red-800 px-3 py-1 text-sm disabled:opacity-40" disabled={!selectedId} onClick={() => void deleteSynergy()}>
            Delete
          </button>
        </fieldset>

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Create synergy + link</legend>
          <input className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          <select className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })}>
            {SYNERGY_TYPES.map((t) => (
              <option key={t} value={t}>{t}</option>
            ))}
          </select>
          <select className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" value={form.linkKind} onChange={(e) => setForm({ ...form, linkKind: e.target.value as typeof form.linkKind })}>
            {LINK_KINDS.map((k) => (
              <option key={k} value={k}>{k}</option>
            ))}
          </select>
          {form.linkKind === "origin_trait" && (
            <input className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" placeholder="originTraitName" value={form.originTraitName} onChange={(e) => setForm({ ...form, originTraitName: e.target.value, displayName: e.target.value })} />
          )}
          {form.linkKind === "armor_set_bonus" && (
            <>
              <input className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" placeholder="armorSetName" value={form.armorSetName} onChange={(e) => setForm({ ...form, armorSetName: e.target.value })} />
              <select className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" value={form.bonusPieces} onChange={(e) => setForm({ ...form, bonusPieces: e.target.value })}>
                <option value="2">2pc</option>
                <option value="4">4pc</option>
              </select>
              <input className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" placeholder="bonusName" value={form.bonusName} onChange={(e) => setForm({ ...form, bonusName: e.target.value })} />
            </>
          )}
          <button type="button" className="rounded bg-emerald-700 px-3 py-1 text-sm" onClick={() => void createSynergy()}>
            Create
          </button>
        </fieldset>

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Reverse lookup</legend>
          <select className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" value={lookupKind} onChange={(e) => setLookupKind(e.target.value)}>
            {LINK_KINDS.map((k) => (
              <option key={k} value={k}>{k}</option>
            ))}
          </select>
          <input className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" placeholder="name" value={lookupName} onChange={(e) => setLookupName(e.target.value)} />
          <button type="button" className="rounded bg-emerald-700 px-3 py-1 text-sm" onClick={() => void reverseLookup()}>
            Lookup
          </button>
        </fieldset>
      </section>

      <section>
        <h2 className="mb-2 text-sm font-medium">{panel.label}</h2>
        {panel.error !== undefined && (
          <pre className="mb-2 overflow-auto rounded bg-red-950/50 p-3 text-xs text-red-200">{JSON.stringify(panel.error, null, 2)}</pre>
        )}
        {panel.request !== undefined && (
          <>
            <p className="text-xs text-zinc-500">Request</p>
            <pre className="mb-2 overflow-auto rounded bg-zinc-900 p-3 text-xs">{JSON.stringify(panel.request, null, 2)}</pre>
          </>
        )}
        {panel.response !== undefined && (
          <>
            <p className="text-xs text-zinc-500">Response</p>
            <pre className="overflow-auto rounded bg-zinc-900 p-3 text-xs">{JSON.stringify(panel.response, null, 2)}</pre>
          </>
        )}
      </section>
    </div>
  );
}
