/**
 * Per-class exotic armor notes and highlighted 9.7.0 builds, curated from the
 * patch notes exotic rework list and launch build-crafting guides.
 */

import type { ExoticArmorNote, HighlightedBuild, StatGuidanceEntry } from "./types";

export const EXOTIC_ARMOR_NOTES: readonly ExoticArmorNote[] = [
  { name: "Hallowfire Heart", className: "Titan", note: "Reworked around Sunfire Furnace stacks: Solar ability defeats cure and boost grenade/class regen and Super damage; exiting Super converts stacks to Super energy" },
  { name: "Pyrogale Gauntlets", className: "Titan", note: "Super Cyclone tracking up ~40%; consistent single-slam burst" },
  { name: "Peregrine Greaves", className: "Titan", note: "Multipliers trimmed but shoulder-charge base damage doubled: net buff; champion/miniboss deleter" },
  { name: "Helm of Saint-14", className: "Titan", note: "Reworked for new relocatable 2x-size Ward of Dawn: The Saint stacks extend Ward; Void/Kinetic damage suppresses around victims" },
  { name: "Cadmus Ridge Lancecap", className: "Titan", note: "Stasis Lances from rapid Stasis damage even without barricade; lance damage scales with Frost Armor stacks" },
  { name: "Severance Enclosure", className: "Titan", note: "Reliability fixes plus disorient on shockwave; multi-shockwave hits restored" },
  { name: "Wormhusk Crown", className: "Hunter", note: "Reworked: class ability grants cure; Solar multikills grant Burning Souls; dodge greatly cures you and allies" },
  { name: "Caliban's Hand", className: "Hunter", note: "+25% melee recharge; scorch damage refunds melee energy; ignition kills fully refund knife energy" },
  { name: "Raiden Flux", className: "Hunter", note: "Arc Staff hits jolt; combo finisher counts as critical damage" },
  { name: "Shinobu's Vow", className: "Hunter", note: "Skip Grenade loop with Bolt Charge synergy; full Bolt Charge heals and enhances the grenade" },
  { name: "Fr0st-EE5", className: "Hunter", note: "Frost Armor while sprinting; Stasis weapons deal bonus damage with Frost Armor" },
  { name: "Lucky Pants", className: "Hunter", note: "NERF: boss damage down ~33% (Eriana's Vow exception at 4.5x); still strong outside boss DPS" },
  { name: "Nezarec's Sin", className: "Warlock", note: "Soul Siphon suppresses; suppressed defeats extend Abyssal Extractors — pairs with the new Soul Siphon Aspect" },
  { name: "Skull of Dire Ahamkara", className: "Warlock", note: "Nova Lance follow-up cast after Nova Bomb; lance-destroyed Cataclysm creates a Nova Vortex" },
  { name: "Crown of Tempests", className: "Warlock", note: "Conduction Tines lasts 10s in PvE; Ionic Sentry deploys a Storm Grenade while Tines active" },
  { name: "Mantle of Battle Harmony", className: "Warlock", note: "Triggers on sustained damage; post-Super all-element surges plus matching-element detonations" },
  { name: "Astrocyte Verse", className: "Warlock", note: "Dark blink air move; blinking grants Volatile Rounds" },
  { name: "Dawn Chorus", className: "Warlock", note: "Bigger ignitions from your scorch; melee energy from ignition damage; Daybreak projectiles ignite instantly" },
  { name: "Contraverse Hold", className: "Warlock", note: "NERF: 15% less energy return with Magnetic/Handheld Supernova" },
];

export const HIGHLIGHTED_BUILDS: readonly HighlightedBuild[] = [
  {
    className: "Titan",
    subclass: "Sunbreaker",
    title: "Shieldburst Ignition",
    summary:
      "Hallowfire Heart + Shattered Throne set. Shieldburst's scorching rounds on Rally Barricade feed team ignitions; Shieldburst detonation scales with Class above 100. Precision/Adaptive primary covers Barrier.",
  },
  {
    className: "Titan",
    subclass: "Behemoth",
    title: "Freeze-Shatter Engine",
    summary:
      "Cadmus Ridge Lancecap + Shatter Grenade + Cryoclasm (Stasis wave while sliding with Frost Armor). Shatter stuns Unstoppable; Aggressive-frame heavy backs it up while the primary handles Barrier.",
  },
  {
    className: "Hunter",
    subclass: "Gunslinger",
    title: "Crackshot Duelist (Trials)",
    summary:
      "Cruel Electrum 4-piece + Crackshot Aspect (cure on full primary hits). Primary Phantom removes you from radar after a pick. No artifact in Trials by rule.",
  },
  {
    className: "Hunter",
    subclass: "Nightstalker",
    title: "Phantom Surge Skirmisher",
    summary:
      "Phantom Surge melee with reworked Trapper's Ambush; Skirmisher-archetype armor (Melee/Weapons) keeps melee damage and weapon uptime high; jolt/slow verbs cover Overload.",
  },
  {
    className: "Warlock",
    subclass: "Voidwalker",
    title: "Soul Siphon Attrition",
    summary:
      "New Soul Siphon Aspect + Nezarec's Sin: siphon suppresses (Overload counter), suppressed defeats extend Abyssal Extractors; Shattered Throne set for Truth to Power ability uptime. Strong in GMs.",
  },
  {
    className: "Warlock",
    subclass: "Dawnblade",
    title: "Dawn Chorus Ignition Chain",
    summary:
      "Dawn Chorus scorch loop: scorch refunds melee, ignitions chain, Daybreak ignites on hit. Solar verbs stun Unstoppable via ignition; bring a Lightweight/Rapid-Fire weapon for Overload.",
  },
];

export const STAT_GUIDANCE: readonly StatGuidanceEntry[] = [
  {
    context: "Endgame PvE (GM, Master raids)",
    guidance:
      "Health 150+ for shield capacity and recharge; push the build's core damage stat (Melee/Grenade/Super) toward 200 for the enhanced damage benefit; Class above 100 gives an overshield on cast; Weapons above 100 is the best generic DPS stat (+15% boss damage at 200).",
  },
  {
    context: "General PvE",
    guidance:
      "One damage stat to ~200, Health to ~100-150, remainder into Class or Weapons. Ability-spam is weaker post-9.7.0; weapon uptime matters more.",
  },
  {
    context: "PvP (Trials/Competitive)",
    guidance:
      "Weapons to ~100+ (up to +6% vs Guardians at 200), Health high for flinch resistance, Class above 100 for a small overshield on cast. No artifact perks in Trials/Competitive.",
  },
];
