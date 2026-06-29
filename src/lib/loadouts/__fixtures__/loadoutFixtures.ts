import type { SavedLoadout } from "@/lib/db/types";
import type { ResolvedBuildSheet } from "@/lib/build/types";

export const CROWN_HASH = 2001;
export const HALLOWFIRE_HASH = 6101;
export const WITHER_HASH = 9001;

export const manifestStores = {
  exoticArmor: [
    {
      hash: CROWN_HASH,
      name: "Crown of Tempests",
      searchName: "crown of tempests",
      icon: null,
      classType: "Warlock" as const,
      slot: "Helmet" as const,
      intrinsic: { name: "i", description: "d" },
      archetype: null,
      flavorText: "",
    },
    {
      hash: HALLOWFIRE_HASH,
      name: "Hallowfire Heart",
      searchName: "hallowfire heart",
      icon: null,
      classType: "Titan" as const,
      slot: "Chest" as const,
      intrinsic: { name: "i", description: "d" },
      archetype: null,
      flavorText: "",
    },
  ],
  exoticWeapons: [
    {
      hash: WITHER_HASH,
      name: "Witherhoard",
      searchName: "witherhoard",
      icon: null,
      slot: "Kinetic" as const,
      element: "Kinetic" as const,
      ammo: "Primary" as const,
      frame: "Breech Grenade Launcher",
      intrinsic: { name: "i", description: "d" },
      catalyst: null,
      flavorText: "",
    },
  ],
};

function minimalSheet(partial: Partial<ResolvedBuildSheet>): ResolvedBuildSheet {
  return {
    build: {
      name: "T",
      summary: "s",
      subclass: {
        name: "Sunbreaker",
        super: "",
        classAbility: "",
        movement: "",
        melee: "",
        grenade: "",
        aspects: [],
        fragments: [],
        rationale: "",
      },
      statTargets: [],
      exoticArmor: { name: "X", rationale: "", alternatives: [] },
      weapons: [],
      mods: { helmet: [], arms: [], chest: [], legs: [], classItem: [], rationale: "" },
      armor: { archetype: "Grenadier", rationale: "" },
      artifact: null,
      gameplayLoop: "",
      acquisitionNotes: "",
    },
    activity: "Patrol",
    subclass: { aspects: [], fragments: [], abilities: [], fragmentCheck: null, rationale: "" },
    exoticArmor: {
      requestedName: "X",
      resolved: null,
      confidence: 0,
      status: "unresolved",
      alternatives: [],
    },
    weapons: [],
    statTargets: [],
    mods: [],
    artifact: null,
    championCoverage: {
      weaponSources: [],
      subclassSources: [],
      covered: { Barrier: false, Overload: false, Unstoppable: false },
    },
    validation: {
      verified: 0,
      fuzzy: 0,
      unresolved: 0,
      illegalPerks: 0,
      slotMismatches: 0,
      remediations: 0,
    },
    ...partial,
  };
}

export function makeLoadout(
  id: string,
  opts: {
    className?: "Titan" | "Hunter" | "Warlock";
    sheet?: Partial<ResolvedBuildSheet>;
  } = {},
): SavedLoadout {
  const now = new Date().toISOString();
  return {
    id,
    name: `Loadout ${id}`,
    source: "generator",
    manifestVersion: "1",
    buildRequest: opts.className
      ? {
          className: opts.className,
          activity: "Patrol",
          subclass: "Test",
          playstyle: "Test",
        }
      : undefined,
    generatedBuild: minimalSheet({}).build,
    resolvedSheet: minimalSheet(opts.sheet ?? {}),
    createdAt: now,
    updatedAt: now,
  };
}

export const crownWarlockLoadout = makeLoadout("crown", {
  className: "Warlock",
  sheet: {
    exoticArmor: {
      requestedName: "Crown of Tempests",
      resolved: { hash: CROWN_HASH, name: "Crown of Tempests", icon: null },
      confidence: 1,
      status: "verified",
      alternatives: [],
    },
  },
});

export const hallowfireTitanLoadout = makeLoadout("hallow", {
  className: "Titan",
  sheet: {
    exoticArmor: {
      requestedName: "Hallowfire Heart",
      resolved: { hash: HALLOWFIRE_HASH, name: "Hallowfire Heart", icon: null },
      confidence: 1,
      status: "verified",
      alternatives: [],
    },
  },
});

export const witherLoadout = makeLoadout("wither", {
  className: "Hunter",
  sheet: {
    weapons: [
      {
        slot: "Kinetic",
        reference: {
          requestedName: "Witherhoard",
          resolved: { hash: WITHER_HASH, name: "Witherhoard", icon: null },
          confidence: 1,
          status: "verified",
        },
        isExotic: true,
        frame: null,
        element: "Kinetic",
        ammo: "Primary",
        championCounter: null,
        perks: [],
        rationale: "",
      },
    ],
  },
});

export const noExoticLoadout = makeLoadout("plain", {
  className: "Titan",
  sheet: {
    exoticArmor: {
      requestedName: "Hallowfire Heart",
      resolved: null,
      confidence: 0,
      status: "unresolved",
      alternatives: [],
    },
    weapons: [],
  },
});
