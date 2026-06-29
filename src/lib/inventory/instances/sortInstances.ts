import type { OwnedInstanceDetail } from "./types";

export function sortInstancesByPower(instances: OwnedInstanceDetail[]): OwnedInstanceDetail[] {
  return [...instances].sort((a, b) => b.power - a.power);
}
