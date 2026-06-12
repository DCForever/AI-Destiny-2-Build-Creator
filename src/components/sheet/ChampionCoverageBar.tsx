import type { ChampionCoverage } from "@/lib/build/types";
import type { ChampionType } from "@/data/rules/championCounters";

const CHAMPION_TYPES: readonly ChampionType[] = ["Barrier", "Overload", "Unstoppable"];

interface ChampionCellProps {
  type: ChampionType;
  covered: boolean;
  sources: string[];
}

function ChampionCell({ type, covered, sources }: ChampionCellProps) {
  const displayed = sources.slice(0, 2);
  const extra = sources.length - 2;

  const baseCls = covered
    ? "border-success/30 bg-success/10"
    : "border-danger/30 bg-danger/10";

  return (
    <div className={`flex-1 border p-3 ${baseCls}`}>
      <div className="text-[11px] tracking-widest uppercase text-muted mb-1">{type}</div>
      {covered ? (
        <div className="text-success text-xs leading-relaxed">
          {displayed.join(", ")}
          {extra > 0 && <span className="text-muted"> +{extra}</span>}
        </div>
      ) : (
        <div className="text-danger text-xs font-semibold tracking-wide">NO COUNTER</div>
      )}
    </div>
  );
}

interface ChampionCoverageBarProps {
  coverage: ChampionCoverage;
}

export function ChampionCoverageBar({ coverage }: ChampionCoverageBarProps) {
  return (
    <div className="flex gap-2">
      {CHAMPION_TYPES.map((type) => {
        const sources = coverage.sources
          .filter((s) => s.counter === type)
          .map((s) => s.source);
        return (
          <ChampionCell
            key={type}
            type={type}
            covered={coverage.covered[type]}
            sources={sources}
          />
        );
      })}
    </div>
  );
}
