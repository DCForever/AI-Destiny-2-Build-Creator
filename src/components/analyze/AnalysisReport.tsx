import type { LoadoutAnalysis } from "@/lib/llm/analyzeSchema";

function SectionHeader({ title }: { title: string }) {
  return (
    <div className="mb-4">
      <h3 className="text-[11px] tracking-widest uppercase text-muted mb-1">{title}</h3>
      <div className="keyline" />
    </div>
  );
}

function BulletList({
  items,
  dotClass,
}: {
  items: string[];
  dotClass: string;
}) {
  return (
    <ul className="space-y-2">
      {items.map((item) => (
        <li key={item} className="flex items-start gap-2.5 text-sm text-foreground leading-relaxed">
          <span className={`size-2 shrink-0 rotate-45 mt-1.5 ${dotClass}`} aria-hidden="true" />
          <span>{item}</span>
        </li>
      ))}
    </ul>
  );
}

function SwapRow({ index, swap }: { index: number; swap: LoadoutAnalysis["swaps"][number] }) {
  const ordinal = String(index + 1).padStart(2, "0");
  return (
    <div className="border-b border-line/50 last:border-0 pb-4 last:pb-0">
      <div className="flex items-baseline gap-3">
        <span className="font-mono text-xs text-accent shrink-0">{ordinal}</span>
        <div className="flex flex-wrap items-baseline gap-2 min-w-0">
          <span className="text-sm text-muted line-through">{swap.replace}</span>
          <span className="text-accent" aria-hidden="true">→</span>
          <span className="text-sm text-foreground font-medium">{swap.with}</span>
        </div>
      </div>
      <p className="text-xs text-muted leading-relaxed mt-1.5 ml-8">{swap.rationale}</p>
    </div>
  );
}

interface AnalysisReportProps {
  analysis: LoadoutAnalysis;
}

export function AnalysisReport({ analysis }: AnalysisReportProps) {
  const hasStrengths = analysis.strengths.length > 0;
  const hasGaps = analysis.gaps.length > 0;
  const hasSwaps = analysis.swaps.length > 0;
  const showGrid = hasStrengths || hasGaps;

  return (
    <div className="panel-notch p-6 space-y-8">
      <section>
        <SectionHeader title="Assessment" />
        <p className="text-sm text-foreground leading-relaxed">{analysis.assessment}</p>
      </section>

      {showGrid && (
        <div className={`grid gap-8 ${hasStrengths && hasGaps ? "sm:grid-cols-2" : ""}`}>
          {hasStrengths && (
            <section>
              <SectionHeader title="Strengths" />
              <BulletList items={analysis.strengths} dotClass="bg-success" />
            </section>
          )}
          {hasGaps && (
            <section>
              <SectionHeader title="Gaps" />
              <BulletList items={analysis.gaps} dotClass="bg-danger" />
            </section>
          )}
        </div>
      )}

      {hasSwaps && (
        <section>
          <SectionHeader title="Priority Swaps" />
          <div className="space-y-4">
            {analysis.swaps.map((swap, i) => (
              <SwapRow key={`${swap.replace}-${swap.with}`} index={i} swap={swap} />
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
