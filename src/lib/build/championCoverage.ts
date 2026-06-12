/**
 * Computes champion type coverage from weapon frames and subclass verb effects.
 */

import type { ResolvedWeapon, ChampionCoverage, ChampionCoverageSource } from "./types";
import { SUBCLASS_VERB_COUNTERS } from "@/data/rules/championCounters";
import type { ChampionType } from "@/data/rules/championCounters";

const CHAMPION_TYPES: readonly ChampionType[] = ["Barrier", "Overload", "Unstoppable"];

function collectWeaponSources(weapons: ResolvedWeapon[]): ChampionCoverageSource[] {
  return weapons
    .filter(w => w.championCounter !== null)
    .map(w => ({
      counter: w.championCounter as ChampionType,
      source: `${w.reference.resolved?.name ?? w.reference.requestedName} (${w.frame ?? "unknown frame"})`,
    }));
}

function firstVerbMatch(
  verb: string,
  items: Array<{ name: string; description: string }>,
): { name: string; description: string } | undefined {
  const pattern = new RegExp(verb, "i");
  return items.find(item => pattern.test(item.description));
}

function collectVerbSources(
  verbCheckItems: Array<{ name: string; description: string }>,
): ChampionCoverageSource[] {
  const sources: ChampionCoverageSource[] = [];
  const seenVerbs = new Set<string>();
  for (const [verb, counter] of Object.entries(SUBCLASS_VERB_COUNTERS)) {
    if (seenVerbs.has(verb)) continue;
    const match = firstVerbMatch(verb, verbCheckItems);
    if (match) {
      sources.push({ counter, source: `subclass verb: ${verb} (${match.name})` });
      seenVerbs.add(verb);
    }
  }
  return sources;
}

function buildCovered(sources: ChampionCoverageSource[]): Record<ChampionType, boolean> {
  const covered = Object.fromEntries(
    CHAMPION_TYPES.map(t => [t, false])
  ) as Record<ChampionType, boolean>;
  for (const { counter } of sources) {
    covered[counter] = true;
  }
  return covered;
}

export function computeChampionCoverage(
  weapons: ResolvedWeapon[],
  verbCheckItems: Array<{ name: string; description: string }>,
): ChampionCoverage {
  const sources = [...collectWeaponSources(weapons), ...collectVerbSources(verbCheckItems)];
  return { sources, covered: buildCovered(sources) };
}
