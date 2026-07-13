"use client";

import { useCallback, useState } from "react";

type Proposal = {
  id: string;
  kind: string;
  rationale?: string;
  synergy?: { name?: string; type: string; subType?: string | null };
  keyword?: { term: string };
};

type JsonPanel = { label: string; request?: unknown; response?: unknown; error?: unknown };

export function LlmProposeDebugPage() {
  const [descriptions, setDescriptions] = useState(
    "Solar scorch loop with Sunshot and healing grenade for mid-tier PvE.",
  );
  const [passId, setPassId] = useState("");
  const [proposals, setProposals] = useState<Proposal[]>([]);
  const [selected, setSelected] = useState<Record<string, boolean>>({});
  const [panel, setPanel] = useState<JsonPanel>({ label: "Ready" });

  const record = useCallback((next: JsonPanel) => setPanel(next), []);

  async function startPass() {
    const url = "/api/llm/propose-pass";
    const payload = { descriptions, useMock: true };
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    if (res.ok) {
      setPassId(body.passId);
      setProposals(body.proposals ?? []);
      const next: Record<string, boolean> = {};
      for (const p of body.proposals ?? []) next[p.id] = p.kind === "synergy";
      setSelected(next);
    }
    record({
      label: `POST ${url}`,
      request: payload,
      response: res.ok ? body : undefined,
      error: res.ok ? undefined : body,
    });
  }

  async function confirmSelected() {
    if (!passId) return;
    const acceptedIds = Object.entries(selected)
      .filter(([, on]) => on)
      .map(([id]) => id);
    const skippedIds = proposals.map((p) => p.id).filter((id) => !acceptedIds.includes(id));
    const url = `/api/llm/propose-pass/${passId}/confirm`;
    const payload = { acceptedIds, skippedIds, proposals };
    const res = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    const body = await res.json();
    record({
      label: `POST ${url}`,
      request: payload,
      response: res.ok ? body : undefined,
      error: res.ok ? undefined : body,
    });
  }

  return (
    <div className="mx-auto max-w-3xl space-y-4">
      <h1 className="text-lg font-semibold">LLM propose-for-confirm</h1>
      <p className="text-sm text-zinc-400">
        Manual pass only. Proposals are ephemeral until you confirm. Synergy confirms create library
        records; keywords are acknowledged but not auto-applied to builds.
      </p>
      <label className="block text-sm">
        Descriptions
        <textarea
          className="mt-1 block w-full rounded border border-zinc-800 bg-zinc-900 px-2 py-1 text-sm"
          rows={5}
          value={descriptions}
          onChange={(e) => setDescriptions(e.target.value)}
        />
      </label>
      <div className="flex flex-wrap gap-2">
        <button
          type="button"
          className="rounded bg-emerald-700 px-3 py-1 text-sm text-white"
          onClick={() => void startPass()}
        >
          Start mock pass
        </button>
        <button
          type="button"
          className="rounded bg-emerald-700 px-3 py-1 text-sm text-white disabled:bg-zinc-800 disabled:text-zinc-500"
          disabled={!passId || proposals.length === 0}
          onClick={() => void confirmSelected()}
        >
          Confirm selected
        </button>
      </div>
      {passId ? <p className="text-xs text-zinc-500">passId: {passId}</p> : null}
      <ul className="space-y-2">
        {proposals.map((p) => (
          <li key={p.id} className="rounded border border-zinc-800 bg-zinc-900 px-3 py-2 text-sm">
            <label className="flex items-start gap-2">
              <input
                type="checkbox"
                checked={Boolean(selected[p.id])}
                onChange={(e) => setSelected((s) => ({ ...s, [p.id]: e.target.checked }))}
              />
              <span>
                <span className="font-medium">{p.kind}</span> · {p.id}
                {p.synergy ? (
                  <span className="block text-zinc-400">
                    {p.synergy.name ?? "(unnamed)"} · {p.synergy.type}
                    {p.synergy.subType ? ` / ${p.synergy.subType}` : ""}
                  </span>
                ) : null}
                {p.keyword ? (
                  <span className="block text-zinc-400">keyword: {p.keyword.term}</span>
                ) : null}
                {p.rationale ? <span className="block text-xs text-zinc-500">{p.rationale}</span> : null}
              </span>
            </label>
          </li>
        ))}
      </ul>
      <pre className="overflow-auto rounded border border-zinc-800 bg-zinc-950 p-3 text-xs">
        {JSON.stringify(panel, null, 2)}
      </pre>
    </div>
  );
}
