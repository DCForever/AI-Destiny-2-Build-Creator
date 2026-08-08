# UX brief: catalog / WeaponInstanceStrip

**Status:** locked  
**Date:** 2026-08-06  
**Hosts:** windows, widgetbook  
**Slice goal:** Close dual-truth for `WeaponInstanceStrip` vs approved component mockups  
**Out of scope:** Full Catalog redesign; perk grid; meta strip; filter bar; invent MW/Craft on chip; invent tier/special when data unknown  

## Product posture

- Job: disambiguate owned weapon copies (power, gear tier, version specialness) and select which copy drives detail  
- Rule IDs: BR-CAT-016*, DBR-UI-001/005/006/007, DBR-ROLL-001/010  

## Locked decisions

| Topic | Decision |
| --- | --- |
| Chrome | Custom Flap pressable chip — not Material ChoiceChip |
| Label | `{power} T{tier} {special?}` e.g. `335 T3 Adept` |
| No on chip | MW, Craft |
| Tier | Show `T1`–`T5` only when `gearTier` known |
| Special | Show only when known (Adept, Holofoil, …) |
| Layout | Multi-row **wrap** (prefer wrap over H-scroll at 400 detail) |
| Order | Power-desc; default highest power |
| Empty | “No local copies”; unowned does not mount strip |
| Selected | Accent wash + inset left accent bar |

## Mockups (approved)

- `docs/ux-redesign/catalog/mockups/002-weapon-instance-strip-desktop.html`
- `docs/ux-redesign/catalog/mockups/002-weapon-instance-strip-mobile.html`
- `docs/ux-redesign/catalog/MOCKUP-APPROVED.md`

## Implement notes

- `WeaponInstanceStrip` in `catalog_weapon_detail.dart` (or extract sibling file)
- Optional presentation field for specialness on projection when host knows version
- Widgetbook knobs: empty, count, power, step, tier, special
- Tests: no ChoiceChip; wrap; tier/special segments; empty key

## Widgetbook

- Keep **Instance strip multi-PL** + **All knobs · instance strip**
