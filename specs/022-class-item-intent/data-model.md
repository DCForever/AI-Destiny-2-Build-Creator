# Data Model: Class-Item Intent Lock

## ExoticArmorIdentityMode

| Value | Meaning |
|-------|---------|
| `classic` | Item-hash locked exotic armor (015) |
| `class_item_intent` | Synergy/intent locked; variants may differ |

Derived (not necessarily persisted): from catalog slot of `builds.exoticArmorHash` and/or variant exotic class_item claims.

## Identity change matrix

| From → To | Confirm/fork? |
|-----------|---------------|
| classic hash A → classic hash B | Yes |
| class item A → class item B | No |
| classic ↔ class_item_intent | Yes |
| clear that flips mode | Yes |

## Perk config

Stored on set item / snapshot config for `class_item` slot: `selectedPerks: number[]` (+ optional `instanceId`). Flows into `SlotClaim.selectedPerks`.

## No new DB tables

Optional later: explicit `exoticArmorIntentMode` column — not required for v1 if derivation is reliable.
