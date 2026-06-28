# Overhaul Plan

## Goals

1. Create, edit, view, and delete Destiny 2 builds
2. View all weapons and quickly filter them 
3. View all my weapons and quickly filter them
4. View all sets of armor and quickly filter them
5. View all my armor and quickly filter them
6. Categorize builds, weapons, armor with **concept tags** from a controlled Destiny vocabulary (PVE, PVP, Solar, Melee, Grandmaster, etc.)
7. Create sets of items to help create builds
   1. Tag each set with one or more concept tags (e.g. name `Ferropotent`, tags `[Melee, Solar, PVE]`) — filter by tag combination when attaching to builds
   2. Sets of Weapons
   3. Sets of Armor
   4. Sets of Mods
   5. Exotic Weapon & Exotic Armor pairs
   6. Fashion Sets
8. Create, edit, view, and delete synergies
   1. Melee synergies
   2. Destiny 2 Verb synergies
   3. Grenade synergies
   4. Primary Weapon Synergies
   5. Special Weapon Synergies
   6. Heavy Weapon Synergies
   7. Kinetic Weapon Synergies
   8. Super synergies
   9. Damage Synergies
   10. Healing Synergies
   11. Interlligently Generated Synergies

## Capabilities

- Combine sets inteligently to create builds
  - Example: I want a build that is going to use the Felwinters Helm + Monte Carlo set for a Melee focused build. It should suggest that I use one of the Melee synergized Armor sets and Melee synergized Weapon sets
- Suggest weapon rolls to hunt for that would also be good for a synergy or build
- Support hundreds of builds and sets, but quickly support finding similar builds Melee focused or Weapon Focused or a specific exotic used
  - I want to have a multiple build for each exotic where only some of the sets differ
    - Example: I want several builds that use Vex Mythoclast, but one might be healing and survivablity while another might be a DPS focused build

## Relationships
1. A set can have 1 or 0 of the following: helmet, arms, chest, legs, class item, primary slot weapon, special slot weapon, heavy slot weapon
2. A build has at least 1 of the following: helmet, arms, chest, legs, class item, primary slot weapon, special slot weapon, heavy slot weapon. This would be the default variant of sets. A single build will have the same subclass and aspects through out all variants. A build will have at least one focused synergy that will help guide suggestions.
   1. A build can have variants which have different sets than the default.
3. A build variant has at least 1 of the following: helmet, arms, chest, legs, class item, primary slot weapon, special slot weapon, heavy slot weapon before it can be saved.
 