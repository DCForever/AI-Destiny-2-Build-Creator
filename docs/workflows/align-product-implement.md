# Workflow: align-product-implement (multiplatform Dart)

**Script**: [`.grok/workflows/align-product-implement.rhai`](../../.grok/workflows/align-product-implement.rhai)

Closes the loop from **product requirements + domain specs → ranked packages → implement → verify** for multiplatform Dart (`flutter/`).

## Source of truth (mandatory)

| Rank | Layer | Path | Owns |
| --- | --- | --- | --- |
| **1** | **High-level product requirements** | [`requirements/Projects/Destiny 2 Build Creator/`](../../requirements/Projects/Destiny%202%20Build%20Creator/) (Obsidian ProjectTracker mount) | Intent, framing, Domains / Areas / Destiny Objects |
| **2** | **Enforceable specs** | `specs/domain-business-rules.md`, `domain-acceptance-criteria.md`, `business-rules.md` | `DBR-*` / `DAC-*` / `BR-*` |
| **2b** | Whole-product framing | `PRODUCT.md` | Purpose, positioning, principles |
| **3** | Implementation | `flutter/packages/*`, `flutter/apps/*` | Code under test |
| **Not SSoT** | **NextJS** | `web/NextJS/` | Legacy residual only |

**Precedence:** Specs win over vault prose on conflict; vault prose informs intent and acceptance language; **both beat any legacy code**, including NextJS.

### Explicitly forbidden as acceptance criteria

- “Match Next” / “port Next Phase X” / “golden parity with Next tests”
- Cloning Next behavior without a **DBR / DAC / BR** or product-requirement citation
- Using Next as the definition of done for a package

Next may be opened only as **optional historical reference** when a gap note already points there — never to invent rules.

Recreate product-req mount: `pwsh -File scripts/link-projecttracker-requirements.ps1`  
Git pointer when mount missing: [`docs/products/README.md`](../products/README.md)

## Supporting ledgers (not product SSoT)

| Layer | Path | IDs |
| --- | --- | --- |
| Dart feature gaps | `docs/multiplatform-dart-feature-gaps.md` | `GAP-*` |
| Slice roadmap | `docs/multiplatform-dart-slice-roadmap.md` | `DART-NNN` |
| Host UI fidelity | `docs/multiplatform-dart-ui-fidelity.md` | `GAP-UI-*` |
| Product map | `docs/product-map/` | surfaces / flows |

FEAT cutover **PASS** does **not** override open BR/DAC gaps.

## When to use

- “What’s left vs product reqs + DBR/DAC/BR on Dart?”
- “Next DART / pkg slice”
- After re-syncing domain markdown or Obsidian product notes, before a coding session

## Code layout probes should use

| Area | Paths |
| --- | --- |
| Pure logic | `flutter/packages/domain`, `db`, `bungie`, `app`, … |
| Hosts | `flutter/apps/windows_host`, `web_host`, `mobile_host` |
| Gates | `flutter/tool/*_gate.dart` |
| Product reqs | `requirements/Projects/Destiny 2 Build Creator/` |
| Specs | `specs/` |
| NextJS | **Do not probe by default** |

## Modes

| `mode` | Behavior |
| --- | --- |
| `scan` (default) | Context + probes + ranked packages + report. **No code changes.** |
| `full` | Scan → user confirms package → plan → user confirms plan → implement → verify → report |
| `implement` | Synthesizes packages but **honors `package_id`** (does not silently swap to another package) |

## Args

```json
{
  "mode": "scan",
  "focus": "optional theme or rule id substring, e.g. DBR-SYN or GAP-UI",
  "package_id": "optional slug from a prior scan",
  "max_packages": 5,
  "commit": false,
  "skip_product_map": false
}
```

| Field | Default | Notes |
| --- | --- | --- |
| `mode` | `scan` | `scan` \| `full` \| `implement` |
| `focus` | _(all open)_ | Narrows prioritization |
| `package_id` | recommended | **Required for unattended implement**; workflow forces this id if synthesis omits it |
| `max_packages` | `5` | Cap 1–8 |
| `commit` | `false` | If true, implement agent may commit related files only (no push by default) |
| `skip_product_map` | `false` | When true, skip product-map sync and note fidelity follow-up |

## How to run (Grok)

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

**Implement a known package** (honors id; product/specs SSoT)

```text
/workflow align-product-implement {"mode":"implement","package_id":"dart-070-set-occupancy","commit":false}
```

Watch progress in `/workflows`. Resume pauses with `/workflow resume <display-name>`.

## Phases

1. **Context** — product requirements + specs SSoT + feature-gap inventory  
2. **Probe** — sets, builds/kit, synergy, completeness/UI, **host-ui-fidelity** (Flutter vs product/specs)  
3. **Packages** — ranked vertical slices (acceptance cites DBR/DAC/BR, not Next)  
4. **Select** — `await_user` unless `package_id` provided; **never silently replace** an explicit `package_id`  
5. **Plan** — files under `flutter/` + `specs/` / `docs/`  
6. **Implement** — Dart code + gap/domain docs  
7. **Verify** — focused tests + wrong-package check + rule capture  
8. **Report** — `scratch/align-*-report.md`

## Implementation conventions

- Prefer pure packages + hard gates + package tests derived from **specs / product reqs**  
- Update `docs/multiplatform-dart-feature-gaps.md` when closing a gap  
- Update slice roadmap when shipping `DART-NNN` work  
- Pure UI polish → `docs/ui-polish-tracker.md`, not domain P1/P2  
- Related workflows: `dart-gaps-analysis`, `dart-speckit-loop`

## Agent budget

| Mode | Approx. agent calls |
| --- | --- |
| `scan` | ~7 (1 context + 5 probes + 1 packages) |
| `full` / `implement` | ~10 (+ plan, implement, verify) |

## Related

- Feature gap catalog: [`docs/multiplatform-dart-feature-gaps.md`](../multiplatform-dart-feature-gaps.md)  
- Slice roadmap: [`docs/multiplatform-dart-slice-roadmap.md`](../multiplatform-dart-slice-roadmap.md)  
- Product requirements pointer: [`docs/products/README.md`](../products/README.md)  
