# Research: DART-046 Jaspr Compose Spine

## Decisions

### R1 — Reuse destiny2_app use cases (not reimplement domain)

- **Decision**: Controllers call `createUserBuild`, `updateUserVariant`, `queryVariantCoverage`, set/synergy CRUD from `packages/app`.
- **Rationale**: Hard/soft parity is already proven in DART-027/028 + Flutter UI slices.
- **Alternatives**: HTTP API to Next — rejected (D-IO pure Dart only).

### R2 — Local-library user for offline compose

- **Decision**: `ensureUser(bungieMembershipId: 'local-library')` when signed out (parity Flutter).
- **Rationale**: Compose must work without OAuth for CI and first-run intent.
- **Alternatives**: Require sign-in first — rejected (blocks exit criteria offline).

### R3 — Writer-only compose

- **Decision**: ComposeServices constructed only when `WebDatabaseBootstrap.database != null`.
- **Rationale**: Single-tab writer lock (DART-043); blocked tabs must not invent second writer.
- **Alternatives**: In-memory compose on blocked tab — rejected (diverges from local-first SQLite truth).

### R4 — Linear web density (not Windows dual-pane)

- **Decision**: Single-column sections on build compose (identity → variants → attachments/pins → soft).
- **Rationale**: Matches mobile reduced density; Jaspr DOM not Flutter dual-pane.
- **Alternatives**: Full dual-pane CSS — deferred polish.

### R5 — Soft display helpers copied to web_host

- **Decision**: Pure format helpers live under `lib/compose/` in web_host (same strings as mobile DART-041).
- **Rationale**: Avoid new shared package for this slice; keep shell-local display.
- **Alternatives**: Extract to `ui_tokens` — out of scope.

### R6 — Catalog remains DART-044 page

- **Decision**: No catalog rewrite; nav only.
- **Rationale**: Roadmap lists catalog as spine destination already shipped offline.

## Risks

| Risk | Mitigation |
| ---- | ---------- |
| jaspr_test cannot easily drive multi-step forms | Prefer controller unit tests for hard/soft parity; light component smoke |
| Default variant hard-gate on incomplete kit | Tests attach on non-default variants |
| Wasm DB unavailable in unit tests | Inject `AppDatabase.memory()` via ComposeServices |

## References

- Flutter mobile compose: `apps/mobile_host/lib/builds/*` (DART-041)
- Windows soft guidance: DART-034
- Use cases: `packages/app`
- Port decisions: `docs/multiplatform-dart-port-decisions.md`
