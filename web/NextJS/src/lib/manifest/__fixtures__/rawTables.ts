/**
 * Hand-trimmed in-memory raw-table fixture covering every extractor.
 * Only the fields each extractor actually reads are populated.
 */

import type { RawTableName, RawTable } from "../types/services";

type D = Record<string, unknown>;

function dp(name: string, description = "", icon?: string): D {
  return icon ? { name, description, icon } : { name, description };
}

function mkItem(hash: number, name: string, desc: string, extra: D = {}): D {
  return { hash, displayProperties: dp(name, desc), ...extra };
}

function mkPlug(hash: number, name: string, catId: string, desc = "", extra: D = {}): D {
  return mkItem(hash, name, desc, { plug: { plugCategoryIdentifier: catId }, ...extra });
}

// ─── DestinyStatDefinition ────────────────────────────────────────────────
// Six Armor 3.0 stats (real hashes) + Aspect Energy Capacity

const STAT_TABLE: RawTable = {
  "2996146975": { hash: 2996146975, displayProperties: dp("Mobility", "Movement speed.") },
  "392767087":  { hash: 392767087,  displayProperties: dp("Resilience", "Damage resistance.") },
  "1943323491": { hash: 1943323491, displayProperties: dp("Recovery", "Rift recharge.") },
  "1735777505": { hash: 1735777505, displayProperties: dp("Discipline", "Grenade recharge.") },
  "144602215":  { hash: 144602215,  displayProperties: dp("Intellect", "Super recharge.") },
  "4244567560": { hash: 4244567560, displayProperties: dp("Strength", "Melee recharge.") },
  "2223994109": { hash: 2223994109, displayProperties: dp("Aspect Energy Capacity", "Fragment slots.") },
};

// ─── DestinyEquipmentSlotDefinition ───────────────────────────────────────

const SLOT_TABLE: RawTable = {
  "3001": { hash: 3001, displayProperties: dp("Kinetic Weapons") },
  "3002": { hash: 3002, displayProperties: dp("Energy Weapons") },
  "3003": { hash: 3003, displayProperties: dp("Power Weapons") },
  "3004": { hash: 3004, displayProperties: dp("Helmet") },
  "3005": { hash: 3005, displayProperties: dp("Gauntlets") },
  "3006": { hash: 3006, displayProperties: dp("Chest Armor") },
  "3007": { hash: 3007, displayProperties: dp("Leg Armor") },
  "3008": { hash: 3008, displayProperties: dp("Class Armor") },
};

// ─── DestinyDamageTypeDefinition ──────────────────────────────────────────

const DAMAGE_TABLE: RawTable = {
  "4001": { hash: 4001, displayProperties: dp("Solar") },
  "4002": { hash: 4002, displayProperties: dp("Stasis") },
  "4003": { hash: 4003, displayProperties: dp("Arc") },
  "4004": { hash: 4004, displayProperties: dp("Void") },
};

// ─── DestinyPlugSetDefinition ─────────────────────────────────────────────

const PLUG_SET_TABLE: RawTable = {
  // Barrel curated set (Corkscrew + Fluted)
  "5001": { reusablePlugItems: [{ plugItemHash: 1010 }, { plugItemHash: 1011 }] },
  // Trait randomized set (Kill Clip + Slideshot)
  "5002": { reusablePlugItems: [{ plugItemHash: 1012 }, { plugItemHash: 1013 }] },
  // Trait curated set (Kill Clip only)
  "5003": { reusablePlugItems: [{ plugItemHash: 1012 }] },
};

// ─── DestinySandboxPerkDefinition ─────────────────────────────────────────

const SANDBOX_PERK_TABLE: RawTable = {
  "8001": { hash: 8001, displayProperties: dp("Hive Mind", "Bonus for 2-piece set.") },
  // Artifact perk body text when inventory plug description is blank
  "8701": {
    hash: 8701,
    displayProperties: dp("Volatile Flow Effect", "Picking up an orb grants Volatile Rounds."),
  },
  // Mod sandbox fallback when tooltip missing
  "8702": {
    hash: 8702,
    displayProperties: dp(
      "Heavy Ammo Finder Effect",
      "Increases the effect of all contributions towards the Heavy ammo meter.",
    ),
  },
  // Focusing Strike — true effect (tooltip is stacking-only boilerplate)
  "8703": {
    hash: 8703,
    displayProperties: dp(
      "Focusing Strike",
      "Grants class ability energy when you cause damage with a powered melee attack.",
    ),
  },
};

// ─── DestinyArtifactDefinition ────────────────────────────────────────────

const ARTIFACT_TABLE: RawTable = {
  "6001": {
    hash: 6001,
    displayProperties: dp("Disc of Pestilence", "Season artifact.", "/artifact.png"),
    tiers: [
      { items: [{ itemHash: 7001 }, { itemHash: 7002 }] },
      { items: [{ itemHash: 7003 }] },
    ],
  },
};

// ─── DestinyEquipableItemSetDefinition ────────────────────────────────────

const SET_TABLE: RawTable = {
  "9001": {
    hash: 9001,
    displayProperties: dp("Hive Mind", "A Hive-themed armor set.", "/set.png"),
    setItems: [1007],
    setPerks: [{ requiredSetCount: 2, sandboxPerkHash: 8001 }],
  },
};

// ─── DestinyInventoryItemDefinition ───────────────────────────────────────

const ITEM_TABLE: RawTable = {
  // Exotic armor: Celestial Nighthawk (Hunter helmet, Exotic)
  "1001": {
    hash: 1001,
    displayProperties: dp("Celestial Nighthawk", "Exotic Hunter helmet.", "/nighthawk.png"),
    itemType: 2,
    classType: 1, // Hunter
    flavorText: "It's a space monocle.",
    inventory: { tierType: 6 },
    equippingBlock: { equipmentSlotTypeHash: 3004 },
    sockets: {
      socketEntries: [
        { singleInitialItemHash: 1002 }, // intrinsic perk
        { singleInitialItemHash: 1003 }, // archetype
      ],
      socketCategories: [],
    },
  },

  // Intrinsic plug for exotic armor
  "1002": mkPlug(1002, "Hawkeye Hack", "intrinsics",
    "Precision hits and kills with Golden Gun reduce its cooldown."),

  // Archetype plug for exotic armor
  "1003": mkPlug(1003, "Celestial Archetype", "armor_archetypes",
    "Exotic armor archetype.", { itemTypeDisplayName: "Archetype" }),

  // Exotic weapon: Gjallarhorn (Power, Solar, Heavy)
  "1004": {
    hash: 1004,
    displayProperties: dp("Gjallarhorn", "Exotic rocket launcher.", "/gjallarhorn.png"),
    itemType: 3,
    defaultDamageTypeHash: 4001, // Solar
    flavorText: "Light the way.",
    inventory: { tierType: 6 },
    equippingBlock: { ammoType: 3, equipmentSlotTypeHash: 3003 }, // Heavy, Power
    sockets: {
      socketEntries: [
        { singleInitialItemHash: 1005 }, // intrinsic (Wolfpack Rounds)
        { singleInitialItemHash: 1006 }, // catalyst
      ],
      socketCategories: [],
    },
  },

  // Intrinsic plug for Gjallarhorn
  "1005": mkPlug(1005, "Wolfpack Rounds", "intrinsics",
    "Rounds fired from this weapon split into tracking cluster missiles."),

  // Catalyst plug for Gjallarhorn
  "1006": mkItem(1006, "Gjallarhorn Catalyst", "Upgrade Masterwork."),

  // Legendary weapon: Chattering Bone (Kinetic, Stasis, Primary)
  "1007": {
    hash: 1007,
    displayProperties: dp("Chattering Bone", "Legendary pulse rifle.", "/chatbone.png"),
    itemType: 3,
    itemTypeDisplayName: "Pulse Rifle",
    defaultDamageTypeHash: 4002, // Stasis
    inventory: { tierType: 5 },
    equippingBlock: { ammoType: 1, equipmentSlotTypeHash: 3001 }, // Primary, Kinetic
    sockets: {
      socketEntries: [
        { singleInitialItemHash: 1008 },                           // [0] frame (excluded)
        { singleInitialItemHash: 1009 },                           // [1] origin (excluded from perkCols)
        { reusablePlugSetHash: 5001 },                             // [2] barrels (curated only)
        { reusablePlugSetHash: 5003, randomizedPlugSetHash: 5002 }, // [3] traits (curated + randomized)
      ],
      socketCategories: [
        { socketCategoryHash: 4241085061, socketIndexes: [0, 1, 2, 3] },
      ],
    },
  },

  // Frame plug: Precision Frame
  "1008": mkPlug(1008, "Precision Frame", "frames",
    "This weapon's recoil pattern is more predictably vertical.", { itemTypeDisplayName: "Intrinsic" }),

  // Origin trait: Tex Balanced Stock
  "1009": mkPlug(1009, "Tex Balanced Stock", "origins",
    "Holding reload grants stability and handling for a short duration."),

  // Barrel perks
  "1010": mkPlug(1010, "Corkscrew Rifling", "barrels",
    "Balanced barrel.", { itemTypeDisplayName: "Barrel" }),
  "1011": mkPlug(1011, "Fluted Barrel",     "barrels",
    "Ultra-light barrel.", { itemTypeDisplayName: "Barrel" }),

  // Trait perks (curated + randomized)
  "1012": mkPlug(1012, "Kill Clip", "frames",
    "Reloading after a kill grants increased damage.", { itemTypeDisplayName: "Trait" }),
  "1013": mkPlug(1013, "Slideshot", "frames",
    "Sliding partially reloads this weapon.", { itemTypeDisplayName: "Trait" }),

  // Aspects
  "1014": mkItem(1014, "Touch of Thunder", "Improves Arc grenades.", {
    itemTypeDisplayName: "Arc Aspect",
    classType: 1, // Hunter
    plug: { plugCategoryIdentifier: "hunter.arc.aspects" },
    investmentStats: [{ statTypeHash: 2223994109, value: 4 }],
  }),
  "1015": mkItem(1015, "Consecration", "Sliding charges a Solar Flare.", {
    itemTypeDisplayName: "Solar Aspect",
    classType: 0, // Titan
    plug: { plugCategoryIdentifier: "titan.solar.aspects" },
    investmentStats: [{ statTypeHash: 2223994109, value: 2 }],
  }),

  // Fragments
  "1016": mkItem(1016, "Spark of Brilliance", "Defeating a blinded target creates a blinding explosion.", {
    itemTypeDisplayName: "Arc Fragment",
    plug: { plugCategoryIdentifier: "shared.arc.fragments" },
    investmentStats: [],
  }),
  "1017": mkItem(1017, "Echo of Undermining", "Your Void grenades weaken targets.", {
    itemTypeDisplayName: "Void Fragment",
    plug: { plugCategoryIdentifier: "shared.void.fragments" },
    investmentStats: [{ statTypeHash: 4244567560, value: -10 }], // Strength -10
  }),

  // Abilities
  "1018": mkItem(1018, "Chaos Reach", "Unleash a long-range Arc beam.", {
    itemTypeDisplayName: "Arc Super",
    classType: 2, // Warlock
    plug: { plugCategoryIdentifier: "warlock.arc.supers" },
  }),
  "1019": mkItem(1019, "Pulse Grenade", "Grenade that periodically damages enemies.", {
    itemTypeDisplayName: "Arc Grenade",
    classType: 3, // all
    plug: { plugCategoryIdentifier: "shared.grenades" },
  }),
  "1020": mkItem(1020, "Storm Fist", "Arc charged melee attack.", {
    itemTypeDisplayName: "Arc Melee",
    classType: 0, // Titan
    plug: { plugCategoryIdentifier: "titan.arc.melee" },
  }),
  "1021": mkItem(1021, "Gambler's Dodge", "Dodge near an enemy to recharge melee.", {
    itemTypeDisplayName: "Void Class Ability",
    classType: 1, // Hunter
    plug: { plugCategoryIdentifier: "hunter.void.class_abilities" },
  }),
  "1022": mkItem(1022, "Burst Glide", "Jump with initial burst of momentum.", {
    itemTypeDisplayName: "Arc Jump",
    classType: 2, // Warlock
    plug: { plugCategoryIdentifier: "warlock.arc.movement" },
  }),
  "1026": mkItem(1026, "Phoenix Dive", "Dive to the ground and create a burst of Solar Light that cures nearby allies.", {
    itemTypeDisplayName: "Solar Class Ability",
    classType: 2, // Warlock
    plug: { plugCategoryIdentifier: "warlock.solar.class_abilities" },
  }),

// Mods
  "1023": mkItem(1023, "Charged Up", "Increases the maximum number of stacks.", {
    itemType: 19,
    plug: { plugCategoryIdentifier: "enhancements.v2_head", energyCost: { energyCost: 1 } },
  }),
  "1024": mkItem(1024, "Special Ammo Finder", "Increases special ammo drop chance.", {
    itemType: 19,
    plug: { plugCategoryIdentifier: "enhancements.general", energyCost: { energyCost: 0 } },
  }),
  "1025": mkItem(1025, "Harmonic Tuning", "Tuning mod.", {
    itemType: 19,
    plug: { plugCategoryIdentifier: "enhancements.tuning" },
  }),
// Major Melee (+10 Melee) — live cat is enhancements.v2_general
  "1030": mkItem(1030, "Major Melee", "+10 Melee.", {
    itemType: 19,
    plug: { plugCategoryIdentifier: "enhancements.v2_general", energyCost: { energyCost: 3 } },
    investmentStats: [{ statTypeHash: 4244567218, value: 10 }],
  }),
  // Minor Health (+5 Health)
  "1031": mkItem(1031, "Minor Health", "+5 Health.", {
    itemType: 19,
    plug: { plugCategoryIdentifier: "enhancements.v2_chest", energyCost: { energyCost: 1 } },
    investmentStats: [{ statTypeHash: 392767087, value: 5 }],
  }),
  // Blank display desc + effect tooltip only (no sandbox) — tooltip used as body
  "1027": {
    hash: 1027,
    displayProperties: dp("Heavy Ammo Finder", ""),
    itemType: 19,
    plug: {
      plugCategoryIdentifier: "enhancements.v2_head",
      energyCost: { energyCost: 1 },
    },
    tooltipNotifications: [
      {
        displayString:
          "Primary ammo weapon final blows help you find ammo more quickly. Does not function in Crucible.",
        displayStyle: "ui_display_style_perk_info",
      },
    ],
  },
  // Focusing Strike shape: stacking-only tooltip + real effect on sandbox perk
  "1028": {
    hash: 1028,
    displayProperties: dp("Focusing Strike", ""),
    itemType: 19,
    plug: {
      plugCategoryIdentifier: "enhancements.v2_arms",
      energyCost: { energyCost: 1 },
    },
    perks: [{ perkHash: 8703 }],
    tooltipNotifications: [
      {
        displayString:
          "Multiple copies of this mod can be stacked to increase the potency of its effect, with diminishing returns for each additional copy of the mod.",
        displayStyle: "ui_display_style_perk_info",
      },
    ],
  },
  // Same mod, higher cost (normal). Extract should keep this over 1028.
  "1029": {
    hash: 1029,
    displayProperties: dp("Focusing Strike", ""),
    itemType: 19,
    plug: {
      plugCategoryIdentifier: "enhancements.v2_arms",
      energyCost: { energyCost: 2 },
    },
    perks: [{ perkHash: 8703 }],
  },

  // Artifact perk items
  // 7001: blank inventory description — real body lives on sandbox perk (typical Bungie shape)
  "7001": {
    hash: 7001,
    displayProperties: dp("Volatile Flow", "", "/vflow.png"),
    perks: [{ perkHash: 8701 }],
  },
  "7002": { hash: 7002, displayProperties: dp("Overload Auto Rifles", "Auto rifles stun Overload champions.", "/oar.png") },
  "7003": { hash: 7003, displayProperties: dp("Unstoppable Hand Cannon", "Hand cannons stun Unstoppable champions.", "/uhc.png") },
};

// ─── Full fixture export ──────────────────────────────────────────────────

export const RAW_TABLES: Record<RawTableName, RawTable> = {
  DestinyInventoryItemDefinition: ITEM_TABLE,
  DestinyStatDefinition: STAT_TABLE,
  DestinyPlugSetDefinition: PLUG_SET_TABLE,
  DestinySocketTypeDefinition: {},
  DestinySocketCategoryDefinition: {},
  DestinyDamageTypeDefinition: DAMAGE_TABLE,
  DestinyInventoryBucketDefinition: {},
  DestinyClassDefinition: {},
  DestinySandboxPerkDefinition: SANDBOX_PERK_TABLE,
  DestinyArtifactDefinition: ARTIFACT_TABLE,
  DestinyEquipmentSlotDefinition: SLOT_TABLE,
  DestinyEquipableItemSetDefinition: SET_TABLE,
  DestinyLoadoutIconDefinition: {},
  DestinyLoadoutColorDefinition: {},
  DestinyLoadoutNameDefinition: {},
};
