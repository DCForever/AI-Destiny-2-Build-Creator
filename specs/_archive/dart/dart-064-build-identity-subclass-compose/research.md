# Research: DART-064

**Date**: 2026-07-25

## Product parity sources

| Topic | Next.js evidence | Dart baseline |
| ----- | ---------------- | ------------- |
| Identity confirm/fork | `src/lib/builds/buildService.ts` `identityFieldsChanged` + `identityAction` + `forkBuildWithIdentity` | `updateUserBuild` mutates in place without identityAction (DART-032 deferred) |
| Exotic armor identity mode | `exoticArmorIntent.ts` class_item_intent non-identity swap | No mode helper yet |
| Subclass kit UI | SubclassTab / sheet subclass section + capacity | Domain `SubclassKit` + hard gates; hosts only `pinnedSuper` text |
| Manifest pickers | `ManifestSearchPicker.tsx` | Raw hash TextFields on Windows; Jaspr summary-only |
| Hard-block UI | VariantEditPanel hardBlocks plain language | Domain on save only |
| Jaspr attach | Named set search/attach + pin context | Free-text set id + first live pin only |

## Decisions

1. **Gate in app package** (not HTTP): in-process `UseCaseException` with `IDENTITY_CONFIRM_REQUIRED` mirrors API 409 semantics for hosts.
2. **Subclass kit changes count as identity** for Confirm/Fork when `subclass` payload differs (Assumption A2) — keeps kit mutations intentional.
3. **Client hard blocks** re-use pure domain evaluators; presentation helpers only format messages.
4. **Pickers** filter `CatalogItem` from OfflineCatalog / entity bundles — no new network; no CLIENT_SECRET.
5. **Jaspr** gets named set dropdown + per-slot pins; Windows already has named dropdown — residual was web only for GAP-UI-BUILD-09.

## Residual / PROC-06

- Icon rendering for Manifest hits may be text-only if icon URLs unavailable offline (fidelity polish → DART-068 if elevated).
- Class-item mode without armor row in catalog falls back to classic (identity-affecting).
