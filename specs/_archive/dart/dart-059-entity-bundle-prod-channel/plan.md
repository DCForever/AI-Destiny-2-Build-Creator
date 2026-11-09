# Implementation Plan: DART-059 Entity Bundle Prod Channel

**Branch**: `dart-059-entity-bundle-prod-channel` | **Date**: 2026-07-25 | **Spec**: [spec.md](./spec.md)

**Input**: Feature specification from `/specs/dart-059-entity-bundle-prod-channel/spec.md`

## Summary

Harden web entity distribution as **hybrid** (ship-in-app primary + optional CDN) with a versioned channel pointer. Extend pure manifest package with channel parse/resolve; upgrade Jaspr loader to try ordered candidates and report load source; ship prod static assets; document channel; clear RB-05 / RC-WEB-DATA PASS and close GAP-WEB-02.

## Technical Context

**Language/Version**: Dart 3.x  

**Primary Dependencies**: `destiny2_manifest`, Jaspr web host (`apps/web_host`)  

**Storage**: Static web assets under `apps/web_host/web/entities/`; no SQLite for entity defs on web  

**Testing**: `dart test` in `packages/manifest` and `apps/web_host`  

**Target Platform**: Jaspr web (browser); pure channel logic VM-testable  

**Project Type**: Pure package + web host hardening  

**Performance Goals**: Single JSON fetch (or CDN then fallback) at Catalog bootstrap; offline after assets installed  

**Constraints**: No browser raw rebuild; no Next manifest API; no CLIENT_SECRET; pure Dart I/O  

**Scale/Scope**: Channel schema + loader + sample prod bundle + docs/cutover updates only (not full live Destiny catalog size)

## Constitution Check

- I. Small Testable Increments: US1 channel types → US2 loader/prod assets → US3 docs/cutover.
- II. Test-First: channel + loader tests before/with implementation.
- III. Green Commit Checkpoints: tests green before merge.
- Soft never auto-applies; no secrets.

## Project Structure

### Documentation (this feature)

```text
specs/dart-059-entity-bundle-prod-channel/
├── plan.md
├── research.md
├── quickstart.md
├── spec.md
├── checklists/requirements.md
└── tasks.md
```

### Source Code

```text
packages/manifest/lib/src/entity_bundle_channel.dart   # NEW channel types + resolve
packages/manifest/lib/destiny2_manifest.dart           # export
packages/manifest/test/entity_bundle_channel_test.dart # NEW
apps/web_host/lib/catalog/entity_bundle_loader.dart    # channel-aware load
apps/web_host/lib/main.client.dart                     # default channel URLs
apps/web_host/web/entities/channel.json                # NEW
apps/web_host/web/entities/prod/bundle.json            # NEW prod sample
apps/web_host/test/entity_bundle_loader_test.dart      # extend
docs/multiplatform-dart-entity-bundle-channel.md       # NEW decision doc
docs/multiplatform-dart-cutover-parity-checklist.md    # RB-05 / RC-WEB-DATA
docs/multiplatform-dart-feature-gaps.md                # GAP-WEB-02 closed
docs/multiplatform-dart-slice-roadmap.md               # DART-059 done
docs/multiplatform-dart-web-opfs-limits.md              # point at prod channel
docs/multiplatform-dart-port-decisions.md              # close open channel item
```

## Implementation approach

1. **Pure channel model** — `EntityBundleChannel.fromJson`, `EntityBundleDistribution`, `resolveEntityBundleCandidates`.
2. **Loader** — optional channel fetch URL; try candidates; set `loadSource` on status; default prod paths.
3. **Assets** — `channel.json` + `prod/bundle.json` with `entity-bundle-prod-1`.
4. **Docs + cutover** — decision doc; RC-WEB-DATA PASS; RB-05 cleared; GAP closed; roadmap next DART-060.

## Complexity Tracking

None — extends existing DART-044 loader; no new runtime platforms.
