"use client";

import { useState } from "react";
import { BuildForm } from "./BuildForm";
import { BuildSheet } from "./sheet/BuildSheet";
import { ExportPanel } from "./ExportPanel";
import { WaitingProgressPanel } from "./WaitingProgressPanel";
import type { BuildRequest } from "@/lib/llm/buildSchema";
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
}: {
  onRegenerate: () => void;
  onVariation: () => void;
}) {
  const buttonClass =
    "text-xs border border-line px-4 py-1.5 text-muted hover:text-foreground hover:border-foreground/40 transition-colors focus-visible:outline-accent";
  return (
    <div className="flex flex-wrap items-center gap-3">
      <button type="button" onClick={onRegenerate} className={buttonClass}>
        Regenerate
      </button>
      <button type="button" onClick={onVariation} className={buttonClass}>
        Try a Different Angle
      </button>
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

export function GeneratorPage() {
  const [state, setState] = useState<GeneratorState>({ phase: "idle" });
  const [lastRequest, setLastRequest] = useState<BuildRequest | null>(null);

  const handleSubmit = async (req: BuildRequest) => {
    const ac = new AbortController();
    setLastRequest(req);
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

  const isGenerating = state.phase === "generating";

  return (
    <div className="flex-1 flex flex-col xl:flex-row gap-8 p-6 max-w-[1600px] mx-auto w-full">
      <div className="xl:w-[380px] flex-shrink-0">
        <BuildForm onSubmit={handleSubmit} isGenerating={isGenerating} />
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

        {state.phase === "done" && (
          <>
            <MetaStrip
              count={state.response.toolCallCount}
              summary={state.response.researchSummary}
            />
            {lastRequest && (
              <ResultActions
                onRegenerate={() => void handleSubmit(lastRequest)}
                onVariation={() =>
                  void handleSubmit(variationRequest(lastRequest, state.response))
                }
              />
            )}
            <BuildSheet sheet={state.response.sheet} />
            <ExportPanel
              exports={state.response.exports}
              build={state.response.build}
              sheet={state.response.sheet}
              shareClassName={lastRequest?.className}
            />
          </>
        )}
      </div>
    </div>
  );
}
