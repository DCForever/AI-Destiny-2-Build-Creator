# Contract: Desired Roll & Instance Pin Persistence

**Feature**: 016-wishlist-equip-ready  
**Related**: [data-model.md](../data-model.md)

## Desired roll

Set item upsert MAY omit `instanceId`. Required: `itemHash` (+ plugs as applicable). Save MUST succeed without ownership.

## Pin write

Set item upsert MAY include `instanceId` of an owned copy. Desired roll fields MUST be retained when pinning.

## Snapshot / resolve

`SnapshotConfig` and resolved `SlotClaim` MUST include optional `instanceId` when present on the source set item (live or frozen snapshot).
