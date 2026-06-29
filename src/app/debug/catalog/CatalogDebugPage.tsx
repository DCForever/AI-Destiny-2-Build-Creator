"use client";

import { useState } from "react";

type JsonPanel = {
  label: string;
  request?: unknown;
  response?: unknown;
  error?: unknown;
};

export function CatalogDebugPage() {
  const [panel, setPanel] = useState<JsonPanel>({ label: "Ready" });
  const [kind, setKind] = useState<"weapons" | "armor">("weapons");
  const [scope, setScope] = useState<"all" | "owned">("all");
  const [q, setQ] = useState("");
  const [slot, setSlot] = useState("");
  const [itemType, setItemType] = useState("");
  const [frame, setFrame] = useState("");
  const [className, setClassName] = useState("");

  async function runSearch() {
    const params = new URLSearchParams({ scope });
    if (q.trim()) params.set("q", q.trim());
    if (slot) params.set("slot", slot);
    if (kind === "weapons" && itemType.trim()) params.set("itemType", itemType.trim());
    if (frame.trim()) params.set("frame", frame.trim());
    if (kind === "armor" && className) params.set("className", className);

    const url = `/api/catalog/${kind}?${params}`;
    setPanel({ label: `GET ${url}`, request: { url } });

    const res = await fetch(url);
    const body = await res.json();
    if (!res.ok) {
      setPanel({ label: `GET ${url}`, request: { url }, error: body });
      return;
    }
    setPanel({ label: `GET ${url}`, request: { url }, response: body });
  }

  return (
    <div className="grid gap-6 lg:grid-cols-2">
      <section className="space-y-4">
        <h1 className="text-lg font-semibold">Catalog</h1>

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Filter</legend>
          <label className="block text-sm">
            Kind
            <select
              className="ml-2 rounded bg-zinc-900 px-2 py-1"
              value={kind}
              onChange={(e) => setKind(e.target.value as "weapons" | "armor")}
            >
              <option value="weapons">Weapons</option>
              <option value="armor">Armor</option>
            </select>
          </label>
          <label className="block text-sm">
            Scope
            <select
              className="ml-2 rounded bg-zinc-900 px-2 py-1"
              value={scope}
              onChange={(e) => setScope(e.target.value as "all" | "owned")}
            >
              <option value="all">All (manifest)</option>
              <option value="owned">Owned (inventory)</option>
            </select>
          </label>
          <input
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            placeholder="Search (q)"
            value={q}
            onChange={(e) => setQ(e.target.value)}
          />
          <select
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            value={slot}
            onChange={(e) => setSlot(e.target.value)}
          >
            <option value="">(any slot)</option>
            {kind === "weapons" ? (
              <>
                <option value="Kinetic">Kinetic</option>
                <option value="Energy">Energy</option>
                <option value="Power">Power</option>
              </>
            ) : (
              <>
                <option value="Helmet">Helmet</option>
                <option value="Gauntlets">Gauntlets</option>
                <option value="Chest">Chest</option>
                <option value="Legs">Legs</option>
                <option value="ClassItem">Class Item</option>
              </>
            )}
          </select>
          {kind === "weapons" && (
            <input
              className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
              placeholder="Item type (e.g. Auto Rifle)"
              value={itemType}
              onChange={(e) => setItemType(e.target.value)}
            />
          )}
          {kind === "armor" && (
            <select
              className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
              value={className}
              onChange={(e) => setClassName(e.target.value)}
            >
              <option value="">(any class)</option>
              <option value="Titan">Titan</option>
              <option value="Hunter">Hunter</option>
              <option value="Warlock">Warlock</option>
            </select>
          )}
          <input
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            placeholder="Frame / archetype"
            value={frame}
            onChange={(e) => setFrame(e.target.value)}
          />
          <button type="button" className="rounded bg-emerald-700 px-3 py-1 text-sm" onClick={() => void runSearch()}>
            Search
          </button>
          {scope === "owned" && (
            <p className="text-xs text-amber-400">
              Owned scope requires sign-in and inventory sync. Empty results show syncPrompt in JSON.
            </p>
          )}
        </fieldset>
      </section>

      <section>
        <h2 className="mb-2 text-sm font-medium">{panel.label}</h2>
        {panel.error !== undefined && (
          <pre className="mb-2 overflow-auto rounded bg-red-950/50 p-3 text-xs text-red-200">
            {JSON.stringify(panel.error, null, 2)}
          </pre>
        )}
        {panel.request !== undefined && (
          <>
            <p className="text-xs text-zinc-500">Request</p>
            <pre className="mb-2 overflow-auto rounded bg-zinc-900 p-3 text-xs">
              {JSON.stringify(panel.request, null, 2)}
            </pre>
          </>
        )}
        {panel.response !== undefined && (
          <>
            <p className="text-xs text-zinc-500">Response</p>
            <pre className="overflow-auto rounded bg-zinc-900 p-3 text-xs">
              {JSON.stringify(panel.response, null, 2)}
            </pre>
          </>
        )}
      </section>
    </div>
  );
}
