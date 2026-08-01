# Feature Specification: Nest Next.js under web/NextJS

**Feature Branch**: `045-nest-nextjs-web`
**Created**: 2026-08-01
**Status**: Implemented
**Input**: Move Next.js app into web/NextJS subfolder

## Scope

### In

- Relocate Next.js app root to `web/NextJS/`
- Move app configs, src, public, Next scripts
- Monorepo root keeps flutter/, docs/, specs/, shared product docs
- Thin root package.json orchestrator proxying npm scripts
- Fix product-map REPO_ROOT, CI, gitignore, dual-run paths, README
- Record structural decision

### Out

- Moving docs/specs/flutter
- Vercel project reconfig (document only)
- Product domain rule changes

## User Stories

### US1 Contributor runs Next (P1)

**Acceptance**: Next lives under web/NextJS; npm install/dev/build/test work from there; root proxy works if present.

### US2 Automation (P1)

**Acceptance**: CI and product-map:ci resolve monorepo docs/; dual-run markers use web/NextJS paths.

### US3 Docs (P2)

**Acceptance**: README getting-started documents web/NextJS (or root proxy).

## Requirements

- **FR-001**: Next app root MUST be web/NextJS/
- **FR-002**: flutter/, docs/, specs/ MUST remain monorepo root
- **FR-003**: product-map scripts MUST resolve monorepo root from nested location
- **FR-004**: CI MUST run Next quality gate against nested app
- **FR-005**: Developers MUST have documented run convention
- **FR-006**: Dual-run shell paths MUST reference web/NextJS package.json and src/app
- **FR-007**: Structural decision MUST be recorded

## Success Criteria

- **SC-001**: No live Next package.json/src at monorepo root (except optional root orchestrator without next dep)
- **SC-002**: typecheck/lint/test/build pass from web/NextJS
- **SC-003**: product-map:ci finds docs/product-map
- **SC-004**: flutter/ still has pub workspace

## Assumptions

- Folder name casing: NextJS
- Root orchestrator recommended
- Local .env.local/.cache moved manually by developer
