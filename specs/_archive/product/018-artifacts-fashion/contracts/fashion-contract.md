# Contract: Fashion Sets & Attachment

## Fashion slots

Allowed `set_items.slot` values for `type=fashion`:

`shader_ornament` | `ghost` | `sparrow` | `ship` | `emblem` | `finisher`

Emotes / consumables → rejected.

## Attach

Variant attachments may include at most **one** set with `type=fashion`. Violations → `400`.

## Combat / soft guidance

Fashion items never appear in combat `equipment` claims, coverage tiers, or suggest-sets gap scoring (keep regression tests).
