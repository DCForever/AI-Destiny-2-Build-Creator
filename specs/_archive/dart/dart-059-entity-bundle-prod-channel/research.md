# Research: DART-059 Entity Bundle Prod Channel

**Date**: 2026-07-25  
**Slice**: DART-059

## Decisions

### R1 — Hybrid distribution (chosen channel)

**Decision**: Production web entity distribution is **hybrid**:

| Role | Mechanism |
| ---- | --------- |
| **Primary offline** | **Ship-in-app** same-origin static assets (`/entities/prod/bundle.json`) packaged with the Jaspr deploy |
| **Optional hot update** | **CDN** absolute URL in `channel.json` (or compile-time define) tried first when set |
| **Fallback** | On CDN failure → ship-in-app; if prod path missing → legacy `/entities/prebuilt/bundle.json` |

**Rationale**: Exit criteria demand offline Catalog after install (ship-in-app satisfies without SW complexity) and a production-hardened channel choice vs open ship-in-app vs CDN. Hybrid documents both and hardens loader ordering without requiring CDN ops on day one.

**Alternatives rejected**:

- **Ship-in-app only** — workable offline but no path for hot version bumps without full redeploy.
- **CDN only** — breaks “offline after install” unless a service worker caches the full bundle; larger ops surface for cutover.
- **Desktop-only full rebuild** — already architecture for raw tables; does not satisfy web Catalog offline.

### R2 — Channel pointer + bundle versioning

**Decision**: Two-layer versioning:

1. **`/entities/channel.json`** — points at active channel (`channelId`, `bundleVersion`, `distribution`, paths).
2. **Bundle body** — existing `EntityBundleDocument.manifestVersion` (+ `builtAt`, `counts`) must match or be compatible with pointer `bundleVersion`.

Operators bump `bundleVersion` when replacing `prod/bundle.json` (or CDN object). App code does not hard-code Destiny season ids.

### R3 — Prod path distinct from DART-044 fixture

**Decision**: Keep `web/entities/prebuilt/bundle.json` as **legacy/dev demo**. Production defaults:

- `web/entities/channel.json`
- `web/entities/prod/bundle.json` with `manifestVersion` like `entity-bundle-prod-1`

Repo sample prod bundle may remain small for CI; operators replace with full extract from desktop pipeline without changing channel schema.

### R4 — Pure channel types in `destiny2_manifest`

**Decision**: Put `EntityBundleChannel` + candidate URL resolution in `packages/manifest` (pure Dart, no `dart:io` / browser). Web host loader consumes it; tests run on VM.

### R5 — No Next manifest API; no browser raw rebuild

**Decision**: Entity load URLs are only same-origin `/entities/…` or optional absolute CDN. Compose continues on Drift OPFS + domain packages. Desktop Windows retains raw rebuild (DART-018).

### R6 — RC-WEB-DATA evidence

**Decision**: Clear RB-05 when: channel doc published, hybrid code + tests green, prod path shipped, cutover checklist RC-WEB-DATA **PASS**, GAP-WEB-02 closed. OPFS single-writer remains documented (DART-043).

## References

- DART-044: `specs/dart-044-jaspr-entity-bundles/`, `EntityBundleDocument`, `WebEntityBundleLoader`
- `docs/multiplatform-dart-web-opfs-limits.md` — prebuilt bundles on web
- GAP-WEB-02 / RB-05 / RC-WEB-DATA
