"use client";

import { useState } from "react";

import { sortByName } from "@/lib/sortByName";

type JsonPanel = {
  label: string;
  request?: unknown;
  response?: unknown;
  error?: unknown;
};

export function SuggestionsDebugPage() {
  const [panel, setPanel] = useState<JsonPanel>({ label: "Ready" });
  const [sets, setSets] = useState<Array<{ id: string; name: string }>>([]);
  const [builds, setBuilds] = useState<Array<{ id: string; name: string }>>([]);
  const [form, setForm] = useState({
    setId: "",
    buildId: "",
    synergyTypesJson: "",
    limit: "5",
  });

  async function loadSets() {
    const res = await fetch("/api/user/sets");
    const body = await res.json();
    if (res.ok) setSets(sortByName(body.sets ?? []));
    setPanel({ label: "GET /api/user/sets", response: body, error: res.ok ? undefined : body });
  }

  async function loadBuilds() {
    const res = await fetch("/api/user/builds");
    const body = await res.json();
    if (res.ok) setBuilds(sortByName(body.builds ?? []));
    setPanel({ label: "GET /api/user/builds", response: body, error: res.ok ? undefined : body });
  }

  async function suggestRolls() {
    let synergyTypes: unknown;
    if (form.synergyTypesJson.trim()) {
      try {
        synergyTypes = JSON.parse(form.synergyTypesJson);
      } catch {
        setPanel({ label: "POST /api/user/suggestions/rolls", error: "Invalid synergyTypes JSON" });
        return;
      }
    }
    const payload = {
      setId: form.setId || undefined,
      buildId: form.buildId || undefined,
      synergyTypes,
      limit: Number(form.limit) || 5,
    };
    setPanel({ label: "POST /api/user/suggestions/rolls", request: payload });
    const res = await fetch("/api/user/suggestions/rolls", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    setPanel({
      label: "POST /api/user/suggestions/rolls",
      request: payload,
      response: res.ok ? body : undefined,
      error: res.ok ? undefined : body,
    });
  }

  return (
    <div className="grid min-w-0 gap-6 lg:grid-cols-2 [&>*]:min-w-0">
      <section className="space-y-4">
        <h1 className="text-lg font-semibold">Roll suggestions</h1>

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Load context</legend>
          <button type="button" className="rounded bg-zinc-700 px-3 py-1 text-sm" onClick={() => void loadSets()}>
            Load sets
          </button>
          <button type="button" className="ml-2 rounded bg-zinc-700 px-3 py-1 text-sm" onClick={() => void loadBuilds()}>
            Load builds
          </button>
        </fieldset>

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Suggest rolls (Scenario 5)</legend>
          <select
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            value={form.setId}
            onChange={(e) => setForm({ ...form, setId: e.target.value })}
          >
            <option value="">Set (optional) —</option>
            {sets.map((s) => (
              <option key={s.id} value={s.id}>{s.name}</option>
            ))}
          </select>
          <select
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            value={form.buildId}
            onChange={(e) => setForm({ ...form, buildId: e.target.value })}
          >
            <option value="">Build (optional) —</option>
            {builds.map((b) => (
              <option key={b.id} value={b.id}>{b.name}</option>
            ))}
          </select>
          <input
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            placeholder='Optional synergyTypes JSON e.g. [{"type":"verb","subType":"Devour"}]'
            value={form.synergyTypesJson}
            onChange={(e) => setForm({ ...form, synergyTypesJson: e.target.value })}
          />
          <input
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            placeholder="limit"
            value={form.limit}
            onChange={(e) => setForm({ ...form, limit: e.target.value })}
          />
          <button type="button" className="rounded bg-emerald-700 px-3 py-1 text-sm" onClick={() => void suggestRolls()}>
            Suggest rolls
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
