---
name: flutter-windows-debug-driver
description: >
  Debug-run the Destiny 2 Flutter Windows host (or Widgetbook) with Flutter
  Driver + Dart MCP: launch main_mcp.dart, connect DTD, hot reload/restart,
  driver taps/screenshots, widget tree, runtime errors. Use when the user says
  "debug app", "driver", "hot restart", "screenshot the app", "tap in the
  running app", /debug-app, /flutter-driver, or needs agent observation of the
  live Windows host (not everyday run mode). Complements run-flutter-windows
  (launch) and impeccable-flutter (design critique).
---

# Flutter Windows debug + Driver (agent loop)

Operate the **running** Windows host so code changes can be verified live:
launch with Driver, connect tooling, drive UI by **real keys**, screenshot,
reload, read errors.

```text
This skill   = launch debug + DTD + Driver + hot_reload/restart + verify
run-flutter-windows = launch only (run | debug)
impeccable-flutter  = design critique on top of the same connection
```

Official MCP: [Interact with a running app](https://docs.flutter.dev/ai/mcp-server#interact-with-a-running-app).

## When to use

| User intent | Mode |
| --- | --- |
| “debug app”, agent must tap/screenshot | **debug** (`main_mcp.dart`) |
| “run app”, human daily use | **run** (`main.dart`) — hand off to `run-flutter-windows` |
| “hot restart / reload after my edit” | this skill (needs DTD) |
| “UI critique / polish” | `impeccable-flutter` (uses same connect path) |

## Hard rules

1. **Never** embed `BUNGIE_CLIENT_SECRET`. Host uses Public + PKCE + `.env.windows.local`.
2. **Agent observe = debug entrypoint:** `lib/main_mcp.dart` (Driver always on). Do not use `main.dart` if you need `flutter_driver` screenshot/tap.
3. **Prefer Dart MCP** `launch_app` → `connect_dart_tooling_daemon`. Shell is fallback.
4. **One instance:** `list_running_apps` → `stop_app` stale pids before a new launch.
5. **Never invent Driver finders.** Discover `Key('…')` / visible text via `get_widget_tree` or source `Key('…')` / `grep`.
6. **Widget tests:** `flutter test`, never bare `dart test` on Flutter UI packages (`dart:ui` thrash).
7. After code edits that affect the running app: **`hot_reload`** (or **`hot_restart`** if state/globals/const entrypoints changed) → re-verify. Do not claim live success from analyze alone.
8. Long worktree paths: launch via `scripts/run-flutter-windows.ps1` / short junction (`F:\d2w\…`) — same as `run-flutter-windows`.

## Entrypoints

| Mode | Target | Driver | Keyboard | Agent tools |
| --- | --- | --- | --- | --- |
| **run** | `lib/main.dart` | off (unless define) | real | DTD only if debug-ish attach |
| **debug** | `lib/main_mcp.dart` | **on** | may be emulated | Driver + DTD |

Host `main_mcp.dart` enables `enableFlutterDriverExtension()` then calls host `main()`.

## Connect (default path)

### A. MCP launch (preferred)

1. `search_tool` for Dart MCP schemas when needed (`launch_app`, `hot_restart`, `flutter_driver_command`, …).
2. `list_devices` → **windows** (non-web).
3. Resolve absolute host: `<melos>/apps/windows_host` (or `widgetbook`).
4. `list_running_apps` → `stop_app` each stale app.
5. `launch_app`:
   - `root`: absolute host dir  
   - `device`: windows device id  
   - `target`: **`lib/main_mcp.dart`**
6. From result: **DTD URI** → `connect_dart_tooling_daemon`.
7. `flutter_driver` · `get_health` → expect ok.
8. Report: mode, host path, pid, DTD, how to stop.

OAuth/env still load from host `.env.windows.local` when present.

### B. Shell fallback (MCP launch failed)

```powershell
# From monorepo root
pwsh -NoProfile -File scripts/run-flutter-windows.ps1 -Target app -Mode debug -SkipPubGet
# or host:
cd <melos>/apps/windows_host
.\run-windows.ps1 -EnableFlutterDriver
```

Background the process. Ask user for **DTD URI** (or parse VM service line from logs) → `connect_dart_tooling_daemon`. Banner: `DEGRADED: shell launch`.

### C. Already running

1. `list_running_apps` — reuse pid + DTD if connected.
2. Else connect DTD from user / log.
3. Do **not** start a second host unless clean restart requested.

## After connect — daily loop

```text
edit code
  → hot_reload   (UI/logic, keep state)
  → hot_restart  (initState, consts, global config, bad state)
  → get_runtime_errors (clearRuntimeErrors: true when rechecking)
  → drive UI (tap / waitFor / scroll)
  → screenshot if visual claim
  → report evidence
```

| Tool | Use |
| --- | --- |
| `hot_reload` | Most UI/domain UI-binding edits |
| `hot_restart` | Selection/init, static config, “stuck” shell state |
| `get_runtime_errors` | Overflows, exceptions after reload |
| `get_widget_tree` (`summaryOnly: true`) | Find keys/text for finders |
| `flutter_driver` | health, tap, waitFor, screenshot, scroll, get_text |
| `get_app_logs` | Red screen / opaque failures (when available) |

### Driver finders (only real values)

```text
ByValueKey  — keyValueString + keyValueType: "String" | "int"
ByText      — exact visible label
ByTooltipMessage
ByType      — runtimeType string (fragile; prefer keys)
```

Workflow:

1. `get_widget_tree` summary **or** `grep` `Key('…')` in host/`ui_flutter`.
2. Prefer product keys already used in dual-truth Capture (`sets_optimize_*`, `host_nav_rail`, …).
3. `waitFor` before `tap` when navigation/async.
4. If animations thrash Driver: `set_frame_sync` enabled `false`, then retry.

### Screenshot / Capture

- Ad-hoc: `flutter_driver` · `screenshot` (save under session or `docs/ux-redesign/.../implementation-shots/` when doing dual-truth).
- Design pass: prefer **`impeccable-flutter`** state matrix conventions.

## Verify playbook (feature work)

Use after Sets/Catalog/etc. code changes while the debug host is up:

1. `hot_reload` or `hot_restart`.
2. `get_runtime_errors` — none blocking.
3. Navigate with Driver (e.g. Sets rail → set row → Optimize).
4. Assert presence: `waitFor` ByValueKey for the surface under test.
5. Optional screenshot for the user.
6. If empty/error UI: read on-screen text via tree/`get_text`, not guesses.

## Common failures

| Symptom | Action |
| --- | --- |
| Driver timeout / no health | Confirm `main_mcp.dart` (not `main.dart`); reconnect DTD |
| “No scroll position” / AXTree spam | Often non-fatal on Windows; check real exceptions via `get_runtime_errors` |
| Tap does nothing | Wrong finder; tree first; dialogs need finder inside route |
| Hot reload misses change | `hot_restart`; if still stale, full relaunch |
| `dart test` thrash on `ui_flutter` | Use **`flutter test`** only |
| Second window / ghost process | `list_running_apps` + `stop_app`; kill `destiny2_windows_host` if orphaned |
| MSB3491 / long path | `run-flutter-windows.ps1` short path / `-ForceShortPath` |

## Tool cheat sheet

See [references/mcp-commands.md](references/mcp-commands.md).

## Report to user

After launch or verify:

- [ ] Target (app / widgetbook) and **debug** mode  
- [ ] Host absolute path  
- [ ] Connected: DTD + Driver health **or** degraded banner  
- [ ] What was verified (keys tapped, errors cleared, screenshot path)  
- [ ] Stop: `stop_app` / close window / quit `flutter run`

## Related

- Project skill **`run-flutter-windows`** — launch run/debug scripts  
- User skill **`impeccable-flutter`** — design critique using same Driver/DTD  
- Host README Driver section: `flutter/apps/windows_host/README.md`  
- Entrypoint: `flutter/apps/windows_host/lib/main_mcp.dart`  
