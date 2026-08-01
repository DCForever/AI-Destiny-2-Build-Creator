# Agent guide — Dart / Flutter / Jaspr (`flutter/`)

Parent monorepo rules: [`../AGENTS.md`](../AGENTS.md) (domain DBR/DAC/BR + product-map). **Read the parent first** for product behavior and UI structure SSoT.

## Workspace root

- **Pub / Melos workspace root:** this directory (`flutter/`).
- Run Dart commands with **cwd = `flutter/`**:

```bash
cd flutter
dart pub get
dart run tool/p0_parity_gate.dart
dart analyze   # or melos scripts from pubspec.yaml
```

- Hosts: `cd apps/windows_host` | `apps/mobile_host` | `apps/web_host` as needed.
- Jaspr `apps/web_host` is **not** a root pub workspace member (analyzer pin); resolve with `dart pub get` inside `apps/web_host`.

## Layout

```text
pubspec.yaml           # workspace: + melos: scripts
packages/              # domain, sandbox_data, storage, db, manifest, bungie, app, ui_tokens, ui_flutter
apps/
  windows_host/        # Flutter Windows
  mobile_host/         # Flutter mobile
  web_host/            # Jaspr web
tool/                  # gates (P0, graph guard, cutover, dual-run, …)
```

Package map and purity rules: [`packages/README.md`](packages/README.md).  
Architecture decisions: [`../docs/multiplatform-dart-port-decisions.md`](../docs/multiplatform-dart-port-decisions.md).  
Slice roadmap: [`../docs/multiplatform-dart-slice-roadmap.md`](../docs/multiplatform-dart-slice-roadmap.md).

## Purity & layering (non-negotiable)

- **`packages/domain`** and **`packages/sandbox_data`**: pure Dart — **no** Flutter, Jaspr, Drift, http, path_provider, or other IO/UI runtime deps. Enforced by `dart run tool/pure_package_graph_guard.dart` / P0 gate.
- **IO / Drift / Bungie HTTP** live in dedicated packages (`storage`, `db`, `manifest`, `bungie`, …).
- **UI:**
  - Tokens / layout contracts: `packages/ui_tokens` (no Flutter widgets).
  - Flutter widgets/theme: `packages/ui_flutter` + hosts.
  - Jaspr: `apps/web_host` maps tokens to CSS — not Flutter Web as product target.
- Soft guidance never auto-applies; hard blocks only per DBR/DAC.

## Auth / secrets

- Dart shells: **Public + PKCE** only. **Never** embed `BUNGIE_CLIENT_SECRET` or `SESSION_SECRET` in Flutter/Jaspr.
- Scan: `dart run tool/client_secret_scan.dart` (from this workspace root).
- Next.js confidential OAuth is a **different** stack (`web/NextJS`); do not copy confidential patterns into clients.

## Gates & tools

From **`flutter/`**:

| Command | Purpose |
| --- | --- |
| `dart run tool/p0_parity_gate.dart` | Pure graph guard + pure package tests |
| `dart run tool/pure_package_graph_guard.dart` | Forbidden deps on pure packages |
| `dart run tool/dual_run_ops_gate.dart` | Dual-run structural markers (paths relative to **monorepo** root) |
| `dart run tool/production_cutover_regate.dart` | Cutover re-gate (see docs) |

Dual-run Next paths are monorepo-relative, e.g. `web/NextJS/package.json`, `web/NextJS/src/app` (not repo-root `src/`).

`findWorkspaceRoot` in tools resolves this Melos root and also accepts monorepo root when a nested `flutter/` workspace exists.

## Product map / UI parity

- Same surface IDs as Next; do not fork DBR/DAC per platform.
- Flutter Windows stubs / parity: [`../docs/product-map/FLUTTER.md`](../docs/product-map/FLUTTER.md).
- Hub edits still go through monorepo `docs/product-map/` + `npm run product-map:sync` (Next scripts).

## Spec Kit slices

- Multiplatform slices: monorepo `specs/dart-*/`.
- Layout nests: e.g. `specs/dart-069-nest-flutter-workspace/`, `specs/045-nest-nextjs-web/`.
- Implement against domain docs first; keep pure packages testable without device/UI.

## When touching Next.js

Stop and open [`../web/NextJS/AGENTS.md`](../web/NextJS/AGENTS.md). Shared product rules stay in monorepo `specs/` — implement in the correct stack, do not duplicate rule text only in Dart.

## Specialized Grok Build Agents

Local multi-agent roles live under [`.grok/agents/`](.grok/agents/). When using Grok Build multi-agent workflows inside this workspace:

- **Always** honor the purity rules, Melos root (`flutter/`), and package boundaries defined above.
- **product-manager** owns scope and acceptance criteria against the product-map / DBR/DAC.
- **flutter-architect** owns structural and layering decisions.
- **flutter-implementor** writes code within existing package boundaries; pair with a simplicity mindset.
- Desktop UI and Web UI work must respect the existing token → Flutter / Jaspr mapping.
- Never introduce Flutter/Jaspr/IO dependencies into pure packages (`domain`, `sandbox_data`).
- Never embed secrets; Public + PKCE only.

Prefer spawning focused subagents rather than asking a single session to hold the entire context.
