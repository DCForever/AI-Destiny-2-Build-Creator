# Dual-truth capture protocol (area-implement)

Closes the redesign ↔ implement loop. **Structure green ≠ dual-truth closed.**  
**PNG on disk ≠ visual parity with mockup.**

Agents and humans follow this for `area-implement` **Verify-structure**, **Capture**, and any manual re-capture.

## Three gates (all required for dual-truth close)

| Gate | Proves | Fail policy |
| --- | --- | --- |
| **Structure** | `dart analyze` + widget/host tests for the plan | Hard fail — do not ship |
| **Shot matrix** | PNG for every **must** row in the plan `shot_matrix` | Pause for human capture **or** explicit structure-only accept |
| **Gap log** | No **open** gaps with `blocks_dual_truth: true` for this area/slice in [`DUAL-TRUTH-GAPS.md`](DUAL-TRUTH-GAPS.md) (unless structure-only accepted per gap) | Plan must address gaps; Capture must set `dual_truth_ok=false` while they remain open |

### Human gap memory

File visual/product mismatches you notice (mockup vs Flutter, or DIM vs Flutter) in:

**[`docs/ux-redesign/DUAL-TRUTH-GAPS.md`](DUAL-TRUTH-GAPS.md)**

Workflows **must read** that file on Load. Do not mark dual-truth closed while blocking gaps stay open.

## Shot matrix contract

Plan output **must** include `shot_matrix`: an array of scenario rows.

| Field | Required | Meaning |
| --- | --- | --- |
| `id` | yes | Scenario id = base filename without `.png` (e.g. `desktop-detail-owned`) |
| `must` | yes | `true` = required for `dual_truth_ok` |
| `proves` | yes | Short tokens this shot must evidence (e.g. `meta-22`, `e-on-12-only`) |
| `drive` | yes | How to reach the UI state |

### `drive` values

| Value | Use when |
| --- | --- |
| `live-inventory` | Real Bungie sync / owned inventory is enough |
| `host-fixture` | Needs seeded map, enhanced hash map, catalyst fields, etc. **Implement must provide fixture or test harness** before Capture claims the row |
| `widget-test-only` | Structure-only proof; do **not** set `must: true` for dual-truth |

Capture returns `matrix_coverage`: one entry per plan row with `status` ∈ `captured` | `missing` | `skipped`, optional `path` and `reason`.

**`dual_truth_ok` is true only if:**

1. Every `must: true` matrix row has `status: captured` and a real PNG on disk under the shots dir, **and**
2. Every **open** gap in `DUAL-TRUTH-GAPS.md` for this area with `blocks_dual_truth: true` is either closed with proof **or** explicitly structure-only-accepted by the human.

Never invent images. Never treat “PNG exists for desktop-detail-owned” as proof that mockup perk chrome matches ship.

## Flutter process rules (hard)

1. **Never** run `flutter run`, `flutter attach`, or a long-lived host as a **foreground blocking** shell command. Those processes wait for input and hang the agent.
2. **Prefer** Dart MCP: `list_devices` → `add_roots` → `stop_app` (stale) → `launch_app` with `lib/main_mcp.dart` (Driver on) → DTD + `flutter_driver` → `stop_app`.
3. **Shell fallback** only with **`background: true`** (or equivalent non-blocking job), env `ENABLE_FLUTTER_DRIVER=1`, target `lib/main_mcp.dart`. Then connect Driver; always **kill/stop** when done.
4. Before interaction: Flutter Driver **`set_frame_sync` enabled=false** (avoids hung taps).
5. If launch or Driver health fails: set `driver_screenshot_ok=false` / leave must-rows `missing`, set `human_capture_required=true`. **Do not** invent PNGs or mark dual-truth complete.

## Capture package layout

```text
docs/ux-redesign/<area>/implementation-shots/<slice-id>/
  COMPARE.md
  desktop-grid.png
  desktop-detail-owned.png
  …
```

- Filenames **must** match matrix `id` + `.png`.
- `COMPARE.md` rows must match files on disk (no “complete” with blank shot paths for must-rows).
- Slice status language: `closed` | `structure-only` | `capture-incomplete` | `human-needed` (see package README).

## Human gate (when dual-truth incomplete)

Workflow pauses after Capture if `dual_truth_ok` is false.

User options on resume:

1. **Finish capture** (run app / sign in / drop PNGs / re-run Driver) then resume so Capture re-scores the matrix.
2. **Accept structure-only** — say clearly you accept structure-only ship; Capture may set `structure_only_accepted: true` (dual-truth remains open for next redesign).
3. **Fail closed** — do not claim dual-truth complete.

## COMPARE residual column

For each matrix row, COMPARE should say:

- **closed** — shot + structure prove the residual
- **structure-only** — tests/code only; shot missing or not evidence
- **reopen** — ship still wrong vs mockup

Next `area-ux-redesign` treats COMPARE + mockups as dual ground truth.

## Related

- Workflow: `.grok/workflows/area-implement.rhai`
- COMPARE template: `_template-implementation-shots-compare.md`
- Loop overview: `README.md`
