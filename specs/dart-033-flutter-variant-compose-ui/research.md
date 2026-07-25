# Research: DART-033 Flutter Variant Compose UI

**Date**: 2026-07-24  
**Slice**: DART-033

## Decisions

### R1 — Compose on Builds detail (not new nav)

Reuse DART-032 Builds dual-pane. Identity remains above; variant compose is a second section on the selected build. Matches product spine (build → variants → attachments) without another NavigationRail destination.

### R2 — Attach via `updateUserVariant` + full attachment list

Product/DART-028 order: replace attachments then `validateVariantSave` (slot conflicts → exotic limits → mod energy → default completeness) with rollback. UI builds the next `List<SetAttachmentInput>` (existing + add, or minus detach) and calls `updateUserVariant`. Do not call `prepareAttachments` alone without validation for equipment-affecting UX.

### R3 — Live mode default

Sets library is the source of truth for items; live attachments re-read active set items. Snapshot mode available in use cases but not required for exit criteria.

### R4 — Pin slot = set item `instanceId`

Wishlist vs instance is the presence of `instanceId` on expanded claims / set items (domain `SlotClaim` + DART-030 fill). Compose “pin slot” updates the live-attached set’s item via `upsertUserSetItem` (same as Sets library fill, without requiring catalog dialog — tests pass instance id string). Full equip-ready inventory stale checks remain available in domain but are not required UI this slice.

### R5 — Conflict surfacing

Map `UseCaseException` (`UseCaseErrorCode.slotConflict` / message) to status banner. Use case already rolls back attachments on failure — UI only displays the error.

### R6 — No soft auto-apply

Soft coverage (DART-034) is out of scope; hard blocks only.

## Dependencies confirmed

- DART-032 Builds page + controller + local-library user resolve
- DART-030 sets with optional instance pins
- DART-027/028 `createUserVariant`, `updateUserVariant`, `prepareAttachments`, `expandAttachmentsToItems`, `getVariantAttachments`

## Alternatives rejected

- Separate “Compose” nav page — extra shell surface for thin slice.
- Editing snapshot configs in UI — heavier; live is enough for P3 compose gate path.
- Auto-resolve slot conflicts by dropping one set — domain is hard-block; must surface, not auto-apply.
