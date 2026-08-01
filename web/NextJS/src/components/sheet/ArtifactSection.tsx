"use client";

import type { ResolvedArtifact } from "@/lib/build/types";
import { EntityHotspot } from "@/components/ui";
import { ResolutionBadge, IllegalBadge } from "./ResolutionBadge";

interface DisabledBannerProps {
  activity: string;
}

function DisabledBanner({ activity }: DisabledBannerProps) {
  return (
    <div className="border border-warning/30 bg-warning/10 px-3 py-2 text-xs text-warning">
      Artifact perks are disabled in this activity ({activity}) — Trials/Competitive.
    </div>
  );
}

interface ArtifactSectionProps {
  artifact: ResolvedArtifact;
  activity: string;
}

export function ArtifactSection({ artifact, activity }: ArtifactSectionProps) {
  const name =
    artifact.reference.resolved?.name ?? artifact.reference.requestedName;
  const icon = artifact.reference.resolved?.icon ?? null;

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-3">
        <EntityHotspot
          kind="Artifact"
          name={name}
          icon={icon}
          size={32}
          showLabel="auto"
          meta={[`Status: ${artifact.reference.status}`]}
        />
        <ResolutionBadge status={artifact.reference.status} />
      </div>

      {!artifact.allowedInActivity && <DisabledBanner activity={activity} />}

      <div>
        <div className="text-[11px] tracking-widest uppercase text-muted mb-2">
          Perks
        </div>
        <div className="flex flex-wrap gap-2">
          {artifact.perks.map((perk, index) => {
            const isIllegal = perk.legality?.legal === false;
            const perkName = perk.resolved?.name ?? perk.requestedName;
            return (
              <span
                key={`${perk.requestedName}-${index}`}
                className={`inline-flex items-center gap-1.5 ${isIllegal ? "opacity-90" : ""}`}
              >
                <EntityHotspot
                  kind="Artifact perk"
                  name={perkName}
                  icon={perk.resolved?.icon ?? null}
                  size={28}
                  showLabel="auto"
                  meta={
                    isIllegal
                      ? [perk.legality?.reason ?? "Illegal in activity"]
                      : undefined
                  }
                />
                <ResolutionBadge status={perk.status} />
                {isIllegal && <IllegalBadge reason={perk.legality?.reason} />}
              </span>
            );
          })}
        </div>
      </div>

      <p className="text-sm text-muted leading-relaxed">{artifact.rationale}</p>
    </div>
  );
}
