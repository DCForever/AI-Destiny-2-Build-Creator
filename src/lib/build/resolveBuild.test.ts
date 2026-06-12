import { describe, it, expect } from "vitest";
import { generatedBuildSchema, type GeneratedBuild } from "@/lib/llm/buildSchema";
import { normalizeName } from "@/lib/manifest/normalize";
import type { ItemResolver, PerkValidator, EntityCache, PerkLegality, ResolveResult } from "@/lib/manifest/types/services";
import type { StoreName, EntityStores } from "@/lib/manifest/types/stores";
import type {
  AspectRecord, FragmentRecord, AbilityRecord,
  WeaponRecord, ExoticWeaponRecord, ExoticArmorRecord,
  PerkRecord, ModRecord, ArtifactRecord,
} from "@/lib/manifest/types/records";
import { resolveBuild, type ResolveBuildDeps } from "./resolveBuild";

// --- Fixture helpers ---

const B = (hash: number, name: string) =>
  ({ hash, name, searchName: normalizeName(name), icon: null });

const ASPECTS: AspectRecord[] = [
  { ...B(1001, "Lightning Surge"), description: "Deals arc damage causing jolt to nearby enemies.", classType: "Hunter", element: "Arc", fragmentCapacity: 2 },
  { ...B(1002, "Arc Soul"), description: "Summons an arc soul ally.", classType: "Warlock", element: "Arc", fragmentCapacity: 1 },
];
const FRAGMENTS: FragmentRecord[] = [
  { ...B(2001, "Spark of Shock"), description: "Your arc abilities have a chance to jolt targets.", element: "Arc", statModifiers: {} },
  { ...B(2002, "Spark of Resistance"), description: "While surrounded, you are more resistant to damage.", element: "Arc", statModifiers: {} },
];
const ABILITIES: AbilityRecord[] = [
  { ...B(3001, "Stormtrance"), description: "Call lightning down on foes.", kind: "super", classType: "Warlock", element: "Arc" },
  { ...B(3002, "Healing Rift"), description: "Cast a rift that heals you and nearby allies.", kind: "classAbility", classType: "Warlock", element: "Arc" },
  { ...B(3003, "Burst Glide"), description: "Jump and then activate again for a second burst.", kind: "movement", classType: "Warlock", element: "Arc" },
  { ...B(3004, "Ball Lightning"), description: "Throw a ball of lightning that jolts enemies.", kind: "melee", classType: "Warlock", element: "Arc" },
  { ...B(3005, "Shackle Grenade"), description: "Throw a grenade that suspends nearby enemies on detonation.", kind: "grenade", classType: null, element: "Strand" },
];
const EXOTIC_ARMOR: ExoticArmorRecord[] = [
  { ...B(6001, "Ophidian Aspect"), slot: "Gauntlets", classType: "Warlock", archetype: null, intrinsic: { name: "Fluid Aura", description: "Enhanced handling." }, flavorText: "..." },
  { ...B(6002, "Karnstein Armlets"), slot: "Gauntlets", classType: "Warlock", archetype: null, intrinsic: { name: "Vampires Caress", description: "Melee kills heal." }, flavorText: "..." },
];
const WEAPONS: WeaponRecord[] = [
  { ...B(4001, "Fatebringer"), slot: "Kinetic", element: "Void", ammo: "Primary", frame: "Adaptive Frame", itemTypeName: "Hand Cannon", originTraitHashes: [], perkColumns: [{ column: 0, curated: [5001], randomized: [5002] }] },
];
const WEAPON_PERKS: PerkRecord[] = [
  { ...B(5001, "Firefly"), description: "Precision kills cause the target to explode." },
  { ...B(5002, "Opening Shot"), description: "Improved accuracy on the opening shot of attack." },
];
const EXOTIC_WEAPONS: ExoticWeaponRecord[] = [
  { ...B(7001, "Conditional Finality"), slot: "Energy", element: "Stasis", ammo: "Special", frame: "Precision Frame", intrinsic: { name: "Paracausal Pellets", description: "..." }, catalyst: null, flavorText: "..." },
  { ...B(7002, "Gjallarhorn"), slot: "Power", element: "Solar", ammo: "Heavy", frame: "Aggressive Frame", intrinsic: { name: "Wolfpack Rounds", description: "..." }, catalyst: null, flavorText: "..." },
];
const MODS: ModRecord[] = [
  { ...B(8001, "Ashes to Assets"), description: "Grenade kills grant Super energy.", slotCategory: "helmet", energyCost: 1 },
  { ...B(8002, "Heavy Handed"), description: "Melee kills grant Super energy.", slotCategory: "arms", energyCost: 1 },
];
const ARTIFACTS: ArtifactRecord[] = [{
  ...B(9001, "The Current"), description: "Season artifact.",
  perks: [
    { ...B(9101, "Anti-Barrier Scout Rifle"), description: "Scout rifles pierce Barrier Champion shields.", column: 0, row: 0 },
  ],
}];

type FixtureStores = Pick<EntityStores, "aspects"|"fragments"|"abilities"|"exotic-armor"|"weapons"|"exotic-weapons"|"weapon-perks"|"mods"|"artifacts">;
const DEFAULT_STORES: FixtureStores = {
  aspects: ASPECTS, fragments: FRAGMENTS, abilities: ABILITIES,
  "exotic-armor": EXOTIC_ARMOR, weapons: WEAPONS, "exotic-weapons": EXOTIC_WEAPONS,
  "weapon-perks": WEAPON_PERKS, mods: MODS, artifacts: ARTIFACTS,
};

// --- Fake deps ---

function createFakeResolver(
  stores: Partial<FixtureStores>,
  fuzzy?: { name: string; storeKey: keyof FixtureStores; confidence: number },
): ItemResolver {
  return {
    resolve: async <TName extends StoreName>(store: TName, name: string) => {
      const storeRecords = stores[store as keyof FixtureStores] as Array<{ searchName: string }> | undefined;
      if (fuzzy && name === fuzzy.name && store === fuzzy.storeKey) {
        const record = storeRecords?.[0];
        return (record ? { record, confidence: fuzzy.confidence } : null) as unknown as ResolveResult<EntityStores[TName][number]> | null;
      }
      const record = storeRecords?.find(r => r.searchName === normalizeName(name));
      return (record ? { record, confidence: 1 } : null) as unknown as ResolveResult<EntityStores[TName][number]> | null;
    },
    search: async () => [],
  };
}

function createFakeValidator(overrides?: {
  illegalWeaponPerk?: { weaponHash: number; perkHash: number; reason: string };
  fragmentCapacities?: Map<number, number>;
}): PerkValidator {
  return {
    checkWeaponPerk: async (weaponHash, perkHash): Promise<PerkLegality> => {
      const o = overrides?.illegalWeaponPerk;
      if (o && weaponHash === o.weaponHash && perkHash === o.perkHash) return { legal: false, reason: o.reason };
      return { legal: true, column: 0, curated: true };
    },
    checkArtifactPerk: async (): Promise<PerkLegality> => ({ legal: true, column: 0, curated: true }),
    checkFragmentCount: async (aspectHashes, fragmentCount) => {
      const caps = overrides?.fragmentCapacities;
      const capacity = aspectHashes.reduce((s, h) => s + (caps?.get(h) ?? 2), 0);
      return { legal: fragmentCount <= capacity, capacity, requested: fragmentCount };
    },
  };
}

function createFakeCache(stores: Partial<FixtureStores>): EntityCache {
  return {
    getMeta: async () => null,
    rebuild: async () => { throw new Error("not used in tests"); },
    getStore: async <TName extends StoreName>(name: TName) => {
      const store = stores[name as keyof FixtureStores];
      if (!store) throw new Error(`missing fixture store: ${name}`);
      return store as EntityStores[TName];
    },
  };
}

function makeDeps(
  stores: Partial<FixtureStores> = DEFAULT_STORES,
  validatorOpts?: Parameters<typeof createFakeValidator>[0],
  fuzzy?: Parameters<typeof createFakeResolver>[1],
): ResolveBuildDeps {
  return { resolver: createFakeResolver(stores, fuzzy), validator: createFakeValidator(validatorOpts), cache: createFakeCache(stores) };
}

// --- Base fixture build (validated against zod schema) ---

const BASE_BUILD: GeneratedBuild = generatedBuildSchema.parse({
  name: "Arc Suspension Warlock",
  summary: "Combines arc ability uptime with strand suspension for consistent champion coverage.",
  subclass: {
    name: "Stormcaller", super: "Stormtrance", classAbility: "Healing Rift",
    movement: "Burst Glide", melee: "Ball Lightning", grenade: "Shackle Grenade",
    aspects: ["Lightning Surge"],
    fragments: ["Spark of Shock"],
    rationale: "Arc aspects and suspension grenade yield full champion coverage.",
  },
  statTargets: [
    { stat: "Health", target: 100, rationale: "Survivability." },
    { stat: "Melee", target: 200, rationale: "Max melee for +30% damage." },
    { stat: "Grenade", target: 150, rationale: "Enhanced grenade damage." },
    { stat: "Super", target: 100, rationale: "Average super uptime." },
    { stat: "Class", target: 100, rationale: "Class ability cooldown." },
    { stat: "Weapons", target: 50, rationale: "Basic weapon handling." },
  ],
  exoticArmor: {
    name: "Ophidian Aspect", rationale: "Weapon handling and reload.",
    alternatives: [{ name: "Karnstein Armlets", rationale: "Healing fallback." }],
  },
  armor: { archetype: "Gunner", rationale: "Good stat distribution." },
  weapons: [
    { slot: "Kinetic", name: "Fatebringer", isExotic: false, perks: [{ name: "Firefly", rationale: "AoE clears." }], rationale: "Adaptive hand cannon." },
    { slot: "Energy", name: "Conditional Finality", isExotic: true, perks: [], rationale: "Exotic shotgun." },
    { slot: "Power", name: "Gjallarhorn", isExotic: true, perks: [], rationale: "Rocket launcher." },
  ],
  mods: { helmet: ["Ashes to Assets"], arms: ["Heavy Handed"], chest: [], legs: [], classItem: [], rationale: "Super economy mods." },
  artifact: { name: "The Current", perks: [{ name: "Anti-Barrier Scout Rifle", rationale: "Scout barrier." }], rationale: "Season perks." },
  gameplayLoop: "Use grenade to suspend. Jolt with melee. Clean up with Fatebringer.",
  acquisitionNotes: "Fatebringer from Vault of Glass. Gjallarhorn from Grasp of Avarice.",
});

// --- Tests ---

describe("resolveBuild – verified build", () => {
  it("resolves all refs as verified, covers all three champion types, fragmentCheck legal", async () => {
    const sheet = await resolveBuild(BASE_BUILD, "Grandmaster Nightfall", makeDeps());

    expect(sheet.validation.fuzzy).toBe(0);
    expect(sheet.validation.unresolved).toBe(0);
    expect(sheet.validation.illegalPerks).toBe(0);
    expect(sheet.validation.verified).toBeGreaterThan(0);

    expect(sheet.championCoverage.covered.Barrier).toBe(true);
    expect(sheet.championCoverage.covered.Overload).toBe(true);
    expect(sheet.championCoverage.covered.Unstoppable).toBe(true);

    expect(sheet.weapons[0]?.frame).toBe("Adaptive Frame");
    expect(sheet.weapons[0]?.championCounter).toBe("Barrier");
    expect(sheet.subclass.fragmentCheck?.legal).toBe(true);
  });
});

describe("resolveBuild – fuzzy + unresolved mix", () => {
  it("typo weapon is fuzzy, unknown fragment is unresolved, counts match", async () => {
    const build = {
      ...BASE_BUILD,
      subclass: { ...BASE_BUILD.subclass, fragments: ["Nonexistent Fragment"] },
      weapons: [
        { ...BASE_BUILD.weapons[0]!, name: "Fatebringerr" },
        BASE_BUILD.weapons[1]!, BASE_BUILD.weapons[2]!,
      ],
    } as unknown as GeneratedBuild;

    const sheet = await resolveBuild(build, "Nightfall", makeDeps(DEFAULT_STORES, undefined, { name: "Fatebringerr", storeKey: "weapons", confidence: 0.8 }));

    expect(sheet.weapons[0]!.reference.status).toBe("fuzzy");
    expect(sheet.weapons[0]!.reference.confidence).toBe(0.8);
    expect(sheet.subclass.fragments[0]!.status).toBe("unresolved");
    expect(sheet.validation.fuzzy).toBeGreaterThanOrEqual(1);
    expect(sheet.validation.unresolved).toBeGreaterThanOrEqual(1);
  });
});

describe("resolveBuild – illegal perk", () => {
  it("illegalPerks = 1 and legality.reason is carried through", async () => {
    const sheet = await resolveBuild(BASE_BUILD, "Nightfall", makeDeps(DEFAULT_STORES, {
      illegalWeaponPerk: { weaponHash: 4001, perkHash: 5001, reason: "Firefly not in Fatebringer pool" },
    }));

    expect(sheet.validation.illegalPerks).toBe(1);
    expect(sheet.weapons[0]!.perks[0]!.legality?.legal).toBe(false);
    expect(sheet.weapons[0]!.perks[0]!.legality?.reason).toBe("Firefly not in Fatebringer pool");
  });
});

describe("resolveBuild – artifact", () => {
  it("matched perk is verified + legal, unmatched is unresolved + illegal", async () => {
    const build = { ...BASE_BUILD, artifact: { ...BASE_BUILD.artifact!, perks: [{ name: "Anti-Barrier Scout Rifle", rationale: "Barrier." }, { name: "Made Up Perk", rationale: "Does not exist." }] } } as unknown as GeneratedBuild;
    const sheet = await resolveBuild(build, "Nightfall", makeDeps());

    expect(sheet.artifact!.perks[0]!.status).toBe("verified");
    expect(sheet.artifact!.perks[0]!.legality?.legal).toBe(true);
    expect(sheet.artifact!.perks[1]!.status).toBe("unresolved");
    expect(sheet.artifact!.perks[1]!.legality?.legal).toBe(false);
    expect(sheet.artifact!.allowedInActivity).toBe(true);
  });

  it("allowedInActivity = false for Trials of Osiris", async () => {
    const sheet = await resolveBuild(BASE_BUILD, "Trials of Osiris", makeDeps());
    expect(sheet.artifact!.allowedInActivity).toBe(false);
  });

  it("sheet.artifact = null when build.artifact is null", async () => {
    const build = { ...BASE_BUILD, artifact: null } as unknown as GeneratedBuild;
    expect((await resolveBuild(build, "Nightfall", makeDeps())).artifact).toBeNull();
  });
});

describe("resolveBuild – fragment over-capacity", () => {
  it("fragmentCheck.legal = false when requested > capacity", async () => {
    const build = { ...BASE_BUILD, subclass: { ...BASE_BUILD.subclass, fragments: ["Spark of Shock", "Spark of Resistance", "Spark of Shock", "Spark of Resistance"] } } as unknown as GeneratedBuild;
    const sheet = await resolveBuild(build, "Nightfall", makeDeps(DEFAULT_STORES, { fragmentCapacities: new Map([[1001, 1]]) }));

    expect(sheet.subclass.fragmentCheck?.legal).toBe(false);
    expect(sheet.subclass.fragmentCheck?.capacity).toBe(1);
    expect(sheet.subclass.fragmentCheck?.requested).toBe(4);
  });
});

describe("resolveBuild – stat benefits", () => {
  it("Melee at 200 includes '+30% melee ability damage'", async () => {
    const sheet = await resolveBuild(BASE_BUILD, "Nightfall", makeDeps());
    expect(sheet.statTargets.find(s => s.stat === "Melee")!.benefits).toContain("+30% melee ability damage");
  });

  it("Weapons at 50 omits enhanced boss-damage lines", async () => {
    const sheet = await resolveBuild(BASE_BUILD, "Nightfall", makeDeps());
    const benefits = sheet.statTargets.find(s => s.stat === "Weapons")!.benefits;
    expect(benefits.some(b => b.includes("boss"))).toBe(false);
  });
});
