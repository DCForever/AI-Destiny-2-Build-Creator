"use client";

import { useEffect, useState } from "react";

function formatElapsed(seconds: number): string {
  if (seconds < 60) return `${seconds}s`;
  const minutes = Math.floor(seconds / 60);
  const remainder = seconds % 60;
  return `${minutes}m ${remainder}s`;
}

interface WaitingProgressPanelProps {
  label: "Generating" | "Analyzing";
  onCancel: () => void;
}

export function WaitingProgressPanel({ label, onCancel }: WaitingProgressPanelProps) {
  const [elapsedSeconds, setElapsedSeconds] = useState(0);

  useEffect(() => {
    const startedAt = Date.now();
    const id = setInterval(() => {
      setElapsedSeconds(Math.floor((Date.now() - startedAt) / 1000));
    }, 1000);
    return () => clearInterval(id);
  }, []);

  return (
    <div className="panel-notch p-6" aria-busy="true" aria-label={`${label} build`}>
      <div className="text-[11px] tracking-widest uppercase text-muted mb-4">
        {label} · {formatElapsed(elapsedSeconds)}
      </div>
      <p className="text-sm text-muted mb-6">Waiting for model response…</p>
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
