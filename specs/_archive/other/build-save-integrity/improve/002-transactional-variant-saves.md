---
status: DONE
priority: P1
effort: M
risk: MED
category: bug
depends:
  - characterization-hard-gates
planned_at: 799a9d6
issue: ""
---

# Commit build/variant attachment saves only after hard validation

## Objective

Variant attachment updates and related multi-step writes **mutate SQLite first**, then run `validateVariantSave`. If hard Destiny constraints fail, the API returns 4xx but illegal or torn rows already committed. Inventory sync already uses `db.transaction`. After this lands, equipment-affecting save paths either dry-run validate then commit atomically, or wrap prepare+validate so `ApiError` rolls back all intermediate writes.

## Current context

- `src/lib/builds/buildService.ts` — `createUserBuild`, `updateUserVariant`, `validateVariantSave`
- `src/lib/builds/attachmentService.ts` — `prepareAttachments` → immediate `replaceAttachments`
- `src/lib/db/repositories/variantRepository.ts` — attachment replace (delete-all + insert)
- Exemplar transaction: `src/lib/db/repositories/inventoryRepository.ts:8-89` `upsertInventoryBatch` uses `db.transaction`
- Domain: DBR-CMP-006/007, DBR-MOD-001, DBR-SUB-004 — illegal kits **cannot be saved**
- Progressive compose: bare create without attachments may skip full loadout (do not regress 028/029 Finish empty starts)
- Depends on sibling prompt **characterization-hard-gates** so gate behavior is locked before refactor
- Verification: `npm run test`, `npm run typecheck`, `npm run lint`, `npm run build`

```ts
// buildService.ts:605-626
updateVariantRecord(db, buildId, variantId, { /* ... */ now });
if (input.attachments) {
  await prepareAttachments(db, userId, variantId, input.attachments, now);
}
if (equipmentAffecting) {
  await validateVariantSave(db, userId, buildId, variantId);
}
```

```ts
// attachmentService.ts:35-74
export async function prepareAttachments(/* ... */) {
  // builds prepared list then:
  return replaceAttachments(db, variantId, prepared, now);
}
```

```ts
// inventoryRepository.ts:14
db.transaction((tx) => {
  // multi-step inventory replace — pattern to match
});
```

## Detailed instructions

### Requirements

- R1: For `updateUserVariant` when `equipmentAffecting` is true, if `validateVariantSave` throws `ApiError`, **no** attachment or equipment-affecting variant field changes from that request remain committed.
- R2: For `createUserBuild` when `defaultVariant.attachments` is provided, failed validation must not leave a partially attached illegal default variant (either full rollback of build+variant+attachments or documented delete-on-failure that leaves no orphan illegal state). Prefer single transaction.
- R3: `prepareAttachments` / `replaceAttachments` participate in the same transaction as validation, or validation runs against a planned attachment set before any delete/insert.
- R4: Non-equipment-affecting variant updates (name/notes only) need not run full equipment validation (preserve current short-circuit).
- R5: Create without attachments remains allowed (progressive Finish); do not force `assertFullCombatLoadout` on empty default create.
- R6: Public API status codes and error payloads for hard blocks stay compatible (`ApiError` codes).
- R7: Tests: at least one failure path proves attachments unchanged after rejected dual-exotic (or similar) update; at least one success path still commits.

### Acceptance criteria

- [ ] `npm run test` includes a regression that attempts illegal attachments and asserts DB state unchanged afterward
- [ ] Legal attach/update still succeeds and is visible via getBuildDetail / get attachments
- [ ] `npm run typecheck`, `npm run lint`, `npm run build` pass
- [ ] No requirement that bare `createUserBuild` without attachments fails completeness

### Scope boundaries

**In scope**

- `src/lib/builds/buildService.ts`
- `src/lib/builds/attachmentService.ts`
- `src/lib/db/repositories/variantRepository.ts` (transaction-friendly replace)
- Related create/duplicate paths in `variantService.ts` if they share validate-after-write
- Tests under `src/lib/builds/`

**Out of scope**

- Equip route / Bungie write path
- Changing domain exotic/mod rules themselves
- UI Finish walkthrough
- Full repository-layer transaction for every tag write unrelated to equipment

### Risks and notes

- better-sqlite3 transactions are synchronous; async validate that awaits manifest/entity cache may need validate-outside then commit-inside, or load cache before opening the transaction.
- Reviewer must scrutinize fork/duplicate paths for the same validate-after-write pattern.
- Sibling characterization tests should already be green before merging this.