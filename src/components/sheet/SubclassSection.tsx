"use client";

import type { ResolvedSubclass, ResolvedReference, ResolutionStatus } from "@/lib/build/types";
import { getSubclassMeta, listSubclassVerbs } from "@/data/subclasses";
import { formatAbilityTiming, parseAbilityTiming } from "@/data/rules/abilityTimings";
import { EntityHotspot } from "@/components/ui";
import {
  ELEMENT_CSS_COLOR,
  isDestinyElement,
  type DestinyElement,
} from "@/lib/destiny/identityVisuals";
import { ResolutionBadge } from "./ResolutionBadge";

function resolvedName(ref: ResolvedReference): string {
  return ref.resolved?.name ?? ref.requestedName;
}

function accentFor(element: string | null | undefined): string | undefined {
  if (element && isDestinyElement(element)) {
    return ELEMENT_CSS_COLOR[element as DestinyElement];
  }
  return undefined;
}

function RefHotspot({
  reference,
  kind,
  elementColor,
}: {
  reference: ResolvedReference;
  kind: string;
  elementColor?: string;
}) {
  const name = resolvedName(reference);
  const colorMap: Record<ResolutionStatus, string> = {
    verified: "",
    fuzzy: "opacity-90",
    unresolved: "opacity-70",
  };
  return (
    <span className={`inline-flex items-center gap-1.5 ${colorMap[reference.status]}`}>
      <EntityHotspot
        kind={kind}
        name={name}
        description={undefined}
        icon={reference.resolved?.icon ?? null}
        accentColor={elementColor}
        size={28}
        showLabel="auto"
        meta={[`Status: ${reference.status}`]}
      />
      <ResolutionBadge status={reference.status} />
    </span>
  );
}

function AbilitiesGrid({
  abilities,
  elementColor,
}: {
  abilities: ResolvedSubclass["abilities"];
  elementColor?: string;
}) {
  return (
    <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 mb-4">
      {abilities.map(({ kind, reference }) => (
        <div key={kind} className="panel-notch p-3">
          <div className="text-[11px] tracking-widest uppercase text-muted mb-1">
            {kind}
          </div>
          <div className="flex flex-wrap items-center gap-2">
            <RefHotspot
              reference={reference}
              kind={kind}
              elementColor={elementColor}
            />
          </div>
          <p className="text-[10px] text-muted mt-1">
            {formatAbilityTiming(
              parseAbilityTiming("", resolvedName(reference)),
            ) ?? "—"}
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
  const elementColor = accentFor(meta.element);
  return (
    <div>
      <div className="text-[11px] tracking-widest uppercase text-muted mb-2">
        Keyword verbs · {meta.element}
      </div>
      <div className="flex flex-wrap gap-2">
        {verbs.map((v) => (
          <EntityHotspot
            key={v.name}
            kind="Verb"
            name={v.name}
            description={v.description}
            accentColor={elementColor}
            size={28}
            showLabel="always"
          />
        ))}
      </div>
    </div>
  );
}

export function SubclassSection({ subclass, subclassName }: SubclassSectionProps) {
  const meta = subclassName ? getSubclassMeta(subclassName) : null;
  const elementColor = accentFor(meta?.element);

  return (
    <div className="space-y-4">
      {subclassName && <KeywordVerbsBlock subclassName={subclassName} />}
      <AbilitiesGrid abilities={subclass.abilities} elementColor={elementColor} />

      <div>
        <div className="text-[11px] tracking-widest uppercase text-muted mb-2">
          Aspects
        </div>
        <div className="flex flex-wrap gap-2">
          {subclass.aspects.map((ref, index) => (
            <RefHotspot
              key={`${ref.requestedName}-${index}`}
              reference={ref}
              kind="Aspect"
              elementColor={elementColor}
            />
          ))}
        </div>
      </div>

      <div>
        <div className="text-[11px] tracking-widest uppercase text-muted mb-2">
          Fragments
        </div>
        <div className="flex flex-wrap gap-2">
          {subclass.fragments.map((ref, index) => (
            <RefHotspot
              key={`${ref.requestedName}-${index}`}
              reference={ref}
              kind="Fragment"
              elementColor={elementColor}
            />
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
