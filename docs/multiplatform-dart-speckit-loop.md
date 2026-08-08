# DART Spec Kit auto-loop

**Workflow:** `dart-speckit-loop` (`.grok/workflows/dart-speckit-loop.rhai`)  

**Scope (D-LANES):** advances **system / non-UI** DART slices only. Do **not** use this loop for presentation chrome, mockups, or dual-truth Capture — use [ux-redesign](./ux-redesign/README.md).  

**Roadmap:** [multiplatform-dart-slice-roadmap.md](./multiplatform-dart-slice-roadmap.md)  
**Worktree:** `F:\Destiny2BuildCreator-multiplatform-dart`

## What it does

For each pending/active **DART-NNN** slice (in order):

1. **Resolve** — read roadmap; pick next ready slice  
2. **Spec Kit** — specify → plan → tasks → implement → finish-spec into `feature/multiplatform-dart`  
3. **Record** — update roadmap status / Current pointer  

Re-run the workflow to continue after a stop or failure.

## How to run

From Grok (prefer session rooted on the multiplatform worktree):

```text
/dart-speckit-loop
```

With args:

```json
{
  "max_slices": 49,
  "worktree": "F:/Destiny2BuildCreator-multiplatform-dart",
  "stop_on_fail": true,
  "auto_finish": true
}
```

| Arg | Default | Meaning |
| --- | ------- | ------- |
| `max_slices` | 49 | Max slices this run (1–49) |
| `worktree` | multiplatform path | Absolute path to DART worktree |
| `stop_on_fail` | true | Stop after first failed/blocked slice |
| `auto_finish` | true | Merge into `feature/multiplatform-dart` when slice passes |

**Agent budget:** each slice uses ~2 agents (resolve + implement). A full 49-slice run needs budget ≥ ~100. Use `agent_budget: 128` or higher if the host allows.

## Stop conditions

- `max_slices` reached  
- No pending ready slice (`all_done`)  
- Resolve/implement failure and `stop_on_fail`  
- Slice reports `blocked` (e.g. missing Dart SDK, product decision)  

## Human responsibilities

- Install **Dart/Flutter SDK** on the machine before P0 implement  
- Bungie Public+PKCE app credentials when reaching auth slices  
- Review merges on `feature/multiplatform-dart` periodically  
- Do **not** run this against the product worktree (`043-*`)

## Relation to exploration workflow

| Workflow | Role |
| -------- | ---- |
| `explore-flutter-port` | Architecture research (optional re-run) |
| **`dart-speckit-loop`** | **Delivery** of DART-001…049 via Spec Kit |
