import type { ResolvedStatTarget } from "@/lib/build/types";

const STAT_MAX = 200;

interface StatTrackProps {
  target: number;
}

function StatTrack({ target }: StatTrackProps) {
  const pct = Math.min((target / STAT_MAX) * 100, 100);
  return (
    <div className="relative h-1 bg-surface-raised my-2">
      <div
        className="absolute inset-y-0 left-0 bg-accent/50"
        style={{ width: `${pct}%` }}
      />
      <div
        className="absolute inset-y-0 w-px bg-muted/40"
        style={{ left: "50%" }}
      />
      <div
        className="absolute top-1/2 w-2 h-2 rounded-full bg-accent border border-background"
        style={{ left: `${pct}%`, transform: "translate(-50%, -50%)" }}
      />
    </div>
  );
}

interface StatRowProps {
  target: ResolvedStatTarget;
}

function StatRow({ target: st }: StatRowProps) {
  const isEnhanced = st.target > 100;
  return (
    <div className="panel-notch p-4">
      <div className="flex items-baseline justify-between mb-1">
        <span className="text-[11px] tracking-widest uppercase text-muted">{st.stat}</span>
        <span
          className={`font-display text-2xl leading-none ${isEnhanced ? "text-accent" : "text-foreground"}`}
        >
          {st.target}
        </span>
      </div>
      <StatTrack target={st.target} />
      {st.benefits.length > 0 && (
        <ul className="mt-2 space-y-0.5">
          {st.benefits.map((line, index) => (
            <li key={`${line}-${index}`} className="text-xs text-muted leading-relaxed">
              {line}
            </li>
          ))}
        </ul>
      )}
      <p className="text-xs text-muted/60 mt-2 leading-relaxed italic">{st.rationale}</p>
    </div>
  );
}

interface StatsSectionProps {
  statTargets: ResolvedStatTarget[];
}

export function StatsSection({ statTargets }: StatsSectionProps) {
  return (
    <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
      {statTargets.map((st) => (
        <StatRow key={st.stat} target={st} />
      ))}
    </div>
  );
}
