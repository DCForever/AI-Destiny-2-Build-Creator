"use client";

import { useCallback, useState } from "react";

import type { CatalogItem } from "@/lib/catalog/types";

type JsonPanel = {
  label: string;
  request?: unknown;
  response?: unknown;
  error?: unknown;
};

type CatalogResponse = {
  items?: CatalogItem[];
  syncPrompt?: boolean;
  message?: string;
};

type InstanceRow = {
  instanceId: string;
  itemHash: number;
  kind: string;
  bucket: string;
  location: string;
  power: number;
  isMasterwork: boolean;
  isCrafted: boolean;
  className?: string | null;
  characterDisplayName?: string | null;
  plugs: { displayName: string; resolved: boolean }[];
};

type InstanceResponse = {
  instances?: InstanceRow[];
  count?: number;
  syncPrompt?: boolean;
  message?: string;
};

export function CatalogDebugPage() {
  const [panel, setPanel] = useState<JsonPanel>({ label: "Ready" });
  const [kind, setKind] = useState<"weapons" | "armor">("weapons");
  const [scope, setScope] = useState<"all" | "owned">("all");
  const [includeInstancePointer, setIncludeInstancePointer] = useState(false);
  const [q, setQ] = useState("");
  const [slot, setSlot] = useState("");
  const [itemType, setItemType] = useState("");
  const [frame, setFrame] = useState("");
  const [className, setClassName] = useState("");
  const [catalogItems, setCatalogItems] = useState<CatalogItem[]>([]);
  const [selectedHash, setSelectedHash] = useState<number | null>(null);
  const [instanceRows, setInstanceRows] = useState<InstanceRow[]>([]);
  const [instancePanel, setInstancePanel] = useState<JsonPanel | null>(null);
  const [instanceItemHash, setInstanceItemHash] = useState("");
  const [instanceKind, setInstanceKind] = useState<"" | "weapons" | "armor">("");
  const [instanceQ, setInstanceQ] = useState("");

  const fetchInstances = useCallback(async (href: string, label: string) => {
    setInstancePanel({ label, request: { url: href } });
    const res = await fetch(href);
    const body = (await res.json()) as InstanceResponse;
    if (!res.ok) {
      setInstancePanel({ label, request: { url: href }, error: body });
      setInstanceRows([]);
      return;
    }
    setInstancePanel({ label, request: { url: href }, response: body });
    setInstanceRows(body.instances ?? []);
  }, []);

  const selectCatalogRow = useCallback(
    async (item: CatalogItem) => {
      setSelectedHash(item.hash);
      if (item.ownedCount <= 0) {
        setInstanceRows([]);
        setInstancePanel({
          label: "No owned copies",
          response: { message: "ownedCount is 0" },
        });
        return;
      }
      const href =
        item.instancesHref ?? `/api/user/inventory/instances?itemHash=${item.hash}`;
      await fetchInstances(href, `GET ${href}`);
    },
    [fetchInstances],
  );

  async function runSearch() {
    const params = new URLSearchParams({ scope });
    if (q.trim()) params.set("q", q.trim());
    if (slot) params.set("slot", slot);
    if (kind === "weapons" && itemType.trim()) params.set("itemType", itemType.trim());
    if (frame.trim()) params.set("frame", frame.trim());
    if (kind === "armor" && className) params.set("className", className);
    if (scope === "owned" && includeInstancePointer) {
      params.set("includeInstancePointer", "1");
    }

    const url = `/api/catalog/${kind}?${params}`;
    setPanel({ label: `GET ${url}`, request: { url } });
    setCatalogItems([]);
    setSelectedHash(null);
    setInstanceRows([]);
    setInstancePanel(null);

    const res = await fetch(url);
    const body = (await res.json()) as CatalogResponse;
    if (!res.ok) {
      setPanel({ label: `GET ${url}`, request: { url }, error: body });
      return;
    }
    setPanel({ label: `GET ${url}`, request: { url }, response: body });
    setCatalogItems(body.items ?? []);
  }

  async function runInstanceQuery() {
    const params = new URLSearchParams();
    if (instanceItemHash.trim()) params.set("itemHash", instanceItemHash.trim());
    if (instanceKind) params.set("kind", instanceKind);
    if (instanceQ.trim()) params.set("q", instanceQ.trim());
    const href = `/api/user/inventory/instances?${params}`;
    await fetchInstances(href, `GET ${href}`);
  }

  async function fetchInstanceDetail(instanceId: string) {
    const href = `/api/user/inventory/instances/${instanceId}`;
    setInstancePanel({ label: `GET ${href}`, request: { url: href } });
    const res = await fetch(href);
    const body = await res.json();
    setInstancePanel({
      label: `GET ${href}`,
      request: { url: href },
      response: body,
      error: res.ok ? undefined : body,
    });
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
          {scope === "owned" && (
            <label className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={includeInstancePointer}
                onChange={(e) => setIncludeInstancePointer(e.target.checked)}
              />
              includeInstancePointer=1
            </label>
          )}
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
              Owned scope requires sign-in and inventory sync. Select a row to auto-fetch instances.
            </p>
          )}
        </fieldset>

        {catalogItems.length > 0 && (
          <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
            <legend className="px-1 text-sm">Catalog results ({catalogItems.length})</legend>
            <ul className="max-h-48 space-y-1 overflow-auto text-sm">
              {catalogItems.map((item) => (
                <li key={item.hash}>
                  <button
                    type="button"
                    className={`w-full rounded px-2 py-1 text-left ${
                      selectedHash === item.hash ? "bg-emerald-900" : "bg-zinc-900 hover:bg-zinc-800"
                    }`}
                    onClick={() => void selectCatalogRow(item)}
                  >
                    {item.name} ({item.ownedCount} owned)
                    {item.instancesHref ? " · pointer" : ""}
                  </button>
                </li>
              ))}
            </ul>
          </fieldset>
        )}

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Instance API (direct)</legend>
          <input
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            placeholder="itemHash"
            value={instanceItemHash}
            onChange={(e) => setInstanceItemHash(e.target.value)}
          />
          <select
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            value={instanceKind}
            onChange={(e) => setInstanceKind(e.target.value as "" | "weapons" | "armor")}
          >
            <option value="">(any kind)</option>
            <option value="weapons">weapons</option>
            <option value="armor">armor</option>
          </select>
          <input
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            placeholder="Perk search (q)"
            value={instanceQ}
            onChange={(e) => setInstanceQ(e.target.value)}
          />
          <button
            type="button"
            className="rounded bg-emerald-700 px-3 py-1 text-sm"
            onClick={() => void runInstanceQuery()}
          >
            Query instances
          </button>
        </fieldset>

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Synergy reverse lookup (T057b)</legend>
          <input
            id="synergy-lookup-name"
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            placeholder="origin trait name (e.g. Cast No Shadows)"
            defaultValue="Cast No Shadows"
          />
          <button
            type="button"
            className="rounded bg-zinc-700 px-3 py-1 text-sm"
            onClick={() => {
              const name = (document.getElementById("synergy-lookup-name") as HTMLInputElement).value;
              void (async () => {
                const params = new URLSearchParams({ kind: "origin_trait", name });
                const url = `/api/user/synergies/by-target?${params}`;
                setPanel({ label: `GET ${url}` });
                const res = await fetch(url);
                const body = await res.json();
                setPanel({ label: `GET ${url}`, response: body, error: res.ok ? undefined : body });
              })();
            }}
          >
            Synergy lookup JSON
          </button>
        </fieldset>
      </section>

      <section className="space-y-4">
        <div>
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
        </div>

        {(instanceRows.length > 0 || instancePanel) && (
          <div>
            <h2 className="mb-2 text-sm font-medium">Owned instances</h2>
            {instanceRows.length > 0 && (
              <ul className="mb-3 space-y-2 text-sm">
                {instanceRows.map((row) => (
                  <li key={row.instanceId} className="rounded border border-zinc-800 p-2">
                    <button
                      type="button"
                      className="text-left text-emerald-400 underline"
                      onClick={() => void fetchInstanceDetail(row.instanceId)}
                    >
                      {row.instanceId}
                    </button>
                    <p>
                      {row.power} · {row.bucket} · {row.location}
                      {row.className ? ` · ${row.className}` : ""}
                      {row.characterDisplayName ? ` (${row.characterDisplayName})` : ""}
                    </p>
                    <p className="text-xs text-zinc-400">
                      {row.plugs.map((p) => p.displayName).join(", ")}
                    </p>
                  </li>
                ))}
              </ul>
            )}
            {instancePanel && (
              <>
                <p className="text-xs text-zinc-500">{instancePanel.label}</p>
                {instancePanel.error !== undefined && (
                  <pre className="mb-2 overflow-auto rounded bg-red-950/50 p-3 text-xs text-red-200">
                    {JSON.stringify(instancePanel.error, null, 2)}
                  </pre>
                )}
                {instancePanel.response !== undefined && (
                  <pre className="overflow-auto rounded bg-zinc-900 p-3 text-xs">
                    {JSON.stringify(instancePanel.response, null, 2)}
                  </pre>
                )}
              </>
            )}
          </div>
        )}
      </section>
    </div>
  );
}
