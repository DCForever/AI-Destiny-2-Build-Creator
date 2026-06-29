# Contract: Debug/Service UI

**Type**: Internal verification surface (FR-033)

**Business rules**: [../../business-rules.md](../../business-rules.md)

## Scope

This iteration exposes **no production user-facing UI**. All manual verification uses **`/debug/*` pages** that call the same REST APIs documented in sibling contracts.

Production polished components (`SetEditor`, `BuildEditor`, catalog browse pages, nav) are **deferred**.

## Routes

| Path | Purpose |
|------|---------|
| `/debug/sets` | Set CRUD, tags, items, `confirmReplace` flow, mod-slot-empty hint |
| `/debug/builds` | Build/variant CRUD, attachments, synergies, tag filter, suggestions |
| `/debug/synergies` | Synergy CRUD, link pickers (hash/name inputs), reverse lookup test |
| `/debug/catalog` | Catalog filter `scope=all\|owned`, synergy badge preview (JSON) |
| `/debug/suggestions` | Explicit set/synergy/roll suggestion requests |

## Access Control

**Rules**: FR-033

- Requires authenticated user session (same as `/api/user/*`).
- When `NODE_ENV=production`, all `/debug/*` routes MUST return **404**.

Implement via `src/app/debug/layout.tsx` (or middleware) checking env + session.

## Page Requirements

Each debug page MUST include:

1. **HTML forms** — fields map 1:1 to API request bodies/query params.
2. **JSON panels** — show last request, response body, and error `{ code, details }`.
3. **Conflict UX for FR-027** — on `SLOT_OCCUPIED`, display message and resubmit control that sets `confirmReplace: true`.
4. **Stale indicator** — when API returns `stale: true` on SetItems, display visibly in JSON panel.

No design system, routing nav to production pages, or client-side state management beyond form submit.

## Validation

Manual validation follows [quickstart.md](../quickstart.md) using `/debug/*` in local dev (`npm run dev`, signed in).

See [set-attachment-contract.md](./set-attachment-contract.md), [build-variant-contract.md](./build-variant-contract.md), [synergy-contract.md](./synergy-contract.md).
