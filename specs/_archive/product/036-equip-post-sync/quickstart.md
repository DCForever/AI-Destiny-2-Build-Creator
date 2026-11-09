# Quickstart: Equip Post-Sync Reassert

## Verify

```bash
npm run test -- src/lib/builds/equipReady.test.ts src/lib/builds/equipPlan.test.ts
npm run typecheck
npm run lint
```

## Manual / API review

1. Equip-ready variant with all pins present after sync → plan executes as before.
2. Force inventory without a claimed instance after sync (fixture/mock) → 409 `NOT_EQUIP_READY`, no write client calls.
3. Confirm route order: sync → list inventory → recompute readiness → plan → execute.
