import { SUBCLASSES_BY_CLASS, type GuardianClass } from "@/data/subclasses";

export function subclassesForClass(className: GuardianClass): readonly string[] {
  return SUBCLASSES_BY_CLASS[className];
}

export function defaultSubclassForClass(className: GuardianClass): string {
  return SUBCLASSES_BY_CLASS[className][0] ?? "";
}

export function isValidSubclassForClass(className: GuardianClass, subclassName: string): boolean {
  return (SUBCLASSES_BY_CLASS[className] as readonly string[]).includes(subclassName);
}

/** When class changes, keep subclass if still valid; otherwise reset to default. */
export function subclassAfterClassChange(
  className: GuardianClass,
  currentSubclass: string,
): string {
  if (isValidSubclassForClass(className, currentSubclass)) return currentSubclass;
  return defaultSubclassForClass(className);
}

/** Clear pinned super when subclass changes (incompatible until re-picked). */
export function pinnedSuperAfterSubclassChange(
  previousSubclass: string,
  nextSubclass: string,
  pinnedSuper: string | null,
): string | null {
  if (previousSubclass === nextSubclass) return pinnedSuper;
  return null;
}
