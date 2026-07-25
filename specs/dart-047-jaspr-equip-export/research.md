# Research: DART-047 Jaspr Equip Export

## Decisions

### R1 — Same domain packages as Flutter (no reimplementation)

- **Decision**: Use `destiny2_domain` (`computeEquipReady`, `assertEquipReady`, `buildJsonOnlyDimExport`, `planEquipSteps`) and `destiny2_bungie` (`executeEquipPlan`, `BungieWriteClient`, `BungieProfileClient.getCharacters`).
- **Rationale**: Roadmap exit criterion; parity with DART-038/039.
- **Alternatives**: Re-code gates in web_host — rejected (drift risk).

### R2 — Surfaces on Build compose (not new routes)

- **Decision**: Equip + DIM sections on `/builds/:buildId` linear compose page.
- **Rationale**: Matches Flutter Builds detail placement; nav already has Builds.
- **Alternatives**: Dedicated `/equip` route — unnecessary for this slice.

### R3 — Optional equip (sign-in + clients)

- **Decision**: Equip path requires `WebOAuthSession` signed-in + injectable profile/write clients. DIM works offline (equip-ready + local inventory only).
- **Rationale**: Spec “optional equip”; jsonOnly needs no network.
- **Alternatives**: Require sign-in for DIM — rejected (Flutter DART-039 parity).

### R4 — Inventory without full sync UI

- **Decision**: Readiness uses `listInventoryItems` from local Drift. Tests seed inventory. Production may call `syncIfStale` before equip when clients available; no new Settings inventory card in this slice.
- **Rationale**: Depends DART-046/037/010, not web inventory sync UI.
- **Alternatives**: Block equip until web sync UI — would expand scope.

### R5 — Shell-local format helpers

- **Decision**: Copy/adapt display helpers under `lib/equip/` and `lib/dim_export/` (same strings as Windows).
- **Rationale**: Avoid new shared package; shell-local like DART-046 compose formats.

### R6 — Injectable clipboard + mock write

- **Decision**: `DimClipboardWriter` typedef; default browser clipboard; tests capture text. Equip uses `createMockWriteClient` in tests.
- **Rationale**: CI without browser clipboard permissions or live Bungie.

## Risks

| Risk | Mitigation |
| ---- | ---------- |
| Empty inventory → never equip-ready in real browser until sync | Document; seed in tests; optional syncIfStale on equip |
| Browser clipboard permissions | Injectable writer; status on failure |
| Class name casing (Hunter vs hunter) | Use same CharacterSummary.classType strings as Flutter fakes |

## References

- Windows equip: `apps/windows_host/lib/equip/*` (DART-038)
- Windows DIM: `apps/windows_host/lib/dim_export/*` (DART-039)
- Domain: `packages/domain` equip_ready, dim_builders, equip_plan
- Orchestrator: `packages/bungie` write/equip_orchestrator
- Port decisions: `docs/multiplatform-dart-port-decisions.md`
