"use client";

import { ARMOR_STAT_NAMES } from "@/data/rules/statBenefits";
import {
  activeCandidate,
  visibleCandidates,
  type CandidateSession,
} from "@/lib/inventory/instances/candidateSession";
import type { OwnedInstanceDetail } from "@/lib/inventory/instances/types";

export interface InstanceCarouselProps {
  session: CandidateSession;
  onPrev: () => void;
  onNext: () => void;
  onSelect: (instanceId: string) => void;
  onRemove?: (instanceId: string) => void;
  onReset?: () => void;
  onOpenPerks?: (instance: OwnedInstanceDetail) => void;
  emptyHint?: string;
}

function shortId(instanceId: string): string {
  return instanceId.length > 8 ? `…${instanceId.slice(-6)}` : instanceId;
}

function locationLabel(instance: OwnedInstanceDetail): string {
  if (instance.location === "vault") return "Vault";
  const character = instance.characterDisplayName ?? instance.className ?? "Character";
  return instance.location === "equipped" ? `${character} (equipped)` : character;
}

function ArmorDetail({ instance }: { instance: OwnedInstanceDetail }): React.JSX.Element {
  const { tier, statValues, totalStats, statsIncomplete, setBonus } = instance;
  return (
    <div className="mt-2 space-y-2 text-xs">
      {tier && (
        <p>
          <span className="text-zinc-500">Tier:</span> {tier.label}
          {tier.approximate && <span className="text-amber-400"> (estimated)</span>}
        </p>
      )}
      <div>
        <span className="text-zinc-500">
          Stats{typeof totalStats === "number" ? ` · total ${totalStats}` : ""}
          {statsIncomplete ? " · incomplete" : ""}
        </span>
        <div className="mt-1 grid grid-cols-3 gap-1">
          {ARMOR_STAT_NAMES.map((name) => (
            <span key={name} className="rounded bg-zinc-800 px-1 py-0.5">
              {name} {statValues?.[name] ?? "—"}
            </span>
          ))}
        </div>
      </div>
      <div>
        <span className="text-zinc-500">Set bonus:</span>{" "}
        {setBonus ? (
          <span>
            {setBonus.name}
            <ul className="mt-1 space-y-0.5">
              {setBonus.tiers.map((bonusTier) => (
                <li key={bonusTier.requiredCount}>
                  <span className="text-zinc-400">{bonusTier.requiredCount}pc — {bonusTier.name}:</span>{" "}
                  {bonusTier.description}
                </li>
              ))}
            </ul>
          </span>
        ) : (
          "no set bonus"
        )}
      </div>
    </div>
  );
}

function WeaponPerks({ instance }: { instance: OwnedInstanceDetail }): React.JSX.Element {
  return (
    <div className="mt-2 text-xs">
      <span className="text-zinc-500">Perks (socket order):</span>
      {instance.plugs.length === 0 ? (
        <p className="text-zinc-500">none</p>
      ) : (
        <ul className="mt-1 flex flex-wrap gap-1">
          {instance.plugs.map((plug, index) => (
            <li key={`${plug.hash}-${index}`} className="rounded bg-zinc-800 px-1 py-0.5">
              {plug.displayName}
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

export function InstanceCarousel({
  session,
  onPrev,
  onNext,
  onSelect,
  onRemove,
  onReset,
  emptyHint,
}: InstanceCarouselProps): React.JSX.Element {
  const visible = visibleCandidates(session);
  const active = activeCandidate(session);

  if (!active) {
    return (
      <div className="rounded border border-zinc-800 p-4 text-sm text-zinc-400">
        <p>{emptyHint ?? "No candidate copies to show."}</p>
        {onReset && (
          <button
            type="button"
            className="mt-2 rounded bg-zinc-700 px-3 py-1 text-xs"
            onClick={onReset}
          >
            Reset candidates
          </button>
        )}
      </div>
    );
  }

  const activeVisibleIndex = visible.findIndex((c) => c.instanceId === active.instanceId);
  const isSelected = session.selectedInstanceId === active.instanceId;
  const hasRemoved = session.removedInstanceIds.size > 0;

  return (
    <div className="space-y-2 rounded border border-zinc-800 p-3">
      <div className="flex items-center justify-between text-xs text-zinc-400">
        <span>
          Copy {activeVisibleIndex + 1} of {visible.length}
          {onReset && hasRemoved && (
            <button
              type="button"
              className="ml-2 rounded bg-zinc-700 px-2 py-0.5 text-[11px]"
              onClick={onReset}
            >
              Reset ({session.removedInstanceIds.size} removed)
            </button>
          )}
        </span>
        <div className="flex gap-1">
          <button
            type="button"
            className="rounded bg-zinc-700 px-2 py-0.5 disabled:opacity-40"
            onClick={onPrev}
            disabled={activeVisibleIndex <= 0}
            aria-label="Previous copy"
          >
            ‹
          </button>
          <button
            type="button"
            className="rounded bg-zinc-700 px-2 py-0.5 disabled:opacity-40"
            onClick={onNext}
            disabled={activeVisibleIndex >= visible.length - 1}
            aria-label="Next copy"
          >
            ›
          </button>
        </div>
      </div>

      <div
        className={`rounded border p-3 text-sm ${
          isSelected ? "border-emerald-600 bg-emerald-950/30" : "border-zinc-700 bg-zinc-900"
        }`}
      >
        <div className="flex items-center justify-between">
          <span className="font-medium">Power {active.power}</span>
          <span className="text-xs text-zinc-500">{shortId(active.instanceId)}</span>
        </div>
        <p className="text-xs text-zinc-400">{locationLabel(active)}</p>
        <div className="mt-1 flex gap-2 text-[11px] text-zinc-500">
          {active.isMasterwork && <span>Masterwork</span>}
          {active.isCrafted && <span>Crafted</span>}
        </div>

        {active.kind === "armor" ? (
          <ArmorDetail instance={active} />
        ) : (
          <WeaponPerks instance={active} />
        )}

        <div className="mt-3 flex flex-wrap gap-2">
          <button
            type="button"
            className={`rounded px-3 py-1 text-xs ${
              isSelected ? "bg-emerald-700" : "bg-emerald-800 hover:bg-emerald-700"
            }`}
            onClick={() => onSelect(active.instanceId)}
          >
            {isSelected ? "Selected" : "Select this copy"}
          </button>
          {onRemove && (
            <button
              type="button"
              className="rounded bg-red-900 px-3 py-1 text-xs hover:bg-red-800"
              onClick={() => onRemove(active.instanceId)}
            >
              Remove
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
