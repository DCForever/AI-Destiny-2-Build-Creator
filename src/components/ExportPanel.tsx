"use client";

import { useState } from "react";
import type { GeneratedBuild } from "@/lib/llm/buildSchema";
import type { ResolvedBuildSheet } from "@/lib/build/types";

type TabId = "wishlist" | "lo" | "json";
type ShareState =
  | { kind: "idle" }
  | { kind: "sharing" }
  | { kind: "success"; url: string }
  | { kind: "error"; message: string };

interface ExportPanelProps {
  exports?: { wishlistText: string; loParamsText: string; skipped: string[] };
  build: GeneratedBuild;
  sheet?: ResolvedBuildSheet;
  shareClassName?: "Titan" | "Hunter" | "Warlock";
}

function toKebab(name: string): string {
  return name
    .toLowerCase()
    .replace(/\s+/g, "-")
    .replace(/[^a-z0-9-]/g, "");
}

function downloadJson(build: GeneratedBuild) {
  const blob = new Blob([JSON.stringify(build, null, 2)], { type: "application/json" });
  const url = URL.createObjectURL(blob);
  const a = document.createElement("a");
  a.href = url;
  a.download = `${toKebab(build.name)}.json`;
  a.click();
  URL.revokeObjectURL(url);
}

function CopyButton({ text }: { text: string }) {
  const [copied, setCopied] = useState(false);

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(text);
      setCopied(true);
      setTimeout(() => setCopied(false), 1500);
    } catch {
      /* clipboard unavailable */
    }
  };

  return (
    <button
      type="button"
      onClick={handleCopy}
      className="text-xs border border-line px-3 py-1 hover:border-accent hover:text-accent transition-colors focus-visible:outline-accent"
    >
      {copied ? "Copied" : "Copy"}
    </button>
  );
}

function TextTab({ text, skipped }: { text: string; skipped: string[] }) {
  return (
    <div className="space-y-3">
      <div className="flex justify-end">
        <CopyButton text={text} />
      </div>
      <pre className="font-mono text-xs text-foreground bg-background border border-line p-3 overflow-x-auto whitespace-pre-wrap break-all max-h-80">
        {text}
      </pre>
      {skipped.length > 0 && (
        <div className="space-y-1">
          <div className="text-[11px] tracking-widest uppercase text-warning">Skipped</div>
          {skipped.map((s) => (
            <p key={s} className="text-xs text-warning/80">{s}</p>
          ))}
        </div>
      )}
    </div>
  );
}

function UnavailableNote() {
  return <p className="text-xs text-muted italic">Exports unavailable for this build.</p>;
}

function JsonTab({ build }: { build: GeneratedBuild }) {
  const preview = JSON.stringify(build, null, 2).slice(0, 600);
  return (
    <div className="space-y-3">
      <button
        type="button"
        onClick={() => downloadJson(build)}
        className="text-xs border border-accent text-accent px-3 py-1.5 hover:bg-accent/10 transition-colors focus-visible:outline-accent"
      >
        Download {toKebab(build.name)}.json
      </button>
      <details>
        <summary className="text-[11px] tracking-widest uppercase text-muted cursor-pointer select-none">
          Preview
        </summary>
        <pre className="font-mono text-xs text-muted bg-background border border-line p-3 mt-2 overflow-x-auto whitespace-pre-wrap break-all max-h-64">
          {preview}…
        </pre>
      </details>
    </div>
  );
}

const TABS: { id: TabId; label: string }[] = [
  { id: "wishlist", label: "DIM Wishlist" },
  { id: "lo", label: "Loadout Optimizer" },
  { id: "json", label: "JSON" },
];

function DimShareButton({
  sheet,
  className,
}: {
  sheet: ResolvedBuildSheet;
  className: "Titan" | "Hunter" | "Warlock";
}) {
  const [state, setState] = useState<ShareState>({ kind: "idle" });
  const [urlCopied, setUrlCopied] = useState(false);

  const handleShare = async () => {
    setState({ kind: "sharing" });
    try {
      const res = await fetch("/api/dim/share", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ sheet, className }),
      });
      const data = (await res.json()) as Record<string, unknown>;
      if (!res.ok) {
        setState({ kind: "error", message: String(data.error ?? "Sharing failed.") });
        return;
      }
      setState({ kind: "success", url: String(data.shareUrl) });
    } catch {
      setState({ kind: "error", message: "Network error — could not reach the share API." });
    }
  };

  const handleCopyUrl = async (url: string) => {
    try {
      await navigator.clipboard.writeText(url);
      setUrlCopied(true);
      setTimeout(() => setUrlCopied(false), 1500);
    } catch {
      /* clipboard unavailable */
    }
  };

  if (state.kind === "success") {
    return (
      <div className="flex items-center gap-2 flex-wrap">
        <a
          href={state.url}
          target="_blank"
          rel="noreferrer"
          className="text-xs text-accent underline underline-offset-2 hover:opacity-80 transition-opacity"
        >
          {state.url}
        </a>
        <button
          type="button"
          onClick={() => handleCopyUrl(state.url)}
          className="text-xs border border-line px-3 py-1 hover:border-accent hover:text-accent transition-colors focus-visible:outline-accent"
        >
          {urlCopied ? "Copied" : "Copy"}
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-1">
      <button
        type="button"
        onClick={handleShare}
        disabled={state.kind === "sharing"}
        className="text-xs border border-line px-3 py-1.5 hover:border-accent hover:text-accent transition-colors focus-visible:outline-accent disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
      >
        {state.kind === "sharing" && (
          <span className="inline-block h-3 w-3 rounded-full border-2 border-current border-t-transparent animate-spin" />
        )}
        Share to dim.gg
      </button>
      {state.kind === "error" && (
        <p className="text-xs text-danger">{state.message}</p>
      )}
    </div>
  );
}

export function ExportPanel({ exports, build, sheet, shareClassName }: ExportPanelProps) {
  const [active, setActive] = useState<TabId>("wishlist");
  const showDimShare = sheet !== undefined && shareClassName !== undefined;

  return (
    <div className="panel-notch p-4 space-y-4">
      <div className="flex gap-0 border-b border-line">
        {TABS.map(({ id, label }) => (
          <button
            key={id}
            type="button"
            onClick={() => setActive(id)}
            className={`px-4 py-2 text-xs tracking-wide transition-colors focus-visible:outline-accent ${
              active === id
                ? "text-accent border-b border-accent -mb-px"
                : "text-muted hover:text-foreground"
            }`}
          >
            {label}
          </button>
        ))}
      </div>

      <div>
        {active === "wishlist" && (
          exports ? (
            <TextTab text={exports.wishlistText} skipped={exports.skipped} />
          ) : (
            <UnavailableNote />
          )
        )}
        {active === "lo" && (
          exports ? (
            <TextTab text={exports.loParamsText} skipped={[]} />
          ) : (
            <UnavailableNote />
          )
        )}
        {active === "json" && <JsonTab build={build} />}
      </div>

      {showDimShare && (
        <div className="pt-3 border-t border-line">
          <DimShareButton sheet={sheet} className={shareClassName} />
        </div>
      )}
    </div>
  );
}
