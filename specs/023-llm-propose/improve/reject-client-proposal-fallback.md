---
status: TODO
priority: P1
effort: S
risk: LOW
category: security
depends: []
planned_at: 799a9d6
issue: ""
---

# Reject client-supplied proposal replay on propose confirm

## Objective

When the in-memory propose pass is missing, `confirmProposals` rebuilds the pass from **client-supplied** `proposalsFallback` and then persists accepted synergies. Any signed-in client can POST crafted synergies through confirm without a prior server-side scan (or after TTL/HMR loss), bypassing propose-for-confirm integrity (DBR-LLM-002). After this lands, confirm only accepts proposals that the server still holds for that `passId` (or a cryptographically bound server-issued payload), and missing passes return 404 without writing synergies from client bodies.

## Current context

- `src/lib/llm/propose/confirmProposals.ts`
- `src/app/api/llm/propose-pass/[passId]/confirm/route.ts` forwards `parsed.data.proposals`
- Pass store: `src/lib/llm/propose/proposalStore` (in-memory)
- Domain: DBR-LLM-001–002 — LLM output is propose-for-confirmation of **model** output, not arbitrary client authoring via confirm
- Feature slice: `specs/023-llm-propose/`
- Verification: `npm run test`, `npm run typecheck`, `npm run lint`

```ts
// confirmProposals.ts:25-34
let pass = getProposePass(passId);
if (!pass && proposalsFallback && proposalsFallback.length > 0) {
  // Recover from lost in-memory pass (HMR / restart) using the scan response body.
  pass = {
    passId,
    createdAt: new Date().toISOString(),
    proposals: proposalsFallback,
  };
  saveProposePass(pass);
}
```

```ts
// confirm/route.ts:35-42
const result = await confirmProposals(
  getDb(),
  auth.user.id,
  passId,
  parsed.data.acceptedIds,
  parsed.data.skippedIds,
  parsed.data.proposals,
);
```

## Detailed instructions

### Requirements

- R1: Remove unconstrained client proposal replay: if `getProposePass(passId)` is missing, confirm fails with 404 (existing unknown-pass error class) and creates **zero** synergies.
- R2: Accepted ids may only resolve against server-stored proposals for that pass.
- R3: API may stop accepting `proposals` on the confirm body, or ignore the field; document the contract change in the 023 propose-confirm contract if it exists.
- R4: Optional hardening (in scope if small): bind pass to `userId` in the store so pass ids from another session cannot be confirmed.
- R5: UX for HMR/restart: client must re-run scan; error message already suggests re-scan — keep or clarify that message.
- R6: Tests: missing pass + malicious fallback does not call create synergy; happy path with server pass still creates on accept.

### Acceptance criteria

- [ ] Unit test: `confirmProposals` with missing pass and non-empty fallback throws/404 and does not create synergies
- [ ] Unit or route test: valid in-memory pass + acceptedIds still creates synergies
- [ ] `rg -n "proposalsFallback" src` shows no trust-client-rebuild path (or only typed deprecated no-op)
- [ ] `npm run test`, `npm run typecheck`, `npm run lint` pass

### Scope boundaries

**In scope**

- `src/lib/llm/propose/confirmProposals.ts`
- `src/app/api/llm/propose-pass/[passId]/confirm/route.ts`
- `src/lib/llm/propose/proposalSchemas.ts` (confirm body)
- `src/lib/llm/propose/proposalStore` (optional userId bind)
- Tests under `src/lib/llm/propose/`
- Contract doc under `specs/023-llm-propose/contracts/` if present

**Out of scope**

- Replacing in-memory store with SQLite durability (nice follow-on; not required)
- Changing scan/propose generation prompts
- Personal keyword persistence (still v1 no-op)

### Risks and notes

- Removing fallback worsens DX after dev server restart mid-confirm — message must tell users to re-scan.
- Do not weaken auth: confirm already requires `requireAuthenticatedUser`.
- Reviewer: ensure createUserSynergy cannot be reached with client-invented proposal bodies.