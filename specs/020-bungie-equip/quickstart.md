# Quickstart: Bungie Equip

**Feature**: 020-bungie-equip  
**Branch**: `020-bungie-equip`

## Setup

```bash
npx vitest run src/lib/builds/equip src/lib/bungie
npm run gate
```

## Validation

### V1 — Gate + character
Non-ready → 409; wrong class → 400; ready + matching character proceeds.

### V2 — Transfer/equip (mock)
Mock write client: transfer then equip steps recorded.

### V3 — Partial
Mid-fail leaves prior successes; status lists failures.

### V4 — Debug
Builds debug Equip with character picker shows status JSON.

## Gate

```bash
npm run gate
```
