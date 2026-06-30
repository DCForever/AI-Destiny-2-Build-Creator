"use client";

import { useCallback, useState } from "react";

import { sortByName } from "@/lib/sortByName";

import { CONCEPT_TAGS } from "@/data/conceptTags";

type JsonPanel = {
  label: string;
  request?: unknown;
  response?: unknown;
  error?: unknown;
};

export function BuildsDebugPage() {
  const [panel, setPanel] = useState<JsonPanel>({ label: "Ready" });
  const [builds, setBuilds] = useState<Array<{ id: string; name: string }>>([]);
  const [sets, setSets] = useState<Array<{ id: string; name: string; type: string }>>([]);
  const [synergies, setSynergies] = useState<Array<{ id: string; name: string }>>([]);
  const [selectedBuildId, setSelectedBuildId] = useState("");
  const [selectedVariantId, setSelectedVariantId] = useState("");

  const [createForm, setCreateForm] = useState({
    name: "Solar Titan",
    className: "Titan",
    exoticArmorHash: "100",
    exoticArmorName: "Hallowfire Heart",
    tagIds: ["solar", "pve"] as string[],
    synergyIds: [] as string[],
    subclassJson: JSON.stringify(
      {
        name: "Sunbreaker",
        super: "Hammer",
        classAbility: "Barricade",
        movement: "Lift",
        melee: "Hammer",
        grenade: "Fire",
        aspects: [],
        fragments: [],
        rationale: "Debug",
      },
      null,
      2,
    ),
  });

  const [attachForm, setAttachForm] = useState({ setId: "", mode: "live" as "live" | "snapshot" });
  const [suggestGoal, setSuggestGoal] = useState("");
  const [variantNotes, setVariantNotes] = useState("");
  const [filterExoticArmor, setFilterExoticArmor] = useState("");

  const record = useCallback((next: JsonPanel) => setPanel(next), []);

  async function loadBuilds() {
    const query = filterExoticArmor.trim() ? `?exoticArmorHash=${encodeURIComponent(filterExoticArmor.trim())}` : "";
    const res = await fetch(`/api/user/builds${query}`);
    const body = await res.json();
    if (res.ok) setBuilds(sortByName(body.builds ?? []));
    record({ label: "GET /api/user/builds" + query, response: body, error: res.ok ? undefined : body });
  }

  async function loadSetsAndSynergies() {
    const [setsRes, buildRes] = await Promise.all([
      fetch("/api/user/sets"),
      fetch("/api/user/builds"),
    ]);
    const setsBody = await setsRes.json();
    if (setsRes.ok) setSets(sortByName(setsBody.sets ?? []));

    if (buildRes.ok && selectedBuildId) {
      const detail = await fetch(`/api/user/builds/${selectedBuildId}`);
      const detailBody = await detail.json();
      if (detail.ok) {
        setSynergies(detailBody.build?.synergies ?? []);
        const variant = detailBody.build?.variants?.[0];
        if (variant) setSelectedVariantId(variant.id);
      }
    }
  }

  async function createBuild() {
    let subclass: unknown;
    try {
      subclass = JSON.parse(createForm.subclassJson);
    } catch {
      record({ label: "Create build", error: { message: "Invalid subclass JSON" } });
      return;
    }

    const synergyIds =
      createForm.synergyIds.length > 0
        ? createForm.synergyIds
        : synergies.length
          ? [synergies[0]!.id]
          : [];

    const payload = {
      name: createForm.name,
      className: createForm.className,
      subclass,
      exoticArmorHash: Number(createForm.exoticArmorHash),
      exoticArmorName: createForm.exoticArmorName,
      tagIds: createForm.tagIds,
      synergyIds,
      defaultVariant: { name: "Default" },
    };

    record({ label: "POST /api/user/builds", request: payload });
    const res = await fetch("/api/user/builds", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    if (res.ok) {
      setSelectedBuildId(body.build?.id ?? "");
      setSelectedVariantId(body.build?.variants?.[0]?.id ?? "");
      await loadBuilds();
    }
    record({ label: "POST /api/user/builds", request: payload, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function attachSet() {
    if (!selectedBuildId || !selectedVariantId || !attachForm.setId) return;
    const url = `/api/user/builds/${selectedBuildId}/variants/${selectedVariantId}`;
    const payload = { attachments: [{ setId: attachForm.setId, mode: attachForm.mode }] };
    record({ label: "PATCH " + url, request: payload });
    const res = await fetch(url, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    record({ label: "PATCH " + url, request: payload, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function fetchResolved() {
    if (!selectedBuildId || !selectedVariantId) return;
    const url = `/api/user/builds/${selectedBuildId}/variants/${selectedVariantId}/resolved`;
    const res = await fetch(url);
    const body = await res.json();
    record({ label: "GET " + url, response: body, error: res.ok ? undefined : body });
  }

  async function suggestSynergiesCall() {
    if (!selectedBuildId) return;
    const url = `/api/user/builds/${selectedBuildId}/suggest-synergies`;
    const res = await fetch(url);
    const body = await res.json();
    record({ label: "GET " + url, response: body, error: res.ok ? undefined : body });
  }

  async function suggestSetsCall() {
    if (!selectedBuildId || !selectedVariantId) return;
    const url = `/api/user/builds/${selectedBuildId}/variants/${selectedVariantId}/suggest-sets`;
    const payload = suggestGoal.trim() ? { goal: suggestGoal.trim() } : {};
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    record({ label: "POST " + url, request: payload, response: body, error: res.ok ? undefined : body });
  }

  async function suggestRollsCall() {
    const payload = {
      buildId: selectedBuildId || undefined,
      setId: attachForm.setId || undefined,
    };
    const res = await fetch("/api/user/suggestions/rolls", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    record({ label: "POST /api/user/suggestions/rolls", request: payload, response: body, error: res.ok ? undefined : body });
  }

  async function duplicateVariant() {
    if (!selectedBuildId || !selectedVariantId) return;
    const url = `/api/user/builds/${selectedBuildId}/variants`;
    const payload = { duplicateFromVariantId: selectedVariantId, name: "Copy", notes: variantNotes || null };
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    if (res.ok) {
      const copy = body.build?.variants?.find((v: { name: string }) => v.name === "Copy");
      if (copy) setSelectedVariantId(copy.id);
    }
    record({ label: "POST " + url, request: payload, response: res.ok ? body : undefined, error: res.ok ? undefined : body });
  }

  async function compareVariantsCall() {
    if (!selectedBuildId) return;
    const url = `/api/user/builds/${selectedBuildId}/compare`;
    const res = await fetch(url);
    const body = await res.json();
    record({ label: "GET " + url, response: body, error: res.ok ? undefined : body });
  }

  async function exportResolved() {
    if (!selectedBuildId || !selectedVariantId) return;
    const url = `/api/user/builds/${selectedBuildId}/variants/${selectedVariantId}/resolved`;
    const res = await fetch(url);
    const body = await res.json();
    if (res.ok) {
      const blob = new Blob([JSON.stringify(body, null, 2)], { type: "application/json" });
      const href = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = href;
      a.download = `resolved-${selectedBuildId}-${selectedVariantId}.json`;
      a.click();
      URL.revokeObjectURL(href);
    }
    record({ label: "Export " + url, response: body, error: res.ok ? undefined : body });
  }

  return (
    <div className="grid min-w-0 gap-6 lg:grid-cols-2 [&>*]:min-w-0">
      <section className="space-y-4">
        <h1 className="text-lg font-semibold">Builds</h1>

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Load data</legend>
          <input
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            placeholder="Filter exoticArmorHash"
            value={filterExoticArmor}
            onChange={(e) => setFilterExoticArmor(e.target.value)}
          />
          <button type="button" className="rounded bg-zinc-700 px-3 py-1 text-sm" onClick={() => void loadBuilds()}>
            Load builds
          </button>
          <button type="button" className="ml-2 rounded bg-zinc-700 px-3 py-1 text-sm" onClick={() => void loadSetsAndSynergies()}>
            Load sets + synergies
          </button>
        </fieldset>

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Create build</legend>
          <input className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" value={createForm.name} onChange={(e) => setCreateForm({ ...createForm, name: e.target.value })} />
          <select className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" value={createForm.className} onChange={(e) => setCreateForm({ ...createForm, className: e.target.value })}>
            <option value="Titan">Titan</option>
            <option value="Hunter">Hunter</option>
            <option value="Warlock">Warlock</option>
          </select>
          <input className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" placeholder="exoticArmorHash" value={createForm.exoticArmorHash} onChange={(e) => setCreateForm({ ...createForm, exoticArmorHash: e.target.value })} />
          <input className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" placeholder="exoticArmorName" value={createForm.exoticArmorName} onChange={(e) => setCreateForm({ ...createForm, exoticArmorName: e.target.value })} />
          <textarea className="block h-32 w-full rounded bg-zinc-900 px-2 py-1 font-mono text-xs" value={createForm.subclassJson} onChange={(e) => setCreateForm({ ...createForm, subclassJson: e.target.value })} />
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
          <button type="button" className="rounded bg-emerald-700 px-3 py-1 text-sm" onClick={() => void createBuild()}>
            Create (seeds default synergy if needed)
          </button>
        </fieldset>

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Variant attach</legend>
          <select className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" value={selectedBuildId} onChange={(e) => setSelectedBuildId(e.target.value)}>
            <option value="">Build —</option>
            {builds.map((b) => (
              <option key={b.id} value={b.id}>{b.name}</option>
            ))}
          </select>
          <input className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" placeholder="variantId" value={selectedVariantId} onChange={(e) => setSelectedVariantId(e.target.value)} />
          <select className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" value={attachForm.setId} onChange={(e) => setAttachForm({ ...attachForm, setId: e.target.value })}>
            <option value="">Set —</option>
            {sets.map((s) => (
              <option key={s.id} value={s.id}>{s.name} ({s.type})</option>
            ))}
          </select>
          <select className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" value={attachForm.mode} onChange={(e) => setAttachForm({ ...attachForm, mode: e.target.value as "live" | "snapshot" })}>
            <option value="live">live</option>
            <option value="snapshot">snapshot</option>
          </select>
          <button type="button" className="rounded bg-emerald-700 px-3 py-1 text-sm" onClick={() => void attachSet()}>
            Attach set
          </button>
          <button type="button" className="ml-2 rounded bg-zinc-700 px-3 py-1 text-sm" onClick={() => void fetchResolved()}>
            Resolved JSON
          </button>
          <button type="button" className="ml-2 rounded bg-zinc-700 px-3 py-1 text-sm" onClick={() => void exportResolved()}>
            Export resolved
          </button>
        </fieldset>

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Variants</legend>
          <input
            className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm"
            placeholder="Notes for duplicate"
            value={variantNotes}
            onChange={(e) => setVariantNotes(e.target.value)}
          />
          <button type="button" className="rounded bg-emerald-700 px-3 py-1 text-sm" onClick={() => void duplicateVariant()}>
            Duplicate variant
          </button>
          <button type="button" className="ml-2 rounded bg-zinc-700 px-3 py-1 text-sm" onClick={() => void compareVariantsCall()}>
            Compare variants
          </button>
        </fieldset>

        <fieldset className="space-y-2 rounded border border-zinc-800 p-3">
          <legend className="px-1 text-sm">Suggestions</legend>
          <input className="block w-full rounded bg-zinc-900 px-2 py-1 text-sm" placeholder="Optional goal" value={suggestGoal} onChange={(e) => setSuggestGoal(e.target.value)} />
          <button type="button" className="rounded bg-emerald-700 px-3 py-1 text-sm" onClick={() => void suggestSetsCall()}>
            Suggest sets
          </button>
          <button type="button" className="ml-2 rounded bg-emerald-700 px-3 py-1 text-sm" onClick={() => void suggestSynergiesCall()}>
            Suggest synergies
          </button>
          <button type="button" className="ml-2 rounded bg-emerald-700 px-3 py-1 text-sm" onClick={() => void suggestRollsCall()}>
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
