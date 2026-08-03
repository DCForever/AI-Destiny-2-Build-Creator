# Agent guide — monorepo root

This repository is a **multi-stack monorepo**. Read the stack-specific guide for the area you are changing.

| Area | Path | Agent guide |
| --- | --- | --- |
| Next.js web app | [`web/NextJS/`](web/NextJS/) | [`web/NextJS/AGENTS.md`](web/NextJS/AGENTS.md) |
| Dart / Flutter / Jaspr | [`flutter/`](flutter/) | [`flutter/AGENTS.md`](flutter/AGENTS.md) |
| Shared product / domain | [`specs/`](specs/), [`docs/`](docs/) | this file |

`CLAUDE.md` at repo root is `@AGENTS.md` (this file).

## Layout (do not undo)

```text
web/NextJS/     # Next.js app root (package.json, src/, scripts/)
flutter/        # Melos/pub workspace (packages/, apps/, tool/)
docs/           # product-map hub, atlas, multiplatform docs
specs/          # DBR/DAC/BR + Spec Kit feature slices
package.json    # thin npm proxy into web/NextJS only
```

- **Do not** put Next app source back at monorepo root.
- **Do not** put Dart packages outside `flutter/`.
- Shared docs and Spec Kit stay at monorepo root (`docs/`, `specs/`, `.specify/`).

## High-level product requirements (Obsidian)

Working product descriptions live in the **ProjectTracker** vault, not as duplicated bodies under `docs/products/`.

| | |
| --- | --- |
| Soft link | [`requirements/`](requirements/) → `C:\Users\Owner\SyncThing\Obsidian\ProjectTracker` |
| Recreate | `pwsh -File scripts/link-projecttracker-requirements.ps1` |
| **Read first for intent/scope** | `requirements/Projects/Destiny 2 Build Creator/` (`Products.md`, `Domains/`, `Areas/`, `Destiny Objects/`) |
| Git pointer | [`docs/products/README.md`](docs/products/README.md) |

When planning product behavior, check that folder for high-level requirements, then enforce via domain specs below.

## Domain & feature rules (always consult + keep current)

When **planning** or **implementing** product behavior (any stack):

1. **Read first** (domain wins on conflict):
   - High-level intent: `requirements/Projects/Destiny 2 Build Creator/` (if mount present)
   - [`specs/domain-business-rules.md`](specs/domain-business-rules.md) — `DBR-*`
   - [`specs/domain-acceptance-criteria.md`](specs/domain-acceptance-criteria.md) — `DAC-*`
   - [`specs/business-rules.md`](specs/business-rules.md) — `BR-*` (feature layer)

2. **Update those docs in the same change** when you ship or decide a product rule that is not already captured (new/changed DBR, DAC, BR; supersession notes; **Updated** date). Do not leave rules only in commits or chat. Vault product notes update when description meaning changes.

3. **Pure UI polish** (density, chrome collapse, viewport lock) stays out of domain P1/P2 gates unless it encodes product semantics — note trackers under `docs/` if needed.

4. Feature specs under `specs/00N-*/` and `specs/dart-*/` remain slice-level; still align them with domain when they contradict DBR/DAC.

## Product map / App Atlas (UI structure SSoT)

When **planning** or **implementing** user-visible UI (screens, tabs, modals, flows, gates) on **any** platform:

1. **Read / update** [`docs/product-map/`](docs/product-map/) in the **same change**:
   - `surfaces.yaml` — product places + `rules:` attachments + platform bindings
   - `flows.yaml` — journeys / subflows / phases
   - `transitions.yaml` — map edges
2. Rule **wording** still lives in domain markdown (above); hub holds **IDs** and structure only.
3. After hub edits: `npm run product-map:sync` from monorepo root (proxies into `web/NextJS`) or `cd web/NextJS && npm run product-map:sync`.
4. Scaffold: `npm run product-map:add-surface` / `product-map:add-flow`.
5. Checklist: [`docs/product-map/CHECKLIST.md`](docs/product-map/CHECKLIST.md).
6. Do **not** hand-edit generated `docs/ui-rules/ui-map.drawio`, `docs/ui-rules/inventory.yaml`, or generated Atlas path blocks — edit the hub and sync.
7. Multi-platform: same surface id; seed/update `platforms.flutter-windows` via `npm run product-map:seed-flutter` — do not fork DBR/DAC per platform. See [`docs/product-map/FLUTTER.md`](docs/product-map/FLUTTER.md).
8. Hierarchical flows: use `include`, `branch`, `loop`, and `gate` on phases so Atlas and Draw.io show nested subflows.
9. Flutter parity: `npm run product-map:parity` (report under `docs/product-map/parity-flutter-windows.md`).
10. **Gate / CI**: `npm run product-map:ci` runs on `npm run gate` and GitHub Actions — after hub edits always `product-map:sync` and commit generated `inventory.yaml`, `ui-map.drawio`, `manifest.json`, `ui-rules-links.json`. Skip with `GATE_SKIP_PRODUCT_MAP=1` only when necessary.

## Commands (monorepo root)

Root [`package.json`](package.json) **proxies** into `web/NextJS` (no Next deps at root):

| Command | Effect |
| --- | --- |
| `npm run dev` / `build` / `test` / `lint` / `typecheck` / `gate` | `npm --prefix web/NextJS run …` |
| `npm run product-map:*` | product-map / atlas scripts under `web/NextJS/scripts/` |

Dart / Flutter commands: **cwd must be `flutter/`** (see [`flutter/AGENTS.md`](flutter/AGENTS.md)).

## Spec Kit

- Config: [`.specify/`](.specify/)
- Feature slices: [`specs/`](specs/) (`00N-*` product, `dart-*` multiplatform, layout slices as needed)
- Default git base branch for new features: see `.specify/extensions/git/git-config.yml` (`base_branch`)

## Decisions & tracking

Structural layout decisions (e.g. `flutter/` nest, `web/NextJS` nest) belong in ProjectTracker decisions and, when durable for the port, [`docs/multiplatform-dart-port-decisions.md`](docs/multiplatform-dart-port-decisions.md).
