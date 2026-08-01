export const SUBCLASSES_BY_CLASS = {
  Titan: ["Sunbreaker", "Striker", "Behemoth", "Sentinel", "Berserker", "Prismatic Titan"],
  Hunter: ["Gunslinger", "Arcstrider", "Revenant", "Nightstalker", "Threadrunner", "Prismatic Hunter"],
  Warlock: ["Dawnblade", "Stormcaller", "Shadebinder", "Voidwalker", "Broodweaver", "Prismatic Warlock"],
} as const;

export type GuardianClass = keyof typeof SUBCLASSES_BY_CLASS;

export {
  SUBCLASS_METADATA,
  getSubclassMeta,
  formatSubclassLabel,
  listSubclassVerbs,
  type SubclassMeta,
  type SubclassVerbMeta,
} from "./subclasses.meta";
