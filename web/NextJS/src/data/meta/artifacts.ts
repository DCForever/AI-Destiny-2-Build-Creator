/**
 * Artifacts 2.0 guidance, curated from the Update 9.7.0 patch notes
 * ("Seasonal > Introducing Artifacts 2.0"). Seven permanent artifacts; all
 * champion mods removed (now intrinsic to weapons); perks save to loadouts;
 * disabled in Trials of Osiris and Competitive Crucible.
 */

import type { ArtifactGuidance } from "./types";

export const ARTIFACT_GUIDANCE: readonly ArtifactGuidance[] = [
  {
    name: "Queensfoil Censer",
    identity:
      "Solar/Super-leaning grid: Torch, Heart of the Flame, Bring into Being, Dragons Bite, Creeping Chill, Solo Operative.",
    rebalanceNotes: [
      "Torch no longer increases damage versus bosses",
      "Heart of the Flame capped at +15% Super damage from nearby allies (was 21%)",
      "Bring into Being activates at 60%+ Super energy (seasonal-armor requirement folded in)",
      "Creeping Chill works with any Stasis defeat and grants Frost Armor to nearby allies",
      "Solo Operative reworked: precision final blows grant a scaling weapon-damage benefit until you die",
    ],
    bestFor: "Super-centric and solo PvE builds; Solo Operative rewards careful play.",
  },
  {
    name: "Slayer Baron Apothecary Satchel",
    identity:
      "Stasis/Void hybrid support grid: Wind Chill, Debilitating Wave, Curative Orbs, Void Renewal, Kinetic Impacts, Old God's Rite, Weakened Clear, Killing Breeze, Frost Renewal.",
    rebalanceNotes: [
      "Wind Chill no longer requires precision damage",
      "Kinetic Impacts now triggers from special/primary grenade launchers too",
      "Old God's Rite projectile damage up ~200% (+85% vs orange bars, +200% vs red bars)",
      "Concussive Reload replaced by Weakened Clear; Armor of Eramis replaced by Frost Renewal",
      "Finders Keepers replaced by Killing Breeze (7s duration)",
    ],
    bestFor: "Stasis builds and grenade-launcher loadouts; strong add-clear support.",
  },
  {
    name: "Hunters Journal",
    identity:
      "Weapon-uptime grid: Sword Stamina, Sustained Fire, Shieldcrush, Transference.",
    rebalanceNotes: [
      "Sword Stamina grants 1 special-sword ammo on three rapid kills (was 3)",
      "Sustained Fire reduced to Resist x2 but now works with Support Auto Rifles",
      "Shieldcrush works with the Melee and Grenade stats",
      "Transference max payout needs 12 kills (was 20)",
    ],
    bestFor: "Sword and sustained-fire weapon builds; support-frame synergies.",
  },
  {
    name: "Tablet of Ruin",
    identity:
      "Void/Strand ability grid: Volatile Marksman, Elemental Siphon, Vile Weave, Flashover, No Bell, Heavy Ordinance Regeneration, Limit Break, Gold from Lead, Particle Reconstruction.",
    rebalanceNotes: [
      "Volatile Marksman boost ICD removed",
      "Elemental Siphon grants 5% Super energy per matching pickup (was 3%)",
      "Vile Weave removes 4s from Tangle cooldown (was 1s)",
      "Flashover damage bonus cut to 50% (was 150%); Limit Break cut to 15% (was 30%)",
      "No Bell is additive melee stacking at 85% with +0.5s duration",
      "Gold from Lead proc rate roughly halved; Particle Reconstruction needs ~70% more shots to proc",
    ],
    bestFor: "Void/Strand ability-loop builds; Tangle and volatile economies.",
  },
  {
    name: "Implement of Curiosity",
    identity:
      "Elemental-pickup grid: Pack Tactics, Elemental Daze, Elemental Coalescence, Energy Acceleration, Solar Shrapnel, Elemental Overdrive, Iron Lord's Vigor.",
    rebalanceNotes: [
      "Pack Tactics duration up to 10s (was 7s)",
      "Elemental Daze blast damage down 25%",
      "Elemental Coalescence pickup chance up 20%",
      "Elemental Overdrive boost up to 22% (matches a 3x surge)",
      "Solar Shrapnel spawns like Horde Shuttle: better roaming, weaker vs bosses",
    ],
    bestFor: "Elemental-well style builds that chain pickups into damage windows.",
  },
  {
    name: "Encrypted Data Disc",
    identity:
      "Ammo/Super economy grid: Kinetic Ammo Synthesis, Payday, Snipers Meditation.",
    rebalanceNotes: [
      "Kinetic Ammo Synthesis heavy/Praxic Blade ammo generation halved",
      "Payday Super energy generation down 5%",
      "Snipers Meditation damage bonus down 5%",
    ],
    bestFor: "Kinetic-weapon and sniper DPS loadouts that lean on ammo uptime.",
  },
  {
    name: "NPA Repulsion Regulator",
    identity:
      "Strand/Void weaken grid: Improved Unraveling, Bricks from Beyond, Supernova, Lightning Strikes Twice.",
    rebalanceNotes: [
      "Improved Unraveling PvE damage bonus up to 15% (was 10%)",
      "Bricks from Beyond grants heavy-ammo bar progress instead of bricks",
      "Supernova PvE weaken lasts 8s (was 6s)",
      "Lightning Strikes Twice now works with the Grenade stat",
    ],
    bestFor: "Strand unravel builds and weaken-driven team damage setups.",
  },
];
