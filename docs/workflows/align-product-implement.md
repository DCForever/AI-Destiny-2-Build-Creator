# Workflow: align-product-implement (multiplatform-dart)

**Script**: [`.grok/workflows/align-product-implement.rhai`](../../.grok/workflows/align-product-implement.rhai)

**Repo**: `F:\Destiny2BuildCreator-multiplatform-dart` (Melos monorepo — Dart packages + host apps; residual Next `src/` for parity reference only).

Closes the loop from **product domain requirements → ranked packages → implement → verify**, adapted for multiplatform Dart gap ledgers (`GAP-*`, `DART-NNN`).

## When to use

- “What’s left vs DBR/DAC/BR on Dart?”
- “Next DART slice / feature gap package”
- After re-syncing domain markdown or running dual-use, before a coding session

## Domain SSoT (AGENTS.md + port ledgers)

| Layer | Path | IDs |
| --- | --- | --- |
| Domain rules | `specs/domain-business-rules.md` | `DBR-*` |
| Acceptance | `specs/domain-acceptance-criteria.md` | `DAC-*` |
| Feature rules | `specs/business-rules.md` | `BR-*` |
| Product purpose | `PRODUCT.md` | capabilities |
| Dart feature gaps | `docs/multiplatform-dart-feature-gaps.md` | `GAP-*`, inventory |
| Slice roadmap | `docs/multiplatform-dart-slice-roadmap.md` | `DART-NNN` |
| Host UI fidelity | `docs/multiplatform-dart-ui-fidelity.md` | `GAP-UI-*` |

Domain wording wins on conflict. FEAT cutover **PASS** does **not** override open BR/DAC gaps.

## Code layout probes should use

| Area | Paths |
| --- | --- |
| Pure logic | `packages/domain`, `packages/db`, `packages/bungie`, `packages/app`, … |
| Hosts | `apps/windows_host`, `apps/web_host`, `apps/mobile_host` |
| Gates | `tool/*_gate.dart` |
| Next parity (read-only) | residual `src/` |

## Modes

| `mode` | Behavior |
| --- | --- |
| `scan` (default) | Context + probes + ranked packages + report. **No code changes.** |
| `full` | Scan → user confirms package → plan → user confirms plan → implement → verify → report |
| `implement` | Uses `package_id` (or recommended) after package synthesis; pauses if `package_id` omitted |

## Args

```json
{
  "mode": "scan",
  "focus": "optional theme or rule id substring, e.g. DBR-SYN or GAP-UI",
  "package_id": "optional slug from a prior scan",
  "max_packages": 5,
  "commit": false,
  "skip_product_map": true
}
```

| Field | Default | Notes |
| --- | --- | --- |
| `mode` | `scan` | `scan` \| `full` \| `implement` |
| `focus` | _(all open)_ | Narrows prioritization |
| `package_id` | recommended | Must match a synthesized package when implementing |
| `max_packages` | `5` | Cap 1–8 |
| `commit` | `false` | If true, implement agent may commit related files only (no push by default) |
| `skip_product_map` | often `true` here | This repo usually has no `docs/product-map`; use ui-fidelity notes |

## How to run (Grok) — open this repo first

**Scan only**

```text
/workflow align-product-implement
```

```text
/workflow align-product-implement {"mode":"scan","focus":"synergy"}
```

**Full implement loop**

```text
/workflow align-product-implement {"mode":"full","focus":"builds"}
```

**Implement a known package**

```text
/workflow align-product-implement {"mode":"implement","package_id":"your-slug","commit":false}
```

Watch progress in `/workflows`. Resume pauses with `/workflow resume <display-name>`.

## Phases

1. **Context** — domain SSoT + multiplatform feature-gap inventory  
2. **Probe** — sets, builds/kit, synergy, completeness/UI, **dart-host-parity**  
3. **Packages** — ranked vertical slices (acceptance + estimate)  
4. **Select** — `await_user` unless `package_id` provided  
5. **Plan** — files under `packages/` / `apps/`, dart tests, docs  
6. **Implement** — Dart code + gap/domain docs  
7. **Verify** — focused `dart test` + rule capture  
8. **Report** — `scratch/align-*-report.md`

## Implementation conventions

- Prefer pure packages + hard gates + package tests  
- Update `docs/multiplatform-dart-feature-gaps.md` when closing a gap  
- Update slice roadmap when shipping `DART-NNN` work  
- Pure UI polish → `docs/ui-polish-tracker.md`, not domain P1/P2  
- Related workflows already in this repo: `dart-gaps-analysis`, `dart-speckit-loop`

## Agent budget

| Mode | Approx. agent calls |
| --- | --- |
| `scan` | ~7 (1 context + 5 probes + 1 packages) |
| `full` / `implement` | ~10 (+ plan, implement, verify) |

## Related

- Feature gap catalog: [`docs/multiplatform-dart-feature-gaps.md`](../multiplatform-dart-feature-gaps.md)  
- Slice roadmap: [`docs/multiplatform-dart-slice-roadmap.md`](../multiplatform-dart-slice-roadmap.md)  
- Source workflow (Next-first repo): `F:\Destiny2BuildCreator\.grok\workflows\align-product-implement.rhai`  
