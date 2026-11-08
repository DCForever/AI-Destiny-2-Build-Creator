# Implementation Plan: Reject client proposal fallback on confirm

**Branch**: `037-reject-proposal-fallback` | **Date**: 2026-07-23 | **Spec**: `specs/037-reject-proposal-fallback/spec.md`

## Summary

Remove the client `proposalsFallback` rebuild in `confirmProposals` so missing passes always 404 with zero synergy writes. Drop `proposals` from the confirm request contract and clients. Bind stored passes to creating `userId` and reject cross-user confirm as unknown pass. Cover malicious fallback and happy path in unit tests; update 023 contract docs.

## Technical Context

**Language/Version**: TypeScript / Next.js 16 (App Router)  
**Primary dependencies**: Zod, Vitest, better-sqlite3 test DB helpers  
**Storage**: In-memory `proposalStore` (globalThis); synergies via `createUserSynergy`  
**Testing**: Vitest unit tests under `src/lib/llm/propose/`  
**Target platform**: Node.js API routes  
**Constraints**: Heed `AGENTS.md` / Next.js 16 local docs; no main-tree edits  
**Scale/Scope**: Small security fix across propose confirm path + two debug clients

## Constitution Check

- Small increment: yes (confirm path + store bind + tests/docs)
- Test-first intent: replace insecure fallback test with reject test; keep happy path
- Green commits: typecheck, lint, relevant tests before finish

## Project Structure

### Documentation

```text
specs/037-reject-proposal-fallback/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── tasks.md
├── contracts/propose-confirm-contract.md
└── checklists/requirements.md
```

### Source

```text
src/lib/llm/propose/confirmProposals.ts   # remove fallback rebuild; user bind check
src/lib/llm/propose/proposalStore.ts      # optional userId on StoredProposePass
src/lib/llm/propose/proposalSchemas.ts    # drop proposals from confirm body
src/lib/llm/propose/runProposePass.ts     # pass userId into store
src/lib/synergies/runGapScan.ts           # pass userId into store
src/app/api/llm/propose-pass/route.ts     # forward auth.user.id
src/app/api/llm/propose-pass/[passId]/confirm/route.ts
src/app/debug/** (stop sending proposals on confirm)
src/lib/llm/propose/proposePass.test.ts
specs/023-llm-propose/contracts/propose-confirm-contract.md
```

## Complexity Tracking

None — no constitution violations.
