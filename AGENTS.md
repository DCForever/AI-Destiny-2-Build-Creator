<!-- BEGIN:nextjs-agent-rules -->
# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` before writing any code. Heed deprecation notices.
<!-- END:nextjs-agent-rules -->

## Domain & feature rules (always consult + keep current)

When **planning** or **implementing** product behavior:

1. **Read first** (domain wins on conflict):
   - [`specs/domain-business-rules.md`](specs/domain-business-rules.md) — `DBR-*`
   - [`specs/domain-acceptance-criteria.md`](specs/domain-acceptance-criteria.md) — `DAC-*`
   - [`specs/business-rules.md`](specs/business-rules.md) — `BR-*` (feature layer)

2. **Update those docs in the same change** when you ship or decide a product rule that is not already captured (new/changed DBR, DAC, BR; supersession notes; **Updated** date). Do not leave rules only in commits or chat.

3. **Pure UI polish** (density, chrome collapse, viewport lock) stays out of domain P1/P2 gates unless it encodes product semantics — note trackers under `docs/` if needed.

4. Feature specs under `specs/00N-*/` remain slice-level; still align them with domain when they contradict DBR/DAC.

## Cursor Cloud specific instructions

Single Next.js 16 app (App Router, React 19, TypeScript, Tailwind v4), package manager **npm**. Dependencies (incl. native `better-sqlite3`) are installed by the startup update script (`npm install`); no Docker/DB server is needed — SQLite lives at `.cache/app.db` and is created on first write.

Standard commands are in `README.md` / `package.json` scripts: `npm run dev` (HTTP :3000), `npm run dev:https` (:3000 over HTTPS, only needed for real Bungie OAuth), `npm run lint`, `npm run typecheck`, `npm run test` (Vitest), `npm run build`, `npm run gate` (typecheck+lint+test+build via `scripts/gate.sh`).

Non-obvious caveats:

- **`.env.local` is required for auth but not for the server to boot.** Copy `.env.local.example` → `.env.local` and set a `SESSION_SECRET` of **32+ chars** (otherwise `getSession()` throws on any auth route). The file is gitignored and not created by the update script.
- **Almost every write/UI flow is gated behind a Bungie session, and most read/create UI needs the downloaded manifest.** Full functionality (catalog browse, synergy/set/build creation *with links*, inventory, equip) requires a real `BUNGIE_API_KEY` (manifest download) and, for sign-in, a Bungie OAuth app (`BUNGIE_CLIENT_ID`/`BUNGIE_CLIENT_SECRET`) served over HTTPS at `https://127.0.0.1:3000`. LLM features need a local LLM (LM Studio/Ollama :1234/:11434) or `XAI_API_KEY`. None of these secrets are present by default — treat them as user-provided.
- **Manifest-free smoke test of the full stack:** the library CRUD API (`/api/user/synergies`, `/api/user/builds`, `/api/user/sets`) only needs a valid session + SQLite. A synergy of a type that takes no subtype (e.g. `dps`) or a `verb`/`element` with a valid subtype can be created via a direct authenticated `POST` without the manifest. The **UI** create form additionally requires ≥1 catalog link (manifest-gated), but `Delete`/list/detail work without the manifest.
- Known pre-existing (not caused by setup): `npm run lint` reports ~14 errors and `npm run test` has 4 failing tests (in `legendaryArmor.test.ts` and `attachmentService.test.ts`); `typecheck` and `build` are clean.
- `serverExternalPackages: ["better-sqlite3"]` in `next.config.ts` — do not bundle it. If the dev DB gets corrupted after a hot reload, delete `.cache/app.db*` and re-create.
- `DEBUG.md` is the canonical operator guide for `/debug/*` flows and Bungie/manifest prerequisites.
