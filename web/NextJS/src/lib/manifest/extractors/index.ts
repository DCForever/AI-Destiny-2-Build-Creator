import type { Extractor } from "../types/services";
import { exoticArmorExtractor } from "./exoticArmor";
import { exoticWeaponsExtractor } from "./exoticWeapons";
import { weaponsExtractor } from "./weapons";
import { weaponPerksExtractor } from "./weaponPerks";
import { originTraitsExtractor } from "./originTraits";
import { artifactsExtractor } from "./artifacts";
import { aspectsExtractor } from "./aspects";
import { fragmentsExtractor } from "./fragments";
import { abilitiesExtractor } from "./abilities";
import { modsExtractor } from "./mods";
import { setBonusesExtractor } from "./setBonuses";
import { statsExtractor } from "./stats";

/** Ordered registry of all entity extractors. */
export const EXTRACTORS: Extractor[] = [
  exoticArmorExtractor,
  exoticWeaponsExtractor,
  weaponsExtractor,
  weaponPerksExtractor,
  originTraitsExtractor,
  artifactsExtractor,
  aspectsExtractor,
  fragmentsExtractor,
  abilitiesExtractor,
  modsExtractor,
  setBonusesExtractor,
  statsExtractor,
];
