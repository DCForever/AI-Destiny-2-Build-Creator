# Quickstart: DIM Export

## V1 — Gate

1. Wishlist-only variant → `POST …/dim-export` → 409 `NOT_EQUIP_READY`.
2. Equip-ready variant → proceeds past gate.

## V2 — Payload (jsonOnly)

1. Sign in; pick equip-ready variant with pins + optional fashion/artifact.
2. `POST …/dim-export` with `{ "jsonOnly": true }`.
3. Inspect `loadout.equipped` (hashes + ids), `parameters.mods`, fashion in `unequipped`, artifact in notes.

## V3 — Share

1. Set `DIM_API_KEY`; signed-in Bungie.
2. `POST …/dim-export` without jsonOnly → `{ shareUrl, loadout }`.
3. Without key → 503 (unless jsonOnly).

## V4 — Debug

1. Builds debug: Check DIM gate → Export to DIM → panel shows shareUrl/loadout.
