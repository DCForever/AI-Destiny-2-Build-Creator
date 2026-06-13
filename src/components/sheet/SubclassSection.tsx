import type { ResolvedSubclass, ResolvedReference, ResolutionStatus } from "@/lib/build/types";
import { getSubclassMeta, listSubclassVerbs } from "@/data/subclasses";
import { formatAbilityTiming, parseAbilityTiming } from "@/data/rules/abilityTimings";
import { ResolutionBadge } from "./ResolutionBadge";

function resolvedName(ref: ResolvedReference): string {
  return ref.resolved?.name ?? ref.requestedName;
}

function RefChip({ reference }: { reference: ResolvedReference }) {
  const colorMap: Record<ResolutionStatus, string> = {
    verified: "border-success/30 text-foreground",
    fuzzy: "border-warning/30 text-warning",
    unresolved: "border-danger/30 text-danger",
  };
  return (
    <span
      className={`inline-flex items-center gap-1.5 border px-2 py-1 text-xs ${colorMap[reference.status]}`}
    >
      {resolvedName(reference)}
      <ResolutionBadge status={reference.status} />
    </span>
  );
}

function AbilitiesGrid({ abilities }: { abilities: ResolvedSubclass["abilities"] }) {
  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 mb-4">
      {abilities.map(({ kind, reference }) => (
        <div key={kind} className="panel-notch p-3">
          <div className="text-[11px] tracking-widest uppercase text-muted mb-1">{kind}</div>
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-sm text-foreground">{resolvedName(reference)}</span>
            <ResolutionBadge status={reference.status} />
          </div>
          <p className="text-[10px] text-muted mt-1">
            {formatAbilityTiming(parseAbilityTiming("", resolvedName(reference))) ?? "—"}
          </p>
        </div>
      ))}
    </div>
  );
}

interface FragmentCheckLineProps {
  check: NonNullable<ResolvedSubclass["fragmentCheck"]>;
}

function FragmentCheckLine({ check }: FragmentCheckLineProps) {
  const isIllegal = !check.legal;
  return (
    <p className={`text-xs mt-2 ${isIllegal ? "text-danger" : "text-muted"}`}>
      Fragments: {check.requested}/{check.capacity}
      {isIllegal && " — too many fragments equipped"}
    </p>
  );
}

interface SubclassSectionProps {
  subclass: ResolvedSubclass;
  subclassName?: string;
}

function KeywordVerbsBlock({ subclassName }: { subclassName: string }) {
  const meta = getSubclassMeta(subclassName);
  if (!meta) return null;
  const verbs = listSubclassVerbs(subclassName);
  return (
    <div>
      <div className="text-[11px] tracking-widest uppercase text-muted mb-2">
        Keyword verbs · {meta.element}
      </div>
      <div className="flex flex-wrap gap-2">
        {verbs.map((v) => (
          <span key={v.name} className="border border-line px-2 py-1 text-xs text-foreground" title={v.description}>
            {v.name}
          </span>
        ))}
      </div>
    </div>
  );
}

export function SubclassSection({ subclass, subclassName }: SubclassSectionProps) {
  return (
    <div className="space-y-4">
      {subclassName && <KeywordVerbsBlock subclassName={subclassName} />}
      <AbilitiesGrid abilities={subclass.abilities} />

      <div>
        <div className="text-[11px] tracking-widest uppercase text-muted mb-2">Aspects</div>
        <div className="flex flex-wrap gap-2">
          {subclass.aspects.map((ref) => (
            <RefChip key={ref.requestedName} reference={ref} />
          ))}
        </div>
      </div>

      <div>
        <div className="text-[11px] tracking-widest uppercase text-muted mb-2">Fragments</div>
        <div className="flex flex-wrap gap-2">
          {subclass.fragments.map((ref) => (
            <RefChip key={ref.requestedName} reference={ref} />
          ))}
        </div>
        {subclass.fragmentCheck && (
          <FragmentCheckLine check={subclass.fragmentCheck} />
        )}
      </div>

      <p className="text-sm text-muted leading-relaxed">{subclass.rationale}</p>
    </div>
  );
}
