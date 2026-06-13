"use client";

import { useState } from "react";
import { BuildForm } from "./BuildForm";
import { EditableBuildSheet } from "./sheet/EditableBuildSheet";
import { ExportPanel } from "./ExportPanel";
import { WaitingProgressPanel } from "./WaitingProgressPanel";
import { loadAuthStatus } from "@/components/BungieAuthControl";
import type { BuildRequest } from "@/lib/llm/buildSchema";
import type { GeneratedBuild } from "@/lib/llm/buildSchema";
import type { ResolvedBuildSheet } from "@/lib/build/types";
import type { BuildApiResponse } from "./buildResponse";

type GeneratorState =
  | { phase: "idle" }
  | { phase: "generating"; abortController: AbortController }
  | { phase: "done"; response: BuildApiResponse }
  | { phase: "error"; message: string };

function formatClientFetchError(message: string): string {
  if (message === "fetch failed" || message === "Failed to fetch") {
    return "Connection to the app was lost. If generation was still running, ensure LM Studio/Ollama stays open and try again. Check Settings for LLM status.";
  }
  return message;
}

function ErrorPanel({ message, onReset }: { message: string; onReset: () => void }) {
  return (
    <div className="panel-notch border-danger/40 p-6 space-y-4">
      <div className="text-[11px] tracking-widest uppercase text-danger mb-2">Error</div>
      <p className="text-sm text-foreground leading-relaxed">{message}</p>
      <button
        type="button"
        onClick={onReset}
        className="text-xs border border-line px-4 py-1.5 text-muted hover:text-foreground hover:border-foreground/40 transition-colors focus-visible:outline-accent"
      >
        Try Again
      </button>
    </div>
  );
}

function MetaStrip({ count, summary }: { count: number; summary: string }) {
  return (
    <div className="flex flex-wrap items-baseline gap-4 text-xs text-muted border-b border-line pb-3 mb-3">
      <span>{count} tool calls</span>
      <span className="flex-1 truncate" title={summary}>{summary}</span>
    </div>
  );
}

function ResultActions({
  onRegenerate,
  onVariation,
  onSave,
  saving,
  saveError,
  saveDone,
}: {
  onRegenerate: () => void;
  onVariation: () => void;
  onSave: () => void;
  saving: boolean;
  saveError: string | null;
  saveDone: boolean;
}) {
  const buttonClass =
    "text-xs border border-line px-4 py-1.5 text-muted hover:text-foreground hover:border-foreground/40 transition-colors focus-visible:outline-accent disabled:opacity-50";
  return (
    <div className="space-y-2">
      <div className="flex flex-wrap items-center gap-3">
        <button type="button" onClick={onRegenerate} className={buttonClass}>
          Regenerate
        </button>
        <button type="button" onClick={onVariation} className={buttonClass}>
          Try a Different Angle
        </button>
        <button type="button" onClick={onSave} disabled={saving} className={buttonClass}>
          {saving ? "Saving…" : "Save Loadout"}
        </button>
      </div>
      {saveDone && <p className="text-xs text-muted">Loadout saved. View it in Loadouts.</p>}
      {saveError && <p className="text-xs text-danger">{saveError}</p>}
    </div>
  );
}

/** Augments the original request so the model steers away from the last build. */
function variationRequest(request: BuildRequest, response: BuildApiResponse): BuildRequest {
  const avoidExotic = response.sheet.exoticArmor.requestedName;
  const directive = `Produce a meaningfully different build than "${response.build.name}": pick a different exotic armor piece than ${avoidExotic} and a different core engine.`;
  const notes = request.notes ? `${request.notes}\n${directive}` : directive;
  return { ...request, notes };
}

export function GeneratorPage({ multiPassAvailable = false }: { multiPassAvailable?: boolean }) {
  const [state, setState] = useState<GeneratorState>({ phase: "idle" });
  const [lastRequest, setLastRequest] = useState<BuildRequest | null>(null);
  const [liveBuild, setLiveBuild] = useState<GeneratedBuild | null>(null);
  const [liveSheet, setLiveSheet] = useState<ResolvedBuildSheet | null>(null);
  const [saving, setSaving] = useState(false);
  const [saveError, setSaveError] = useState<string | null>(null);
  const [saveDone, setSaveDone] = useState(false);

  const handleSubmit = async (req: BuildRequest) => {
    const ac = new AbortController();
    setLastRequest(req);
    setSaveDone(false);
    setSaveError(null);
    setState({ phase: "generating", abortController: ac });

    try {
      const res = await fetch("/api/build", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(req),
        signal: ac.signal,
      });

      if (!res.ok) {
        const body = await res.json() as { error: string };
        // #region agent log
        fetch('http://127.0.0.1:7497/ingest/c1e77a25-b3cb-458d-a22e-6f4c8c0c4060',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'7c9b57'},body:JSON.stringify({sessionId:'7c9b57',location:'GeneratorPage.tsx:handleSubmit',message:'api non-ok response',data:{status:res.status,error:body.error},timestamp:Date.now(),hypothesisId:'B'})}).catch(()=>{});
        // #endregion
        const hint = res.status === 503 ? " — Open Settings to download the manifest." : "";
        setState({ phase: "error", message: `${body.error}${hint}` });
        return;
      }

      const data = await res.json() as BuildApiResponse;
      setLiveBuild(data.build);
      setLiveSheet(data.sheet);
      setState({ phase: "done", response: data });
    } catch (err) {
      if (err instanceof DOMException && err.name === "AbortError") {
        setState({ phase: "idle" });
        return;
      }
      const message = formatClientFetchError(
        err instanceof Error ? err.message : "Build generation failed",
      );
      // #region agent log
      fetch('http://127.0.0.1:7497/ingest/c1e77a25-b3cb-458d-a22e-6f4c8c0c4060',{method:'POST',headers:{'Content-Type':'application/json','X-Debug-Session-Id':'7c9b57'},body:JSON.stringify({sessionId:'7c9b57',location:'GeneratorPage.tsx:catch',message:'client fetch threw',data:{message,name:err instanceof Error?err.name:'unknown',cause:err instanceof Error&&'cause' in err?String((err as Error&{cause?:unknown}).cause):undefined},timestamp:Date.now(),hypothesisId:'B'})}).catch(()=>{});
      // #endregion
      setState({ phase: "error", message });
    }
  };

  const handleCancel = () => {
    if (state.phase === "generating") {
      state.abortController.abort();
    }
  };

  const handleSaveLoadout = async () => {
    if (state.phase !== "done" || !lastRequest || !liveBuild || !liveSheet) return;

    const { auth } = await loadAuthStatus();
    if (!auth.signedIn) {
      setSaveError("Sign in with Bungie to save loadouts.");
      return;
    }

    const defaultName = state.response.build.name;
    const name = window.prompt("Loadout name", defaultName)?.trim();
    if (!name) return;

    setSaving(true);
    setSaveError(null);
    setSaveDone(false);

    try {
      const res = await fetch("/api/user/loadouts", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          name,
          source: "generator",
          buildRequest: lastRequest,
          generatedBuild: liveBuild,
          resolvedSheet: liveSheet,
        }),
      });

      if (!res.ok) {
        const body = await res.json() as { error?: string };
        setSaveError(body.error ?? "Failed to save loadout");
        return;
      }

      setSaveDone(true);
    } catch {
      setSaveError("Failed to save loadout");
    } finally {
      setSaving(false);
    }
  };

  const isGenerating = state.phase === "generating";

  return (
    <div className="flex-1 flex flex-col xl:flex-row gap-8 p-6 max-w-[1600px] mx-auto w-full">
      <div className="xl:w-[380px] flex-shrink-0">
        <BuildForm
          onSubmit={handleSubmit}
          isGenerating={isGenerating}
          multiPassAvailable={multiPassAvailable}
        />
      </div>

      <div className="flex-1 min-w-0 space-y-6">
        {state.phase === "idle" && (
          <div className="panel-notch p-8 text-center">
            <p className="text-muted text-sm">
              Configure your build and click <span className="text-accent">Generate Build</span> to start.
            </p>
          </div>
        )}

        {state.phase === "generating" && (
          <WaitingProgressPanel label="Generating" onCancel={handleCancel} />
        )}

        {state.phase === "error" && (
          <ErrorPanel message={state.message} onReset={() => setState({ phase: "idle" })} />
        )}

        {state.phase === "done" && liveBuild && liveSheet && lastRequest && (
          <>
            <MetaStrip
              count={state.response.toolCallCount}
              summary={state.response.researchSummary}
            />
            <ResultActions
              onRegenerate={() => void handleSubmit(lastRequest)}
              onVariation={() =>
                void handleSubmit(variationRequest(lastRequest, state.response))
              }
              onSave={() => void handleSaveLoadout()}
              saving={saving}
              saveError={saveError}
              saveDone={saveDone}
            />
            <EditableBuildSheet
              sheet={liveSheet}
              build={liveBuild}
              activity={lastRequest.activity}
              className={lastRequest.className}
              onUpdate={({ build, sheet }) => {
                setLiveBuild(build);
                setLiveSheet(sheet);
                setState((prev) =>
                  prev.phase === "done"
                    ? { ...prev, response: { ...prev.response, build, sheet } }
                    : prev,
                );
              }}
            />
            <ExportPanel
              exports={state.response.exports}
              build={liveBuild}
              sheet={liveSheet}
              shareClassName={lastRequest.className}
            />
          </>
        )}
      </div>
    </div>
  );
}
