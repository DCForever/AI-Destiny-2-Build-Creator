import type { ResolvedArtifact } from "@/lib/build/types";
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
  const name = artifact.reference.resolved?.name ?? artifact.reference.requestedName;

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-3">
        <span className="text-sm font-medium text-foreground">{name}</span>
        <ResolutionBadge status={artifact.reference.status} />
      </div>

      {!artifact.allowedInActivity && <DisabledBanner activity={activity} />}

      <div>
        <div className="text-[11px] tracking-widest uppercase text-muted mb-2">Perks</div>
        <div className="flex flex-wrap gap-2">
          {artifact.perks.map((perk) => {
            const isIllegal = perk.legality?.legal === false;
            const perkName = perk.resolved?.name ?? perk.requestedName;
            return (
              <span
                key={perk.requestedName}
                className={`inline-flex items-center gap-1.5 border px-2 py-1 text-xs ${isIllegal ? "border-danger/40 text-danger" : "border-line text-foreground"}`}
              >
                {perkName}
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
