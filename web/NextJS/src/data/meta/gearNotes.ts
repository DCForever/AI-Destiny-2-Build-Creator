/**
 * Set-bonus and exotic notes on the 9.7.0 baseline, curated from the cached
 * sources (patch notes, build-crafting guides). Marked for user review.
 */

import type {
  ExoticWeaponNote,
  SetBonusCombo,
  SetBonusGuidance,
} from "./types";

export const SET_BONUS_GUIDANCE: readonly SetBonusGuidance[] = [
  {
    setName: "Shattered Throne",
    source: "Shattered Throne dungeon",
    twoPiece: "Queensfoil Rush: finishers grant an overshield and a Stasis slowing burst",
    fourPiece:
      "Truth to Power: dealing damage builds stacking damage resistance (finishers accelerate); at max stacks all ability recharge rates increase significantly",
    assessment:
      "Safest general PvE set: rewards normal combat behavior and offsets the 9.7.0 cooldown nerfs; no subclass or weapon-type requirement",
  },
  {
    setName: "Cruel Electrum",
    source: "Trials of Osiris",
    twoPiece:
      "Primary Survivor: primary handling/reload/target acquisition plus flinch resistance when allies are down",
    fourPiece: "Primary Phantom: primary kills briefly remove you from enemy radar",
    assessment: "Strongest Trials set: radar-free repositioning after a pick decides 3v3 rounds",
  },
  {
    setName: "Iron Battalion",
    source: "Iron Banner (focusable with IB Ciphers)",
    twoPiece: "Primary Honing: primaries gain handling, reload, and scaling damage vs non-boss combatants",
    fourPiece: "Supercyclical: final blows during a Super refund part of its energy when it ends",
    assessment:
      "Best Super-uptime set: directly counters the 60% cut to boss Super generation; pair with Super-refund exotics",
  },
  {
    setName: "SRL",
    source: "Sparrow Racing League gear",
    twoPiece: "Revving Up: charge grants health regen",
    fourPiece: "Dielectric Drift: slide-jolt loop for Arc movement builds",
    assessment: "Flashy Arc movement pick; jolt and ability-energy artifact mods extend the loop",
  },
  {
    setName: "Veritas",
    source: "Destination set",
    twoPiece: "Elemental pickup on finishers or successive powered melee final blows (matches Light subclass)",
    fourPiece: "Finishers on powerful combatants heal you and create loyal Void moths",
    assessment: "Natural fit for finisher-heavy PvE builds alongside Queensfoil Rush",
  },
  {
    setName: "Exodus Down",
    source: "Destination set",
    twoPiece: "Armor-charge healing",
    fourPiece: "Damage resistance synergy",
    assessment: "Solo survivability staple; combine 2-piece with Shattered Throne's Truth to Power",
  },
];

export const SET_BONUS_COMBOS: readonly SetBonusCombo[] = [
  { pieces: "Queensfoil Rush + Scoot to Loot", useCase: "Safest general PvE utility: finisher overshield plus ammo on slide" },
  { pieces: "Primary Chain + Primary Honing", useCase: "Best primary-weapon package: stacking handling and damage" },
  { pieces: "Primary Survivor + Primary Chain", useCase: "Safer Trials primary package" },
  { pieces: "Veritas + Queensfoil Rush", useCase: "Finisher-heavy PvE: both reward the same behavior" },
  { pieces: "Exodus Down + Truth to Power", useCase: "Solo survivability: armor-charge healing plus DR and ability uptime" },
];

export const EXOTIC_WEAPON_NOTES: readonly ExoticWeaponNote[] = [
  { name: "The Lament", note: "Previous nerf reverted by ~70%; premier sword DPS again" },
  { name: "Anarchy", note: "Buffed; strong set-and-forget boss damage with the additive bonus economy" },
  { name: "Arbalest", note: "+33% damage vs champions; excellent Barrier tool (intrinsic anti-barrier linear)" },
  { name: "Sleeper Simulant", note: "+10% vs bosses and champions" },
  { name: "Ice Breaker", note: "No longer errantly ignites stunned Barrier champions" },
  { name: "Choir of One", note: "Ammo per brick reduced; still strong sustained damage" },
  {
    name: "Rocket-Assisted Pulses",
    note: "Heavily nerfed as a category (ammo economy and damage); no longer the default special pick",
  },
  {
    name: "(General)",
    note: "Every exotic weapon now has a catalyst; many older catalysts add real perks (e.g. Heal Clip, Incandescent, Chain Reaction). Exotic primaries deal +40% vs minors, legendary primaries +30%.",
  },
];
