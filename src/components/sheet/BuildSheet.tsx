import type { ResolvedBuildSheet, ResolvedReference } from "@/lib/build/types";
import { ChampionCoverageBar } from "./ChampionCoverageBar";
import { SubclassSection } from "./SubclassSection";
import { WeaponsSection } from "./WeaponsSection";
import { StatsSection } from "./StatsSection";
import { ModsSection } from "./ModsSection";
import { ArtifactSection } from "./ArtifactSection";
import { ResolutionBadge } from "./ResolutionBadge";
import { ItemIcon } from "./ItemIcon";

function SectionHeader({ title }: { title: string }) {
  return (
    <div className="mb-4">
      <h3 className="text-[11px] tracking-widest uppercase text-muted mb-1">{title}</h3>
      <div className="keyline" />
    </div>
  );
}

function SectionWrapper({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <section>
      <SectionHeader title={title} />
      {children}
    </section>
  );
}

function ExoticArmorCard({ exoticArmor, rationale }: {
  exoticArmor: ResolvedBuildSheet["exoticArmor"];
  rationale: string;
}) {
  const name = exoticArmor.resolved?.name ?? exoticArmor.requestedName;
  return (
    <div className="panel-notch p-4 space-y-3">
      <div className="flex items-center gap-3">
        <ItemIcon icon={exoticArmor.resolved?.icon ?? null} name={name} size={40} />
        <div>
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-sm font-medium text-foreground">{name}</span>
            <ResolutionBadge status={exoticArmor.status} />
          </div>
        </div>
      </div>
      {exoticArmor.alternatives.length > 0 && (
        <AlternativesList alternatives={exoticArmor.alternatives} />
      )}
      <p className="text-xs text-muted leading-relaxed">{rationale}</p>
    </div>
  );
}

function AlternativesList({ alternatives }: { alternatives: ResolvedReference[] }) {
  return (
    <div>
      <div className="text-[11px] tracking-widest uppercase text-muted mb-1">Alternatives</div>
      <div className="flex flex-wrap gap-2">
        {alternatives.map((alt) => (
          <span key={alt.requestedName} className="inline-flex items-center gap-1.5 border border-line px-2 py-1 text-xs text-foreground">
            {alt.resolved?.name ?? alt.requestedName}
            <ResolutionBadge status={alt.status} />
          </span>
        ))}
      </div>
    </div>
  );
}

function ValidationStrip({ v }: { v: ResolvedBuildSheet["validation"] }) {
  return (
    <div className="flex flex-wrap gap-4 text-xs text-muted">
      <span className="text-success">{v.verified} verified</span>
      {v.fuzzy > 0 && <span className="text-warning">{v.fuzzy} fuzzy</span>}
      {v.unresolved > 0 && <span className="text-danger">{v.unresolved} unresolved</span>}
      {v.illegalPerks > 0 && <span className="text-danger">{v.illegalPerks} illegal perks</span>}
    </div>
  );
}

interface BuildSheetProps {
  sheet: ResolvedBuildSheet;
}

export function BuildSheet({ sheet }: BuildSheetProps) {
  return (
    <div className="space-y-8">
      <div>
        <h2 className="text-2xl text-accent mb-2">{sheet.build.name}</h2>
        <p className="text-sm text-muted leading-relaxed mb-3">{sheet.build.summary}</p>
        <ValidationStrip v={sheet.validation} />
      </div>

      <SectionWrapper title="Champion Coverage">
        <ChampionCoverageBar coverage={sheet.championCoverage} />
      </SectionWrapper>

      <SectionWrapper title="Subclass">
        <SubclassSection subclass={sheet.subclass} />
      </SectionWrapper>

      <SectionWrapper title="Exotic Armor">
        <ExoticArmorCard exoticArmor={sheet.exoticArmor} rationale={sheet.build.exoticArmor.rationale} />
      </SectionWrapper>

      <SectionWrapper title="Weapons">
        <WeaponsSection weapons={sheet.weapons} />
      </SectionWrapper>

      <SectionWrapper title="Stats">
        <StatsSection statTargets={sheet.statTargets} />
      </SectionWrapper>

      <SectionWrapper title="Armor & Mods">
        <ModsSection mods={sheet.mods} armor={sheet.build.armor} />
      </SectionWrapper>

      {sheet.artifact && (
        <SectionWrapper title="Artifact">
          <ArtifactSection artifact={sheet.artifact} activity={sheet.activity} />
        </SectionWrapper>
      )}

      <SectionWrapper title="Gameplay Loop">
        <p className="text-sm text-foreground leading-relaxed">{sheet.build.gameplayLoop}</p>
      </SectionWrapper>

      <SectionWrapper title="Acquisition">
        <p className="text-sm text-foreground leading-relaxed">{sheet.build.acquisitionNotes}</p>
      </SectionWrapper>
    </div>
  );
}
