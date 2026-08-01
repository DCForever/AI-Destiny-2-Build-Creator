"use client";

import { useMemo, useState } from "react";

type ObjectReference = {
  store: string;
  hash?: number;
  name: string;
  snippet: string;
};

type Gap = {
  gapKind?: "type" | "link";
  coverageKey: string;
  kind?: string;
  displayName: string;
  sources: string[];
  suggestedType: string;
  suggestedSubType?: string | null;
  rationale: string;
  mentionCount?: number;
  sampleObjectNames?: string[];
  references?: ObjectReference[];
};

type Proposal = {
  id: string;
  kind: string;
  rationale?: string;
  synergy?: {
    type: string;
    subType?: string | null;
    links?: Array<{ displayName?: string; kind?: string }>;
  };
};

type ScanResult = {
  scope: string;
  kinds?: string[];
  candidateCount: number;
  coveredCount: number;
  missingCount: number;
  typeGapCount?: number;
  linkGapCount?: number;
  ignoredCount?: number;
  ignoredKeys?: string[];
  ownedWeaponCount: number;
  syncPrompt: boolean;
  passId: string;
  gaps: Gap[];
  proposals: Proposal[];
};

type ScanMode = "types" | "all";

export function SynergyGapsDebugPage() {
  const [mode, setMode] = useState<ScanMode>("types");
  const [scope, setScope] = useState<"both" | "owned" | "manifest">("both");
  const [query, setQuery] = useState("");
  const [limit, setLimit] = useState(200);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<ScanResult | null>(null);
  const [selected, setSelected] = useState<Record<string, boolean>>({});
  const [focusedId, setFocusedId] = useState<string | null>(null);
  const [confirmResult, setConfirmResult] = useState<unknown>(null);
  const [listFilter, setListFilter] = useState("");

  const visibleProposals = useMemo(() => {
    const proposals = result?.proposals ?? [];
    const gaps = result?.gaps ?? [];
    const q = listFilter.trim().toLowerCase();
    if (!q) return proposals.map((p, i) => ({ proposal: p, gap: gaps[i] }));

    return proposals
      .map((p, i) => ({ proposal: p, gap: gaps[i] }))
      .filter(({ proposal, gap }) => {
        const hay = [
          gap?.displayName,
          gap?.suggestedType,
          gap?.suggestedSubType,
          gap?.coverageKey,
          proposal.synergy?.type,
          proposal.synergy?.subType,
          proposal.rationale,
        ]
          .filter(Boolean)
          .join(" ")
          .toLowerCase();
        return hay.includes(q);
      });
  }, [result, listFilter]);

  const focused = useMemo(() => {
    if (!focusedId) return null;
    return (
      visibleProposals.find((v) => v.proposal.id === focusedId) ??
      (result?.proposals ?? [])
        .map((p, i) => ({ proposal: p, gap: result?.gaps?.[i] }))
        .find((v) => v.proposal.id === focusedId) ??
      null
    );
  }, [focusedId, visibleProposals, result]);

  async function runScan() {
    setBusy(true);
    setError(null);
    setConfirmResult(null);
    setFocusedId(null);
    try {
      const kinds =
        mode === "types"
          ? (["type"] as const)
          : (["type", "weapon", "origin_trait", "armor_set_bonus"] as const);
      const res = await fetch("/api/user/synergies/gap-scan", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          scope,
          limit,
          kinds: [...kinds],
          query: mode === "types" && query.trim() ? query.trim() : undefined,
        }),
      });
      const body = (await res.json()) as ScanResult & { error?: string };
      if (!res.ok) {
        setError(body.error ?? "Gap scan failed");
        setResult(null);
        return;
      }
      setResult(body);
      setListFilter(query.trim());
      // Do not pre-select gaps — user opts in per type before confirm.
      setSelected({});
      if (body.proposals?.[0]?.id) setFocusedId(body.proposals[0].id);
    } catch {
      setError("Gap scan failed");
    } finally {
      setBusy(false);
    }
  }

  function selectedCoverageKeys(): string[] {
    const visibleIds = new Set(visibleProposals.map((v) => v.proposal.id));
    return visibleProposals
      .filter(
        (v) => selected[v.proposal.id] && visibleIds.has(v.proposal.id),
      )
      .map((v) => v.gap?.coverageKey)
      .filter((k): k is string => Boolean(k));
  }

  async function ignoreSelected() {
    const keys = selectedCoverageKeys();
    if (keys.length === 0) {
      setError("Select one or more missing types to ignore.");
      return;
    }
    setBusy(true);
    setError(null);
    try {
      const res = await fetch("/api/user/synergies/gap-ignore", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "add", keys }),
      });
      const body = (await res.json()) as { error?: string; count?: number };
      if (!res.ok) {
        setError(body.error ?? "Ignore failed");
        return;
      }
      // Re-scan so ignored types disappear immediately.
      await runScan();
    } catch {
      setError("Ignore failed");
      setBusy(false);
    }
  }

  async function clearIgnored() {
    setBusy(true);
    setError(null);
    try {
      const res = await fetch("/api/user/synergies/gap-ignore", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "clear" }),
      });
      const body = (await res.json()) as { error?: string };
      if (!res.ok) {
        setError(body.error ?? "Clear ignored failed");
        setBusy(false);
        return;
      }
      await runScan();
    } catch {
      setError("Clear ignored failed");
      setBusy(false);
    }
  }

  async function confirmSelected() {
    if (!result?.passId) return;
    setBusy(true);
    setError(null);
    try {
      const visibleIds = new Set(visibleProposals.map((v) => v.proposal.id));
      const acceptedIds = Object.entries(selected)
        .filter(([id, on]) => on && visibleIds.has(id))
        .map(([id]) => id);
      if (acceptedIds.length === 0) {
        setError("Select one or more missing types to confirm.");
        setBusy(false);
        return;
      }
      const skippedIds = (result.proposals ?? [])
        .map((p) => p.id)
        .filter((id) => !acceptedIds.includes(id));
      const res = await fetch(
        `/api/llm/propose-pass/${result.passId}/confirm`,
        {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            acceptedIds,
            skippedIds,
          }),
        },
      );
      const body = await res.json();
      if (!res.ok) {
        setError(
          typeof body.error === "string" ? body.error : "Confirm failed",
        );
        return;
      }
      setConfirmResult(body);
    } catch {
      setError("Confirm failed");
    } finally {
      setBusy(false);
    }
  }

  const references = focused?.gap?.references ?? [];
  const shownRefs = references.slice(0, 10);

  return (
    <div className="mx-auto max-w-5xl space-y-4">
      <h1 className="text-lg font-semibold">Missing synergy types</h1>
      <p className="text-sm text-zinc-400">
        Lists <strong>novel</strong> keywords from object{" "}
        <strong>descriptions only</strong> (not perk/item names) that are not
        already a known synergy type/subtype (e.g. curated{" "}
        <strong>Verb: Ionic Trace</strong> is not “missing” — create/link it in
        the library if you need a row). Sources: origin perks, armor sets,
        weapon perks (no barrels/mags), aspects, fragments, exotic armor,
        exotic weapon intrinsic/catalyst, artifacts. Select a type for the
        first 10 object references with snippets.
      </p>

      <div className="space-y-3 rounded border border-zinc-800 p-3">
        <label className="block text-sm">
          Search missing types
          <input
            className="mt-1 w-full rounded border border-zinc-700 bg-zinc-900 px-3 py-2 text-sm"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={(e) => {
              if (e.key === "Enter") void runScan();
            }}
            placeholder='e.g. Sliding · Radiant · "melee" · dps'
          />
        </label>

        <div className="flex flex-wrap items-end gap-3">
          <label className="text-sm">
            Mode
            <select
              className="ml-2 rounded border border-zinc-700 bg-zinc-900 px-2 py-1"
              value={mode}
              onChange={(e) => setMode(e.target.value as ScanMode)}
            >
              <option value="types">Types only (recommended)</option>
              <option value="all">Types + unlinked gear</option>
            </select>
          </label>
          {mode === "all" ? (
            <label className="text-sm">
              Scope
              <select
                className="ml-2 rounded border border-zinc-700 bg-zinc-900 px-2 py-1"
                value={scope}
                onChange={(e) =>
                  setScope(e.target.value as "both" | "owned" | "manifest")
                }
              >
                <option value="both">both</option>
                <option value="owned">owned</option>
                <option value="manifest">manifest</option>
              </select>
            </label>
          ) : null}
          <label className="text-sm">
            Max results
            <input
              type="number"
              min={1}
              max={500}
              className="ml-2 w-20 rounded border border-zinc-700 bg-zinc-900 px-2 py-1"
              value={limit}
              onChange={(e) => setLimit(Number(e.target.value) || 200)}
            />
          </label>
          <button
            type="button"
            disabled={busy}
            className="rounded bg-amber-600 px-3 py-1.5 text-sm font-medium text-black disabled:opacity-50"
            onClick={() => void runScan()}
          >
            {busy ? "Searching…" : "Search missing types"}
          </button>
          <button
            type="button"
            disabled={busy || !result?.passId || visibleProposals.length === 0}
            className="rounded border border-emerald-700 px-3 py-1.5 text-sm text-emerald-300 disabled:opacity-50"
            onClick={() => void confirmSelected()}
          >
            Confirm selected
          </button>
          <button
            type="button"
            disabled={busy || !result || visibleProposals.length === 0}
            className="rounded border border-zinc-600 px-3 py-1.5 text-sm text-zinc-300 disabled:opacity-50"
            onClick={() => void ignoreSelected()}
            title="Hide selected types from future scans"
          >
            Ignore selected
          </button>
          <button
            type="button"
            disabled={busy || !(result?.ignoredCount)}
            className="rounded border border-zinc-700 px-3 py-1.5 text-sm text-zinc-500 disabled:opacity-50"
            onClick={() => void clearIgnored()}
            title="Restore all ignored missing types"
          >
            Clear ignored
            {result?.ignoredCount ? ` (${result.ignoredCount})` : ""}
          </button>
        </div>
      </div>

      {error ? <p className="text-sm text-red-400">{error}</p> : null}

      {result ? (
        <div className="grid gap-3 lg:grid-cols-[1fr_1.1fr]">
          <div className="space-y-3 rounded border border-zinc-800 p-3 text-sm">
            <p>
              {result.typeGapCount != null
                ? `Type gaps: ${result.typeGapCount}`
                : `Missing: ${result.missingCount}`}
              {result.linkGapCount
                ? ` · link gaps: ${result.linkGapCount}`
                : ""}{" "}
              · showing {visibleProposals.length}
              {result.ignoredCount
                ? ` · ignored ${result.ignoredCount}`
                : ""}
              {listFilter.trim() ? ` (filter “${listFilter.trim()}”)` : ""}
            </p>

            <label className="block text-xs text-zinc-500">
              Filter this list
              <input
                className="mt-1 w-full rounded border border-zinc-800 bg-zinc-950 px-2 py-1.5 text-sm text-zinc-200"
                value={listFilter}
                onChange={(e) => setListFilter(e.target.value)}
                placeholder="Narrow results without re-scanning…"
              />
            </label>

            <p className="text-xs text-zinc-500">
              passId: <code>{result.passId}</code>
            </p>

            {visibleProposals.length === 0 ? (
              <p className="text-zinc-500">
                No missing types match. Try a broader search or clear the filter.
              </p>
            ) : (
              <div className="max-h-[32rem] space-y-1 overflow-auto">
                {visibleProposals.map(({ proposal: p, gap }) => {
                  const label =
                    gap?.displayName ||
                    (p.synergy?.subType
                      ? `${p.synergy.type}: ${p.synergy.subType}`
                      : p.synergy?.type) ||
                    p.id;
                  const fromObjects =
                    gap?.sources?.includes("object_text") ||
                    (gap?.mentionCount != null && gap.mentionCount > 0);
                  const isFocused = focusedId === p.id;
                  return (
                    <div
                      key={p.id}
                      className={`flex items-start gap-2 border-b border-zinc-900 py-1.5 px-1 ${
                        isFocused ? "bg-zinc-900/80 ring-1 ring-amber-700/50" : ""
                      }`}
                    >
                      <input
                        type="checkbox"
                        className="mt-1"
                        checked={selected[p.id] ?? false}
                        onChange={(e) =>
                          setSelected((prev) => ({
                            ...prev,
                            [p.id]: e.target.checked,
                          }))
                        }
                      />
                      <button
                        type="button"
                        className="min-w-0 flex-1 text-left"
                        onClick={() => setFocusedId(p.id)}
                      >
                        <span className="font-medium text-zinc-100">{label}</span>
                        <span className="ml-2 text-xs uppercase tracking-wide text-zinc-500">
                          {gap?.gapKind === "link" ? "link" : "type"}
                          {fromObjects ? " · from objects" : ""}
                          {gap?.mentionCount != null
                            ? ` · ×${gap.mentionCount}`
                            : ""}
                          {(gap?.references?.length ?? 0) > 0
                            ? ` · ${Math.min(10, gap!.references!.length)} refs`
                            : ""}
                        </span>
                        {p.rationale ? (
                          <span className="mt-0.5 block text-xs text-zinc-500">
                            {p.rationale}
                          </span>
                        ) : null}
                      </button>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          <div className="rounded border border-zinc-800 p-3 text-sm">
            {!focused ? (
              <p className="text-zinc-500">
                Select a missing type to view object references and snippets.
              </p>
            ) : (
              <div className="space-y-3">
                <div>
                  <h2 className="text-base font-medium text-zinc-100">
                    {focused.gap?.displayName ?? focused.proposal.id}
                  </h2>
                  <p className="text-xs text-zinc-500">
                    {focused.gap?.suggestedType}
                    {focused.gap?.suggestedSubType
                      ? ` · ${focused.gap.suggestedSubType}`
                      : ""}
                    {focused.gap?.mentionCount != null
                      ? ` · ${focused.gap.mentionCount} mention(s)`
                      : ""}
                  </p>
                </div>

                <div>
                  <h3 className="mb-2 text-[11px] font-medium uppercase tracking-widest text-amber-400/90">
                    References (first {shownRefs.length}
                    {references.length > 10
                      ? ` of ${references.length}+`
                      : references.length > shownRefs.length
                        ? ` of ${references.length}`
                        : ""}
                    )
                  </h3>
                  {shownRefs.length === 0 ? (
                    <p className="text-xs text-zinc-500">
                      No object snippets stored for this gap (vocab-only or link
                      gap).
                    </p>
                  ) : (
                    <ol className="max-h-[28rem] space-y-3 overflow-auto">
                      {shownRefs.map((ref, i) => (
                        <li
                          key={`${ref.store}-${ref.hash ?? ref.name}-${i}`}
                          className="rounded border border-zinc-800 bg-zinc-950/60 p-2"
                        >
                          <div className="flex flex-wrap items-baseline gap-x-2 gap-y-0.5">
                            <span className="text-[10px] uppercase tracking-wider text-zinc-500">
                              {i + 1}. {ref.store}
                            </span>
                            <span className="font-medium text-zinc-200">
                              {ref.name}
                            </span>
                            {ref.hash != null ? (
                              <span className="text-[10px] text-zinc-600">
                                hash {ref.hash}
                              </span>
                            ) : null}
                          </div>
                          <p className="mt-1 text-xs leading-relaxed text-zinc-400">
                            {ref.snippet || "(no snippet)"}
                          </p>
                        </li>
                      ))}
                    </ol>
                  )}
                </div>
              </div>
            )}
          </div>
        </div>
      ) : null}

      {confirmResult ? (
        <pre className="overflow-auto rounded border border-zinc-800 bg-zinc-900 p-3 text-xs">
          {JSON.stringify(confirmResult, null, 2)}
        </pre>
      ) : null}
    </div>
  );
}
