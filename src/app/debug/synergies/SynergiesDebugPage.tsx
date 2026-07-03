"use client";

import { useCallback, useRef, useMemo, useState } from "react";

import { CREATABLE_SYNERGY_TYPES } from "@/lib/synergies/schemas";
import { generateSynergyName, getSynergyTypeLabel } from "@/lib/synergies/generateSynergyName";
import { requiresSubType } from "@/lib/synergies/synergyTypeRules";
import type { SynergyLinkInput } from "@/lib/synergies/schemas";
import type { SynergyPickerItem } from "@/lib/synergies/synergyPickerLinks";
import { compareDisplayName, sortByName } from "@/lib/sortByName";

type JsonPanel = {
  label: string;
  request?: unknown;
  response?: unknown;
  error?: unknown;
};

type SubTypeOption = { id: string; name: string; description?: string };

type WeaponOption = { hash: number; name: string; description?: string };

const LINK_KINDS = ["weapon", "weapon_perk", "origin_trait", "armor_set_bonus"] as const;

const SORTED_SYNERGY_TYPES = [...CREATABLE_SYNERGY_TYPES].sort((a, b) =>
  compareDisplayName(getSynergyTypeLabel(a), getSynergyTypeLabel(b)),
);

const SORTED_LINK_KINDS = [...LINK_KINDS].sort((a, b) => compareDisplayName(a, b));

function linkItemSelectValue(
  linkKind: (typeof LINK_KINDS)[number],
  item: SynergyPickerItem | WeaponOption,
): string {
  if (linkKind === "weapon" && "hash" in item) return String(item.hash);
  if ("kind" in item) return `${item.kind}-${item.name}`;
  return "";
}

export function SynergiesDebugPage() {
  const [panel, setPanel] = useState<JsonPanel>({ label: "Ready" });
  const [synergies, setSynergies] = useState<Array<{ id: string; name: string; type: string }>>([]);
  const [selectedId, setSelectedId] = useState("");
  const [filterType, setFilterType] = useState("");

  const [form, setForm] = useState({
    type: "verb",
    subType: "",
    description: "",
    linkKind: "origin_trait" as (typeof LINK_KINDS)[number],
  });

  const [subTypeOptions, setSubTypeOptions] = useState<SubTypeOption[]>([]);
  const [subTypeSearch, setSubTypeSearch] = useState("");
  const [linkSearch, setLinkSearch] = useState("");
  const [linkOptions, setLinkOptions] = useState<SynergyPickerItem[]>([]);
  const [weaponOptions, setWeaponOptions] = useState<WeaponOption[]>([]);
  const [selectedLink, setSelectedLink] = useState<SynergyPickerItem | WeaponOption | null>(null);
  const [linkDescription, setLinkDescription] = useState("");

  const [lookupKind, setLookupKind] = useState("origin_trait");
  const [lookupName, setLookupName] = useState("Cast No Shadows");
  const [lookupItemHash, setLookupItemHash] = useState("");

  const needsSubType = requiresSubType(form.type as (typeof CREATABLE_SYNERGY_TYPES)[number] & string);

  const previewName = useMemo(() => {
    const linkDisplayName = selectedLink?.name ?? "Unlinked";
    return generateSynergyName({
      type: form.type as Parameters<typeof generateSynergyName>[0]["type"],
      subType: needsSubType ? form.subType || null : null,
      linkDisplayName,
    });
  }, [form.type, form.subType, needsSubType, selectedLink]);

  const loadSubTypes = useCallback(async (category: string, query = "") => {
    if (!requiresSubType(category as never)) {
      setSubTypeOptions([]);
      return;
    }
    const params = new URLSearchParams({ category });
    if (query.trim()) {
      params.set("q", query.trim());
      params.set("limit", "100");
    }
    const res = await fetch(`/api/catalog/synergy-pickers/subtypes?${params}`);
    const body = await res.json();
    if (res.ok) {
      setSubTypeOptions(body.options ?? []);
      if (body.options?.[0]?.name) {
        setForm((f) => ({ ...f, subType: f.subType || body.options[0].name }));
      }
    }
  }, []);

  const subTypesLoadedFor = useRef<string | null>(null);

  const ensureSubTypes = useCallback(
    (category: string) => {
      if (!requiresSubType(category as never)) {
        setSubTypeOptions([]);
        return;
      }
      if (subTypesLoadedFor.current === category) return;
      subTypesLoadedFor.current = category;
      void loadSubTypes(category);
    },
    [loadSubTypes],
  );

  const handleTypeChange = (nextType: string) => {
    subTypesLoadedFor.current = null;
    setSubTypeSearch("");
    setForm({ ...form, type: nextType, subType: "" });
    ensureSubTypes(nextType);
  };

  const searchLinks = useCallback(async () => {
    setSelectedLink(null);
    setLinkDescription("");
    if (form.linkKind === "weapon") {
      const params = new URLSearchParams({ q: linkSearch, limit: "30" });
      const res = await fetch(`/api/catalog/weapons?${params}`);
      const body = await res.json();
      if (res.ok) {
        setWeaponOptions(
          sortByName(
            (body.items ?? []).map((i: { hash: number; name: string; description?: string }) => ({
              hash: i.hash,
              name: i.name,
              description: i.description ?? "",
            })),
          ),
        );
      }
      return;
    }
    const params = new URLSearchParams({ kind: form.linkKind, q: linkSearch });
    if (linkSearch.trim()) {
      params.set("limit", "100");
    }
    const res = await fetch(`/api/catalog/synergy-pickers/links?${params}`);
    const body = await res.json();
    if (res.ok) setLinkOptions(sortByName(body.items ?? []));
  }, [form.linkKind, linkSearch]);

  function selectLinkItem(item: SynergyPickerItem | WeaponOption) {
    setSelectedLink(item);
    setLinkDescription(item.description ?? "");
  }

  function buildLink(): SynergyLinkInput | null {
    if (!selectedLink) return null;
    if (form.linkKind === "weapon" && "hash" in selectedLink && !("kind" in selectedLink)) {
      return { kind: "weapon", displayName: selectedLink.name, itemHash: selectedLink.hash };
    }
    const picker = selectedLink as SynergyPickerItem;
    const base = { kind: picker.kind, displayName: picker.name };
    switch (picker.kind) {
      case "origin_trait":
        return { ...base, originTraitName: picker.originTraitName, originTraitHash: picker.originTraitHash };
      case "weapon_perk":
        return { ...base, perkHash: picker.perkHash };
      case "armor_set_bonus":
        return {
          ...base,
          armorSetName: picker.armorSetName!,
          bonusPieces: picker.bonusPieces!,
          bonusName: picker.bonusName!,
          armorSetHash: picker.armorSetHash,
        };
      default:
        return null;
    }
  }

  async function loadSynergies() {
    const params = filterType ? `?type=${filterType}` : "";
    const url = `/api/user/synergies${params}`;
    const res = await fetch(url);
    const body = await res.json();
    if (res.ok) setSynergies(sortByName(body.synergies ?? []));
    setPanel({ label: `GET ${url}`, response: body, error: res.ok ? undefined : body });
  }

  async function createSynergy() {
    const link = buildLink();
    if (!link) {
      setPanel({ label: "Create blocked", error: { message: "Select a link from catalog pickers" } });
      return;
    }
    const payload = {
      type: form.type,
      subType: needsSubType ? form.subType : null,
      description: form.description,
      links: [link],
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
    setPanel({
      label: "POST /api/user/synergies",
      request: payload,
      response: res.ok ? body : undefined,
      error: res.ok ? undefined : body,
    });
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
    if (lookupKind === "weapon" && lookupItemHash.trim()) {
      params.set("itemHash", lookupItemHash.trim());
    } else if (lookupName.trim()) {
      params.set("name", lookupName.trim());
    }
    const url = `/api/user/synergies/by-target?${params}`;
    const res = await fetch(url);
    const body = await res.json();
    setPanel({ label: "GET " + url, response: body, error: res.ok ? undefined : body });
  }

  return (
    <div className="grid min-w-0 gap-6 lg:grid-cols-2 [&>*]:min-w-0">
      <section className="space-y-4">
        <h1 className="text-lg font-semibold">Synergies</h1>

        <fieldset className="min-w-0 space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">List</legend>
          <select className="rounded bg-zinc-900 px-2 py-1 text-sm" value={filterType} onChange={(e) => setFilterType(e.target.value)}>
            <option value="">(any type)</option>
            {SORTED_SYNERGY_TYPES.map((t) => (
              <option key={t} value={t}>{getSynergyTypeLabel(t)}</option>
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

        <fieldset
          className="min-w-0 space-y-2 rounded border border-zinc-800 p-3"
          onFocus={() => ensureSubTypes(form.type)}
        >
          <legend className="px-1 text-sm">Create synergy + link</legend>
          <label className="block text-xs text-zinc-400">Auto-generated name</label>
          <p className="min-w-0 break-words rounded bg-zinc-950 px-2 py-1 text-sm text-zinc-300">{previewName}</p>

          <select
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            value={form.type}
            onChange={(e) => handleTypeChange(e.target.value)}
          >
            {SORTED_SYNERGY_TYPES.map((t) => (
              <option key={t} value={t}>{getSynergyTypeLabel(t)}</option>
            ))}
          </select>

          {needsSubType && (
            <>
              {form.type === "weapon_archetype" && (
                <div className="flex gap-2">
                  <input
                    className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
                    placeholder="Filter archetypes…"
                    value={subTypeSearch}
                    onChange={(e) => setSubTypeSearch(e.target.value)}
                  />
                  <button
                    type="button"
                    className="rounded bg-zinc-800 px-2 py-1 text-xs"
                    onClick={() => {
                      subTypesLoadedFor.current = null;
                      void loadSubTypes(form.type, subTypeSearch);
                    }}
                  >
                    Search
                  </button>
                </div>
              )}
              <select
                className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
                value={form.subType}
                onChange={(e) => setForm({ ...form, subType: e.target.value })}
              >
                <option value="">— select sub-type —</option>
                {subTypeOptions.map((o) => (
                  <option key={o.id} value={o.name}>{o.name}</option>
                ))}
              </select>
              {subTypeOptions.length > 0 ? (
                <ul className="max-h-40 space-y-1 overflow-auto text-xs">
                  {subTypeOptions.map((o) => (
                    <li key={o.id}>
                      <button
                        type="button"
                        className={`w-full rounded px-2 py-1 text-left ${
                          form.subType === o.name ? "bg-emerald-900" : "bg-zinc-950 hover:bg-zinc-900"
                        }`}
                        onClick={() => setForm({ ...form, subType: o.name })}
                      >
                        <div>{o.name}</div>
                        <div className="text-zinc-500">
                          {o.description?.trim() ? o.description : "Description unavailable"}
                        </div>
                      </button>
                    </li>
                  ))}
                </ul>
              ) : null}
            </>
          )}

          <select
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            value={form.linkKind}
            onChange={(e) => {
              setForm({ ...form, linkKind: e.target.value as typeof form.linkKind });
              setSelectedLink(null);
              setLinkDescription("");
              setLinkOptions([]);
              setWeaponOptions([]);
            }}
          >
            {SORTED_LINK_KINDS.map((k) => (
              <option key={k} value={k}>{k}</option>
            ))}
          </select>

          <div className="flex gap-2">
            <input
              className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
              placeholder="Search catalog…"
              value={linkSearch}
              onChange={(e) => setLinkSearch(e.target.value)}
            />
            <button type="button" className="rounded bg-zinc-700 px-3 py-1 text-sm" onClick={() => void searchLinks()}>
              Search
            </button>
          </div>

          <select
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            value={selectedLink ? linkItemSelectValue(form.linkKind, selectedLink) : ""}
            onChange={(e) => {
              if (form.linkKind === "weapon") {
                const w = weaponOptions.find((o) => String(o.hash) === e.target.value);
                if (w) selectLinkItem(w);
              } else {
                const item = linkOptions.find(
                  (o) => `${o.kind}-${o.name}` === e.target.value,
                );
                if (item) selectLinkItem(item);
              }
            }}
          >
            <option value="">— select link —</option>
            {form.linkKind === "weapon"
              ? weaponOptions.map((w) => (
                  <option key={w.hash} value={String(w.hash)}>{w.name}</option>
                ))
              : linkOptions.map((o) => (
                  <option key={`${o.kind}-${o.name}`} value={`${o.kind}-${o.name}`}>{o.name}</option>
                ))}
          </select>

          {(form.linkKind === "weapon" ? weaponOptions : linkOptions).length > 0 ? (
            <ul className="max-h-48 space-y-1 overflow-auto text-xs">
              {(form.linkKind === "weapon" ? weaponOptions : linkOptions).map((item) => {
                const key =
                  form.linkKind === "weapon" && "hash" in item
                    ? String(item.hash)
                    : `${(item as SynergyPickerItem).kind}-${item.name}`;
                const selected =
                  form.linkKind === "weapon"
                    ? selectedLink && "hash" in selectedLink && selectedLink.hash === (item as WeaponOption).hash
                    : selectedLink &&
                      "kind" in selectedLink &&
                      selectedLink.kind === (item as SynergyPickerItem).kind &&
                      selectedLink.name === item.name;
                return (
                  <li key={key}>
                    <button
                      type="button"
                      className={`w-full rounded px-2 py-1 text-left ${
                        selected ? "bg-emerald-900" : "bg-zinc-950 hover:bg-zinc-900"
                      }`}
                      onClick={() => selectLinkItem(item as SynergyPickerItem | WeaponOption)}
                    >
                      <div>{item.name}</div>
                      <div className="text-zinc-500">
                        {item.description?.trim() ? item.description : "Description unavailable"}
                      </div>
                    </button>
                  </li>
                );
              })}
            </ul>
          ) : null}

          {linkDescription ? (
            <p className="min-w-0 break-words rounded bg-zinc-950 p-2 text-xs leading-relaxed text-zinc-400">{linkDescription}</p>
          ) : null}

          <button type="button" className="rounded bg-emerald-700 px-3 py-1 text-sm" onClick={() => void createSynergy()}>
            Create
          </button>
        </fieldset>

        <fieldset className="min-w-0 space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Reverse lookup</legend>
          <select className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" value={lookupKind} onChange={(e) => setLookupKind(e.target.value)}>
            {SORTED_LINK_KINDS.map((k) => (
              <option key={k} value={k}>{k}</option>
            ))}
          </select>
          {lookupKind === "weapon" ? (
            <input
              className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
              placeholder="itemHash"
              value={lookupItemHash}
              onChange={(e) => setLookupItemHash(e.target.value)}
            />
          ) : (
            <input
              className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
              placeholder="name"
              value={lookupName}
              onChange={(e) => setLookupName(e.target.value)}
            />
          )}
          <button type="button" className="rounded bg-emerald-700 px-3 py-1 text-sm" onClick={() => void reverseLookup()}>
            Lookup
          </button>
        </fieldset>
      </section>

      <section>
        <h2 className="mb-2 break-words text-sm font-medium">{panel.label}</h2>
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
