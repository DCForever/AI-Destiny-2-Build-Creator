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

function RemediationNote({ original, reason }: { original: string; reason?: string }) {
  return (
    <p className="text-[10px] text-warning mt-1" title={reason}>
      Auto-corrected from {original}
    </p>
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
      {perk.originalRequestedName && (
        <RemediationNote original={perk.originalRequestedName} reason={perk.remediationReason} />
      )}
      {perk.rationale && (
        <p className="text-xs text-muted mt-0.5 leading-relaxed">{perk.rationale}</p>
      )}
    </li>
  );
}

function WeaponCard({ weapon, editable = false, onClick }: {
  weapon: ResolvedWeapon;
  editable?: boolean;
  onClick?: () => void;
}) {
  const name = weapon.reference.resolved?.name ?? weapon.reference.requestedName;
  const icon = weapon.reference.resolved?.icon ?? null;

  const card = (
    <div className="panel-notch p-4 space-y-3">
      <div className="text-[11px] tracking-widest uppercase text-muted flex items-center justify-between">
        <span>{weapon.slot}</span>
        {editable && (
          <span className="text-[10px] text-accent normal-case tracking-normal">Click to swap</span>
        )}
      </div>

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

      {weapon.owned === false && (
        <p className="text-[10px] text-muted border border-line px-2 py-1">Not in your inventory — see Acquisition</p>
      )}
      {weapon.owned === true && weapon.rollTags && weapon.rollTags.length > 0 && (
        <div className="flex flex-wrap gap-1">
          {weapon.rollTags.map((tag) => (
            <span key={tag} className="text-[10px] border border-accent/30 text-accent px-1.5 py-0.5">{tag}</span>
          ))}
        </div>
      )}

      {weapon.originalRequestedName && (
        <RemediationNote original={weapon.originalRequestedName} reason={weapon.remediationReason} />
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

  if (editable && onClick) {
    return (
      <button
        type="button"
        onClick={onClick}
        className="text-left w-full cursor-pointer hover:ring-1 hover:ring-accent/40 transition-shadow focus-visible:outline-accent rounded-sm"
      >
        {card}
      </button>
    );
  }

  return card;
}

interface WeaponsSectionProps {
  weapons: ResolvedWeapon[];
  editable?: boolean;
  onSlotClick?: (slot: ResolvedWeapon["slot"]) => void;
}

export function WeaponsSection({ weapons, editable = false, onSlotClick }: WeaponsSectionProps) {
  return (
    <div className="grid gap-4 sm:grid-cols-3">
      {weapons.map((w) => (
        <WeaponCard
          key={w.reference.requestedName}
          weapon={w}
          editable={editable}
          onClick={onSlotClick ? () => onSlotClick(w.slot) : undefined}
        />
      ))}
    </div>
  );
}
