"use client";

import { useState, useEffect } from "react";
import { BuildForm } from "./BuildForm";
import { BuildSheet } from "./sheet/BuildSheet";
import { ExportPanel } from "./ExportPanel";
import type { BuildRequest } from "@/lib/llm/buildSchema";
import type { BuildApiResponse } from "./buildResponse";

type GeneratorState =
  | { phase: "idle" }
  | { phase: "generating"; abortController: AbortController }
  | { phase: "done"; response: BuildApiResponse }
  | { phase: "error"; message: string };

const PROGRESS_STAGES = [
  "Researching manifest + meta…",
  "Composing build…",
  "Validating against manifest…",
];

function ProgressPanel({ onCancel }: { onCancel: () => void }) {
  const [stageIdx, setStageIdx] = useState(0);

  useEffect(() => {
    const id = setInterval(() => {
      setStageIdx((prev) => Math.min(prev + 1, PROGRESS_STAGES.length - 1));
    }, 20_000);
    return () => clearInterval(id);
  }, []);

  return (
    <div className="panel-notch p-6" aria-busy="true" aria-label="Generating build">
      <div className="text-[11px] tracking-widest uppercase text-muted mb-4">
        Estimated · Generating
      </div>
      <div className="space-y-3 mb-6">
        {PROGRESS_STAGES.map((label, i) => (
          <div
            key={label}
            className={`flex items-center gap-3 ${i <= stageIdx ? "text-foreground" : "text-muted"}`}
          >
            <div
              className={`w-1.5 h-1.5 rounded-full flex-shrink-0 ${
                i < stageIdx ? "bg-success" : i === stageIdx ? "bg-accent pulse-line" : "bg-line"
              }`}
            />
            <span className="text-sm">{label}</span>
          </div>
        ))}
      </div>
      <button
        type="button"
        onClick={onCancel}
        className="text-xs text-danger border border-danger/30 px-4 py-1.5 hover:bg-danger/10 transition-colors focus-visible:outline-accent"
      >
        Cancel
      </button>
    </div>
  );
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

export function GeneratorPage() {
  const [state, setState] = useState<GeneratorState>({ phase: "idle" });

  const handleSubmit = async (req: BuildRequest) => {
    const ac = new AbortController();
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
      const message = err instanceof Error ? err.message : "Build generation failed";
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
          <ProgressPanel onCancel={handleCancel} />
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
            <BuildSheet sheet={state.response.sheet} />
            <ExportPanel exports={state.response.exports} build={state.response.build} />
          </>
        )}
      </div>
    </div>
  );
}
