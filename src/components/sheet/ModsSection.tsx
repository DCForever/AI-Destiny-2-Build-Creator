import type { ResolvedPerkPick } from "@/lib/build/types";
import type { GeneratedBuild } from "@/lib/llm/buildSchema";
import { ResolutionBadge, IllegalBadge } from "./ResolutionBadge";

function ModChip({ pick }: { pick: ResolvedPerkPick }) {
  const isIllegal = pick.legality?.legal === false;
  const name = pick.resolved?.name ?? pick.requestedName;
  return (
    <div
      className={`panel-notch px-2 py-1.5 text-xs ${isIllegal ? "border-danger/40" : ""}`}
    >
      <div className="flex flex-wrap items-center gap-1">
        <span className={isIllegal ? "text-danger" : "text-foreground"}>{name}</span>
        <ResolutionBadge status={pick.status} />
        {isIllegal && <IllegalBadge reason={pick.legality?.reason} />}
      </div>
    </div>
  );
}

interface SlotColumnProps {
  slot: string;
  picks: ResolvedPerkPick[];
}

function SlotColumn({ slot, picks }: SlotColumnProps) {
  return (
    <div>
      <div className="text-[11px] tracking-widest uppercase text-muted mb-2">{slot}</div>
      <div className="space-y-1.5">
        {picks.length === 0 ? (
          <p className="text-xs text-muted/50 italic">—</p>
        ) : (
          picks.map((p) => <ModChip key={p.requestedName} pick={p} />)
        )}
      </div>
    </div>
  );
}

interface ModsSectionProps {
  mods: { slot: string; picks: ResolvedPerkPick[] }[];
  armor: GeneratedBuild["armor"];
}

export function ModsSection({ mods, armor }: ModsSectionProps) {
  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-baseline gap-3">
        <span className="text-sm font-medium text-foreground">{armor.archetype}</span>
        {armor.setBonus && (
          <span className="text-xs text-muted">Set bonus: {armor.setBonus}</span>
        )}
      </div>

      <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4">
        {mods.map(({ slot, picks }) => (
          <SlotColumn key={slot} slot={slot} picks={picks} />
        ))}
      </div>

      <p className="text-xs text-muted leading-relaxed">{armor.rationale}</p>
    </div>
  );
}
