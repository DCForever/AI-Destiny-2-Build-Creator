import type { ResolvedWeapon, ResolvedPerkPick } from "@/lib/build/types";
import type { ChampionType } from "@/data/rules/championCounters";
import { ResolutionBadge, IllegalBadge } from "./ResolutionBadge";
import { ItemIcon } from "./ItemIcon";

function ChampionChip({ type }: { type: ChampionType }) {
  const colorMap: Record<ChampionType, string> = {
    Barrier: "border-arc/40 text-arc",
    Overload: "border-warning/40 text-warning",
    Unstoppable: "border-solar/40 text-solar",
  };
  return (
    <span className={`inline-block border px-2 py-0.5 text-[10px] tracking-widest uppercase ${colorMap[type]}`}>
      {type}
    </span>
  );
}

const ELEMENT_DOT_CLASSES: Record<string, string> = {
  Kinetic: "bg-foreground/70",
  Arc: "bg-arc",
  Solar: "bg-solar",
  Void: "bg-void",
  Stasis: "bg-stasis",
  Strand: "bg-strand",
  Prismatic: "bg-accent",
};

function ElementLine({ weapon }: { weapon: ResolvedWeapon }) {
  const parts = [weapon.element, weapon.ammo, weapon.frame].filter(Boolean);
  if (parts.length === 0) {
    return <div className="text-xs text-muted mt-0.5">{weapon.slot}</div>;
  }
  const dotClass = weapon.element ? ELEMENT_DOT_CLASSES[weapon.element] : null;
  return (
    <div className="flex items-center gap-1.5 text-xs text-muted mt-0.5">
      {dotClass && <span className={`size-2 shrink-0 rotate-45 ${dotClass}`} />}
      <span className="truncate">{parts.join(" · ")}</span>
    </div>
  );
}

function PerkRow({ perk }: { perk: ResolvedPerkPick }) {
  const isIllegal = perk.legality?.legal === false;
  const name = perk.resolved?.name ?? perk.requestedName;

  return (
    <li className="py-1.5 border-b border-line/50 last:border-0">
      <div className="flex flex-wrap items-center gap-2">
        <span className={`text-sm ${isIllegal ? "text-danger" : "text-foreground"}`}>{name}</span>
        <ResolutionBadge status={perk.status} />
        {isIllegal && <IllegalBadge reason={perk.legality?.reason} />}
      </div>
      {perk.rationale && (
        <p className="text-xs text-muted mt-0.5 leading-relaxed">{perk.rationale}</p>
      )}
    </li>
  );
}

function WeaponCard({ weapon }: { weapon: ResolvedWeapon }) {
  const name = weapon.reference.resolved?.name ?? weapon.reference.requestedName;
  const icon = weapon.reference.resolved?.icon ?? null;

  return (
    <div className="panel-notch p-4 space-y-3">
      <div className="text-[11px] tracking-widest uppercase text-muted">{weapon.slot}</div>

      <div className="flex items-center gap-3">
        <ItemIcon icon={icon} name={name} size={40} />
        <div className="flex-1 min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <span className="text-sm font-medium text-foreground truncate">{name}</span>
            <ResolutionBadge status={weapon.reference.status} />
            {weapon.isExotic && (
              <span className="badge badge-fuzzy">Exotic</span>
            )}
          </div>
          <ElementLine weapon={weapon} />
        </div>
      </div>

      {weapon.championCounter && (
        <ChampionChip type={weapon.championCounter} />
      )}

      {weapon.perks.length > 0 && (
        <div>
          <div className="text-[11px] tracking-widest uppercase text-muted mb-1">Perks</div>
          <ul className="divide-y-0">
            {weapon.perks.map((p) => (
              <PerkRow key={p.requestedName} perk={p} />
            ))}
          </ul>
        </div>
      )}

      <p className="text-xs text-muted leading-relaxed">{weapon.rationale}</p>
    </div>
  );
}

interface WeaponsSectionProps {
  weapons: ResolvedWeapon[];
}

export function WeaponsSection({ weapons }: WeaponsSectionProps) {
  return (
    <div className="grid gap-4 sm:grid-cols-3">
      {weapons.map((w) => (
        <WeaponCard key={w.reference.requestedName} weapon={w} />
      ))}
    </div>
  );
}
