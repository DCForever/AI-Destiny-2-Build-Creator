"use client";

import { useCallback, useEffect, useState } from "react";

export interface StatusCardProps {
  title: string;
  description: string;
  load: () => Promise<{ ok: boolean; lines: string[] }>;
}

function Spinner() {
  return (
    <span
      className="inline-block size-3 border border-line border-t-accent rounded-full animate-spin"
      aria-hidden="true"
    />
  );
}

function StatusBadge({ loading, ok }: { loading: boolean; ok: boolean }) {
  if (loading) {
    return (
      <span className="flex items-center gap-2" aria-label="Checking status">
        <Spinner />
      </span>
    );
  }

  if (ok) {
    return <span className="badge badge-verified">ONLINE</span>;
  }

  return <span className="badge badge-unresolved">OFFLINE</span>;
}

export function StatusCard({ title, description, load }: StatusCardProps) {
  const [loading, setLoading] = useState(true);
  const [ok, setOk] = useState(false);
  const [lines, setLines] = useState<string[]>([]);

  const runLoad = useCallback(async () => {
    setLoading(true);
    try {
      const result = await load();
      setOk(result.ok);
      setLines(result.lines);
    } catch (err) {
      const message = err instanceof Error ? err.message : "Check failed";
      setOk(false);
      setLines([message]);
    } finally {
      setLoading(false);
    }
  }, [load]);

  useEffect(() => {
    let cancelled = false;
    void (async () => {
      setLoading(true);
      try {
        const result = await load();
        if (cancelled) return;
        setOk(result.ok);
        setLines(result.lines);
      } catch (err) {
        if (cancelled) return;
        const message = err instanceof Error ? err.message : "Check failed";
        setOk(false);
        setLines([message]);
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [load]);

  return (
    <div className="panel-notch p-5 space-y-4">
      <div className="flex items-center justify-between gap-3">
        <h2 className="text-[11px] tracking-widest uppercase text-muted">{title}</h2>
        <StatusBadge loading={loading} ok={ok} />
      </div>

      <p className="text-xs text-muted leading-relaxed">{description}</p>

      {lines.length > 0 && (
        <div className="space-y-1" role="status" aria-live="polite">
          {lines.map((line, index) => (
            <div key={`${index}-${line}`} className="font-mono text-xs text-foreground">
              {line}
            </div>
          ))}
        </div>
      )}

      <button
        type="button"
        onClick={() => void runLoad()}
        disabled={loading}
        className="text-xs border border-line px-4 py-1.5 text-muted hover:text-foreground hover:border-foreground/40 transition-colors focus-visible:outline-accent disabled:opacity-50"
      >
        Recheck
      </button>
    </div>
  );
}
