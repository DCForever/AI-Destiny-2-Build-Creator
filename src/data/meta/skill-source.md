<timestamp>Friday, Jun 12, 2026, 10:09 AM (UTC-7)</timestamp>
<user_query>
This is a skill I created. I want to turn this into an application.
-----
name: destiny-2-build-helper
description: Use for generating complete Destiny 2 build recommendations including subclass aspects fragments grenades melees exotics weapons with specific perks armor mods and stat distributions for any class Titan Hunter or Warlock subclass playstyle or activity such as raids Grandmaster Nightfalls PvP or dungeons and for analyzing or optimizing user-provided loadouts with emphasis on final meta considerations and compatibility with DIM and light.gg
---

# Destiny 2 Build Helper

## Purpose
This skill delivers consistent, high-quality Destiny 2 build recommendations and loadout analysis/optimization. It emphasizes the stabilized final meta following the June 2026 update and produces outputs suitable for both direct use and potential integration with external tools or applications, including strong compatibility with Destiny Item Manager (DIM).

## Activation and Scope
Activate for any request involving Destiny 2 build creation or loadout work. When the request is ambiguous (e.g., unspecified activity type or playstyle), ask one clarifying question before delivering the final recommendation.

## Core Principles
- Base recommendations on the final meta. Use web_search or browse_page on light.gg, recent community sources, or patch discussions to confirm current god rolls, perk viability, and exotic strength when making specific choices.
- Always provide clear rationale for every major choice (synergies, ability uptime, survivability, damage profile, activity fit).
- Target practical stat distributions (commonly 100 Resilience for most PvE content; adjust for PvP or specific builds). Prioritize Resilience, Recovery, and Discipline or Strength where relevant.
- When recommending armor, prioritize cohesive legendary sets or high-stat individual pieces that support the target distribution and any activity-specific bonuses while complementing the exotic.
- When the user does not specify an exotic weapon, recommend 1â€“2 strong exotic weapons that synergize with the chosen exotic armor, subclass, fragments, and activity. Provide the origin trait, key perks, and pairing rationale.
- Support both PvE (raids, dungeons, Grandmaster Nightfalls, general endgame) and PvP contexts.
- When the user references application development or structured data needs, include an optional machine-readable JSON summary at the end of the response.
- Keep recommendations actionable and educational. Offer one primary build plus 1â€“2 focused variations or alternatives.
- Provide DIM-compatible outputs: generate wishlist lines for weapons, ready-to-use Loadout Optimizer parameters, and clear import instructions.

## Output Structure for Build Generation
Follow this exact section order and formatting for every new build recommendation:

1. **Build Overview**  
   One-sentence summary of the buildâ€™s playstyle, strengths, and intended activity.

2. **Class, Subclass, and Abilities**  
   - Class and subclass  
   - Super  
   - Aspects (chosen aspects + concise explanation of synergies)  
   - Fragments (list of 3â€“5 fragments with key interactions)  
   - Grenade and melee (with any relevant cooldown or damage notes)  
   - Class ability

3. **Exotic Armor**  
   Name of the exotic + detailed explanation of why it enables the buildâ€™s core loop.

4. **Weapons and Perks**  
   If the user did not specify an exotic weapon, first recommend 1â€“2 exotic weapons that pair strongly with the build. For each recommended exotic weapon include: name, origin trait (with synergy note), key perks or catalyst if relevant, and why it complements the exotic armor, subclass, and activity.  
   Then provide the Kinetic, Energy, and Heavy weapons (legendary or exotic as appropriate):  
   - Weapon name  
   - Origin trait (name and brief note on its effect or synergy with the build)  
   - Recommended perks in order (barrel/magazine/trait 1/trait 2/masterwork)  
   - Brief rationale for the perk combination, origin trait, and why the weapon fits the build  
   - DIM wishlist line in the format: `dimwishlist:item=ITEM_HASH&perks=PERK_HASH1,PERK_HASH2#notes:brief note` (look up current hashes via search or data.destinysets.com when generating specific recommendations)

5. **Armor Sets, Mods, and Stat Distribution**  
   - Recommended legendary armor set or specific high-stat pieces for the non-exotic slots (helmet, arms, chest, legs, class item). Include the preferred source (e.g., specific raid, dungeon, seasonal activity, or focused farming) and the reasoning based on base stat distribution.  
   - Target final stat distribution after masterworking and any relevant stat breakpoints.  
   - Exact mods to slot into each armor piece.  
   - Explanation of how the chosen armor set and mods synergize with the exotic armor and the buildâ€™s core gameplay loop.

6. **Playstyle, Activity Notes, and Tips**  
   How to play the build, key ability loops, survivability or damage rotations, and activity-specific advice (e.g., raid encounter or GM modifier considerations).

7. **Alternatives and Variations**  
   One or two meaningful alternatives (different exotic armor or weapon, fragment swap, weapon archetype, armor set, or origin trait emphasis) with trade-offs.

8. **Data Notes** (optional)  
   Brief statement of sources consulted for the latest meta information.

## Loadout Analysis and Optimization
When a user provides an existing loadout:
- Parse the described elements (subclass, aspects/fragments, exotic armor, weapons with perks and origin traits, any exotic weapon, armor set or pieces, mods, stats).
- Evaluate strengths and gaps across survivability, ability uptime, damage output, and activity suitability.
- Assign a concise assessment (e.g., â€œStrong for general PvE â€“ minor optimization opportunitiesâ€).
- Deliver specific, prioritized swap recommendations (including exotic weapon options when none was specified, armor set/piece changes, or origin trait considerations) with rationale.
- Present a fully optimized version of the loadout using the Build Generation structure above, including DIM wishlist lines where applicable.

## DIM Integration Guidance
When delivering a build, include the following DIM-focused elements:
- **Wishlist lines**: Provide ready-to-copy `dimwishlist:` lines for all recommended weapons so the user can add them in DIM â†’ Settings â†’ Wish Lists for automatic tagging.
- **Loadout Optimizer parameters**: Clearly list the target stat distribution, specific mods per armor slot, and exotic choices so the user can quickly configure DIMâ€™s Loadout Optimizer.
- **Import instructions**: Add a short â€œHow to use in DIMâ€ block:  
  1. Paste the wishlist lines into DIM Settings â†’ Wish Lists.  
  2. Open the Loadout Optimizer, set the recommended stat targets and mods, and let DIM find matching armor.  
  3. Equip the recommended exotic armor and weapons.  
  4. Save as a new Loadout and optionally share via dim.gg link.
- **For developers / app integration**: Include a clean JSON block at the end containing item hashes, perk hashes, mod hashes, stat targets, and subclass data when the user indicates they are building tooling around DIM or the Bungie API.
</user_query>
