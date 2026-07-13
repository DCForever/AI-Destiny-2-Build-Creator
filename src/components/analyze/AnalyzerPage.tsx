"use client";

import { useState } from "react";
import type { AnalyzeRequest } from "@/lib/llm/analyzeSchema";
import { AnalyzeForm } from "./AnalyzeForm";
import { BungieImport } from "./BungieImport";
import { AnalysisReport } from "./AnalysisReport";
import { BuildSheet } from "@/components/sheet/BuildSheet";
import { ExportPanel } from "@/components/ExportPanel";
import { WaitingProgressPanel } from "@/components/WaitingProgressPanel";
import type { AnalyzeApiResponse } from "./analyzeResponse";
import {
  Button,
  EmptyState,
  Panel,
  SectionLabel,
  Stack,
  Text,
} from "@/components/ui";

type AnalyzerState =
  | { phase: "idle" }
  | { phase: "analyzing"; abortController: AbortController }
  | { phase: "done"; response: AnalyzeApiResponse }
  | { phase: "error"; message: string };

function SectionHeader({ title }: { title: string }) {
  return (
    <div className="mb-4">
      <SectionLabel>{title}</SectionLabel>
      <div className="keyline mt-1" />
    </div>
  );
}

function ErrorPanel({ message, onReset }: { message: string; onReset: () => void }) {
  return (
    <Panel tone="danger" pad="lg">
      <Stack gap={12}>
        <Text size="xs" tone="danger" className="tracking-widest uppercase">
          Error
        </Text>
        <Text size="sm" className="leading-relaxed">
          {message}
        </Text>
        <Button size="sm" variant="outline" onClick={onReset}>
          Try Again
        </Button>
      </Stack>
    </Panel>
  );
}

function MetaStrip({ count, summary }: { count: number; summary: string }) {
  return (
    <div className="flex flex-wrap items-baseline gap-4 text-xs text-muted border-b border-line pb-3 mb-3">
      <span>{count} tool calls</span>
      <span className="flex-1 truncate" title={summary}>
        {summary}
      </span>
    </div>
  );
}

export function AnalyzerPage() {
  const [state, setState] = useState<AnalyzerState>({ phase: "idle" });
  const [loadoutText, setLoadoutText] = useState("");
  const [className, setClassName] = useState<AnalyzeRequest["className"]>("Titan");
  const [submittedClassName, setSubmittedClassName] =
    useState<AnalyzeRequest["className"]>("Titan");

  const handleSubmit = async (req: AnalyzeRequest) => {
    const ac = new AbortController();
    setSubmittedClassName(req.className);
    setState({ phase: "analyzing", abortController: ac });

    try {
      const res = await fetch("/api/analyze", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(req),
        signal: ac.signal,
      });

      if (!res.ok) {
        const body = (await res.json()) as { error: string };
        const hint = res.status === 503 ? " — Open Settings to download the manifest." : "";
        setState({ phase: "error", message: `${body.error}${hint}` });
        return;
      }

      const data = (await res.json()) as AnalyzeApiResponse;
      setState({ phase: "done", response: data });
    } catch (err) {
      if (err instanceof DOMException && err.name === "AbortError") {
        setState({ phase: "idle" });
        return;
      }
      const message = err instanceof Error ? err.message : "Loadout analysis failed";
      setState({ phase: "error", message });
    }
  };

  const handleCancel = () => {
    if (state.phase === "analyzing") {
      state.abortController.abort();
    }
  };

  const handleImport = (text: string, importedClass: AnalyzeRequest["className"]) => {
    setLoadoutText(text);
    setClassName(importedClass);
  };

  const isAnalyzing = state.phase === "analyzing";

  return (
    <div className="flex-1 max-w-[1600px] mx-auto px-4 sm:px-6 py-4 sm:py-6 w-full">
      <div className="flex flex-col xl:flex-row gap-6 xl:gap-8">
        <div className="xl:w-[380px] flex-shrink-0 space-y-6">
          <AnalyzeForm
            onSubmit={handleSubmit}
            disabled={isAnalyzing}
            loadoutText={loadoutText}
            onLoadoutTextChange={setLoadoutText}
            className={className}
            onClassNameChange={setClassName}
          />
          <BungieImport onImport={handleImport} />
        </div>

        <div className="flex-1 min-w-0 space-y-6">
          {state.phase === "idle" && (
            <EmptyState
              description={
                <>
                  Paste your loadout or import from Bungie, then click{" "}
                  <span className="text-accent">Analyze Loadout</span> to start.
                </>
              }
            />
          )}

          {state.phase === "analyzing" && (
            <WaitingProgressPanel label="Analyzing" onCancel={handleCancel} />
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
              <AnalysisReport analysis={state.response.analysis} />
              <section>
                <SectionHeader title="Optimized Build" />
                <BuildSheet sheet={state.response.sheet} />
              </section>
              <ExportPanel
                exports={state.response.exports}
                build={state.response.sheet.build}
                sheet={state.response.sheet}
                shareClassName={submittedClassName}
              />
            </>
          )}
        </div>
      </div>
    </div>
  );
}
