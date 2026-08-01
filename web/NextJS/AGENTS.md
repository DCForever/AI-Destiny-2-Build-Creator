# Agent guide — Next.js (`web/NextJS`)

Parent monorepo rules: [`../../AGENTS.md`](../../AGENTS.md) (domain DBR/DAC/BR + product-map). **Read the parent first** for product behavior and UI structure SSoT.

<!-- BEGIN:nextjs-agent-rules -->
# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` **in this directory** before writing any code. Heed deprecation notices.
<!-- END:nextjs-agent-rules -->

## App root

- **Package root:** this directory (`web/NextJS/`).
- **Do not** assume `package.json` / `src/` live at monorepo root.
- From monorepo root you may use `npm run <script>` (proxy). From here: `npm run <script>` directly.
- Cache and env for this app: `.cache/`, `.env.local` under **this** directory (`process.cwd()`). Do not symlink monorepo-root `.cache` into this tree (Turbopack rejects out-of-root symlinks).

## Layout (this app)

```text
src/app/           # App Router routes + API
src/components/    # production UI
src/lib/           # domain services, bungie, manifest, db, …
src/data/          # sandbox tables, vocab
public/            # static assets (incl. destiny-icons)
scripts/           # gate, product-map, atlas (REPO_ROOT walks to monorepo)
```

Path alias: `@/*` → `./src/*` (`tsconfig.json`).

## Quality gates

From **this directory** (or monorepo root proxy):

```bash
npm run typecheck
npm run lint
npm run test
npm run build
npm run gate          # product-map:ci → typecheck → lint → test → build
```

CI (`.github/workflows/ci.yml`) uses `working-directory: web/NextJS`.

## Product-map / scripts

- Scripts under `scripts/product-map/` and `scripts/ui-rules/` resolve **monorepo root** via walk-up (`docs/product-map` + `flutter` or `.git`), not via a fixed number of `..` only.
- Generated outputs still land in monorepo `docs/ui-rules/` and `docs/atlas/`.
- After hub edits: `npm run product-map:sync` and commit generated files with the hub.

## Next-specific constraints

- **SQLite:** single-process local use (`better-sqlite3`). Not Edge/serverless multi-worker.
- **Bungie OAuth (this stack):** Confidential client + httpOnly session (see monorepo `README.md` / `.env.local.example`). Secrets stay server-only — never ship `BUNGIE_CLIENT_SECRET` / `SESSION_SECRET` to the client bundle.
- **Soft vs hard:** soft suggestions never auto-apply; hard blocks only where domain says so (DBR/DAC).
- Prefer production surfaces under `src/app/{build,sets,synergy,catalog,loadouts,settings}`; keep `/debug/*` operator-only.

## When touching Flutter / Dart

Stop and open [`../../flutter/AGENTS.md`](../../flutter/AGENTS.md). Do not invent parallel domain rules per stack.
