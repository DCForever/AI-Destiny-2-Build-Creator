# Plan: 039 Transactional variant saves

## Summary

Stop validate-after-write on equipment-affecting variant/build attachment paths. Plan attachments and variant field patches asynchronously, run `validateVariantSave` against the **planned** state (read-only), then commit `updateVariantRecord` + `replaceAttachments` inside `db.transaction` (inventoryRepository exemplar). On create-with-attachments failure, delete the new build so no illegal orphan remains.

## Approach

1. Split `attachmentService`: `planAttachments` (no write) + `prepareAttachments` = plan then replace (compat).
2. Extend `validateVariantSave` with optional `attachments` override and `variantPatch` for dry-run against planned equipment.
3. `updateUserVariant`: resolve artifact + plan attachments → if equipmentAffecting, validate planned → `db.transaction` write variant + attachments.
4. `createUserBuild`: create build+variant; if attachments, plan → validate planned → replace or `deleteBuildRecord` on failure.
5. `createUserVariant` duplicate: same plan → validate → replace or delete variant on failure.
6. Regression: illegal attach leaves attachments empty / prior set unchanged.

## Files

- `src/lib/builds/attachmentService.ts`
- `src/lib/builds/buildService.ts`
- `src/lib/builds/variantService.ts`
- `src/lib/builds/buildService.test.ts`
- Specs under `specs/039-transactional-variant-saves/`

## Risks

- better-sqlite3 transactions are sync — all async/cache work stays outside the transaction.
- Do not force full loadout on bare create.
