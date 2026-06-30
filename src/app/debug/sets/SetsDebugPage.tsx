"use client";

import { useCallback, useState } from "react";

import { CONCEPT_TAGS } from "@/data/conceptTags";
import { SET_TYPES, WEAPON_SLOTS, ARMOR_SLOTS } from "@/lib/sets/schemas";

type JsonPanel = {
  label: string;
  request?: unknown;
  response?: unknown;
  error?: { code?: string; message?: string; details?: unknown };
};

const SLOTS_BY_TYPE: Record<string, string[]> = {
  weapon: [...WEAPON_SLOTS],
  armor: [...ARMOR_SLOTS],
  pair: ["exotic_weapon", "exotic_armor"],
};

export function SetsDebugPage() {
  const [sets, setSets] = useState<unknown[]>([]);
  const [selectedId, setSelectedId] = useState("");
  const [panel, setPanel] = useState<JsonPanel>({ label: "Ready" });
  const [pendingReplace, setPendingReplace] = useState<Record<string, unknown> | null>(null);

  const [createForm, setCreateForm] = useState({
    name: "Solar PVE",
    type: "weapon",
    tagIds: ["solar", "pve"] as string[],
  });
  const [filterTags, setFilterTags] = useState("");
  const [filterType, setFilterType] = useState("");
  const [itemForm, setItemForm] = useState({
    slot: "primary",
    itemHash: "999001",
    itemName: "Debug Weapon",
    selectedPerks: "",
  });

  const record = useCallback((next: JsonPanel) => setPanel(next), []);

  const loadSets = useCallback(async () => {
    const params = new URLSearchParams();
    if (filterType) params.set("type", filterType);
    if (filterTags.trim()) params.set("tags", filterTags.trim());
    const url = `/api/user/sets${params.toString() ? `?${params}` : ""}`;
    record({ label: "GET /api/user/sets", request: { url } });
    const res = await fetch(url);
    const body = await res.json();
    if (!res.ok) {
      record({ label: "GET /api/user/sets", request: { url }, error: body });
      return;
    }
    setSets(body.sets ?? []);
    record({ label: "GET /api/user/sets", request: { url }, response: body });
  }, [filterTags, filterType, record]);

  async function createSet() {
    const payload = createForm;
    record({ label: "POST /api/user/sets", request: payload });
    const res = await fetch("/api/user/sets", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    if (!res.ok) {
      record({ label: "POST /api/user/sets", request: payload, error: body });
      return;
    }
    setSelectedId(body.set?.id ?? "");
    record({ label: "POST /api/user/sets", request: payload, response: body });
    await loadSets();
  }

  async function addItem(confirmReplace = false) {
    if (!selectedId) return;
    const payload: Record<string, unknown> = {
      slot: itemForm.slot,
      itemHash: Number(itemForm.itemHash),
      itemName: itemForm.itemName,
    };
    if (itemForm.selectedPerks.trim()) {
      payload.selectedPerks = itemForm.selectedPerks.split(",").map((s) => Number(s.trim()));
    }
    if (confirmReplace) payload.confirmReplace = true;

    const url = `/api/user/sets/${selectedId}/items`;
    record({ label: "PUT " + url, request: payload });
    const res = await fetch(url, {
      method: "PUT",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    if (res.status === 409 && body.code === "SLOT_OCCUPIED") {
      setPendingReplace(payload);
      record({ label: "PUT " + url, request: payload, error: body });
      return;
    }
    setPendingReplace(null);
    if (!res.ok) {
      record({ label: "PUT " + url, request: payload, error: body });
      return;
    }
    record({ label: "PUT " + url, request: payload, response: body });
  }

  async function deleteSet() {
    if (!selectedId) return;
    const url = `/api/user/sets/${selectedId}`;
    record({ label: "DELETE " + url });
    const res = await fetch(url, { method: "DELETE" });
    const body = await res.json();
    if (!res.ok) {
      record({ label: "DELETE " + url, error: body });
      return;
    }
    setSelectedId("");
    record({ label: "DELETE " + url, response: body });
    await loadSets();
  }

  async function suggestRollsForSet() {
    if (!selectedId) return;
    const payload = { setId: selectedId };
    const res = await fetch("/api/user/suggestions/rolls", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    record({
      label: "POST /api/user/suggestions/rolls",
      request: payload,
      response: res.ok ? body : undefined,
      error: res.ok ? undefined : body,
    });
  }

  const slots = SLOTS_BY_TYPE[createForm.type] ?? WEAPON_SLOTS;

  return (
    <div className="grid min-w-0 gap-6 lg:grid-cols-2 [&>*]:min-w-0">
      <section className="space-y-4">
        <h1 className="text-lg font-semibold">Sets</h1>

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Filter list</legend>
          <label className="block text-sm">
            Type
            <select
              className="ml-2 rounded bg-zinc-900 px-2 py-1"
              value={filterType}
              onChange={(e) => setFilterType(e.target.value)}
            >
              <option value="">(any)</option>
              {SET_TYPES.map((t) => (
                <option key={t} value={t}>
                  {t}
                </option>
              ))}
            </select>
          </label>
          <label className="block text-sm">
            Tags (comma, AND)
            <input
              className="ml-2 w-48 rounded bg-zinc-900 px-2 py-1"
              value={filterTags}
              onChange={(e) => setFilterTags(e.target.value)}
              placeholder="solar,pve"
            />
          </label>
          <button type="button" className="rounded bg-zinc-700 px-3 py-1 text-sm" onClick={() => void loadSets()}>
            Load / refresh
          </button>
        </fieldset>

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Create set</legend>
          <input
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            value={createForm.name}
            onChange={(e) => setCreateForm({ ...createForm, name: e.target.value })}
            placeholder="Name"
          />
          <select
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            value={createForm.type}
            onChange={(e) => setCreateForm({ ...createForm, type: e.target.value })}
          >
            {SET_TYPES.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
          <div className="flex flex-wrap gap-2 text-xs">
            {CONCEPT_TAGS.map((tag) => (
              <label key={tag.id} className="flex items-center gap-1">
                <input
                  type="checkbox"
                  checked={createForm.tagIds.includes(tag.id)}
                  onChange={(e) => {
                    const tagIds = e.target.checked
                      ? [...createForm.tagIds, tag.id]
                      : createForm.tagIds.filter((id) => id !== tag.id);
                    setCreateForm({ ...createForm, tagIds });
                  }}
                />
                {tag.label}
              </label>
            ))}
          </div>
          <button type="button" className="rounded bg-emerald-700 px-3 py-1 text-sm" onClick={() => void createSet()}>
            Create
          </button>
        </fieldset>

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Selected set</legend>
          <select
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            value={selectedId}
            onChange={(e) => setSelectedId(e.target.value)}
          >
            <option value="">—</option>
            {sets.map((s) => {
              const set = s as { id: string; name: string; type: string };
              return (
                <option key={set.id} value={set.id}>
                  {set.name} ({set.type})
                </option>
              );
            })}
          </select>
          <button
            type="button"
            className="rounded bg-red-800 px-3 py-1 text-sm disabled:opacity-40"
            disabled={!selectedId}
            onClick={() => void deleteSet()}
          >
            Delete set
          </button>
          <button
            type="button"
            className="ml-2 rounded bg-emerald-700 px-3 py-1 text-sm disabled:opacity-40"
            disabled={!selectedId}
            onClick={() => void suggestRollsForSet()}
          >
            Suggest rolls
          </button>
        </fieldset>

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Add / replace item</legend>
          <select
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            value={itemForm.slot}
            onChange={(e) => setItemForm({ ...itemForm, slot: e.target.value })}
          >
            {slots.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>
          <input
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            value={itemForm.itemHash}
            onChange={(e) => setItemForm({ ...itemForm, itemHash: e.target.value })}
            placeholder="itemHash"
          />
          <input
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            value={itemForm.itemName}
            onChange={(e) => setItemForm({ ...itemForm, itemName: e.target.value })}
            placeholder="itemName"
          />
          <input
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            value={itemForm.selectedPerks}
            onChange={(e) => setItemForm({ ...itemForm, selectedPerks: e.target.value })}
            placeholder="selectedPerks (comma)"
          />
          <button
            type="button"
            className="rounded bg-emerald-700 px-3 py-1 text-sm disabled:opacity-40"
            disabled={!selectedId}
            onClick={() => void addItem(false)}
          >
            Put item
          </button>
          {pendingReplace && (
            <button
              type="button"
              className="ml-2 rounded bg-amber-700 px-3 py-1 text-sm"
              onClick={() => void addItem(true)}
            >
              Confirm replace (FR-027)
            </button>
          )}
        </fieldset>
      </section>

      <section>
        <h2 className="mb-2 text-sm font-medium">{panel.label}</h2>
        {panel.error && (
          <pre className="mb-2 overflow-auto rounded bg-red-950/50 p-3 text-xs text-red-200">
            {JSON.stringify(panel.error, null, 2)}
          </pre>
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
