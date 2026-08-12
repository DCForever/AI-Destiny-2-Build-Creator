---
name: run-flutter-windows
description: >
  Launch Destiny 2 Flutter Windows host or Widgetbook from the current monorepo
  or worktree. Use when the user says "run app", "debug app", "run widgetbook",
  "debug widgetbook", /run-app, /debug-app, /run-widgetbook, /debug-widgetbook,
  or wants a background Windows process an agent can observe (DTD / Flutter Driver).
  Handles Melos root discovery, long worktree paths via F:\d2w junctions, and
  prefers MCP launch_app for agent observation with shell fallback.
---

# Run Flutter Windows (app / Widgetbook)

Launch **product Windows host** or **Widgetbook** from whatever checkout the session is in (primary monorepo or `F:\Destiny2Creator-worktrees\…`).

## Trigger map

| User says | Target | Mode | Agent observe |
| --- | --- | --- | --- |
| **run app** / `/run-app` | `windows_host` | run (`main.dart`) | optional DTD if already debug |
| **debug app** / `/debug-app` | `windows_host` | debug (`main_mcp.dart` + Driver) | **yes** — preferred for agents |
| **run widgetbook** / `/run-widgetbook` | `widgetbook` | run | optional |
| **debug widgetbook** / `/debug-widgetbook` | `widgetbook` | debug (`main_mcp.dart`) | **yes** |

Synonyms: “launch host”, “start catalog app”, “open widgetbook”, “driver windows”.

## Hard rules

1. **Never** embed `BUNGIE_CLIENT_SECRET`. Host uses Public + PKCE + `.env.windows.local` only.
2. **Resolve Melos root** from session cwd (or git worktree root), not a hard-coded path alone.
3. **Long worktree paths:** use `scripts/run-flutter-windows.ps1` (auto `F:\d2w\<slug>` junction) — do not `flutter run` from a path whose plugin tlog probe is ≥ 250 chars.
4. **Agent observation default for “debug *”:** prefer Dart MCP `launch_app` with `target=lib/main_mcp.dart` on device `windows`. Shell is fallback.
5. **One instance:** `list_running_apps` → `stop_app` stale pids before a new launch when using MCP.
6. **Background shell:** if shell launch, use `run_terminal_command` with `background: true` and a long/no timeout so the process stays up; tell the user the command + cwd.

## Resolve paths

From the session workspace root (or any nested path under it):

1. Walk up until `flutter/melos.yaml` **or** current dir is Melos root (`melos.yaml` + workspace `pubspec.yaml`).
2. Hosts:
   - App → `<melos>/apps/windows_host`
   - Widgetbook → `<melos>/apps/widgetbook`
3. Monorepo script (preferred entry from primary checkout):

```powershell
# Primary repo root = parent of flutter/
pwsh -File scripts/run-flutter-windows.ps1 -Target app -Mode run
pwsh -File scripts/run-flutter-windows.ps1 -Target app -Mode debug
pwsh -File scripts/run-flutter-windows.ps1 -Target widgetbook -Mode run -SkipPubGet
pwsh -File scripts/run-flutter-windows.ps1 -Target widgetbook -Mode debug
```

From inside a worktree, either:

```powershell
# worktree root still has flutter/ + can use monorepo scripts if present
pwsh -File scripts/run-flutter-windows.ps1 -Target app -Mode debug -StartDir .
```

or call host scripts after short-path resolution:

```powershell
cd <short-or-native>\apps\windows_host
.\run-windows.ps1 -EnableFlutterDriver   # debug
.\run-windows.ps1                        # run
```

Env symlink (once per new worktree):

```powershell
pwsh -File scripts/link-worktree-env.ps1
```

## Agent procedure

### A. Prefer MCP (debug app / debug widgetbook / “so I can screenshot”)

1. `list_devices` → pick **windows** (non-web).
2. Resolve absolute **host** path (after short-junction if needed — run the PowerShell script with `-Mode debug` only if MCP cannot use short path; MCP `root` must be a real filesystem path; junctions under `F:\d2w\…` are fine).
3. `list_running_apps` → `stop_app` stale.
4. `launch_app`:
   - `root`: absolute host dir
   - `device`: windows device id
   - `target`: **`lib/main_mcp.dart`**
5. `connect_dart_tooling_daemon` with DTD from launch result.
6. `flutter_driver` · `get_health` when driver entry used.
7. Report: pid, DTD, host path, mode.

### B. Shell launch (run app / run widgetbook / MCP failed)

1. Compute monorepo or worktree root.
2. Background:

```powershell
pwsh -NoProfile -File "<repo>/scripts/run-flutter-windows.ps1" -Target app|widgetbook -Mode run|debug [-SkipPubGet] [-Clean] [-Gen]
```

3. Set `background: true` on the tool call; do not poll-sleep.
4. Tell user: process is running; for agent observe they should use **debug** next time or paste DTD if shell-launched.
5. If build fails with **MSB3491** / missing `.tlog`: re-run with short path (script default) or `-ForceShortPath`, and `-Clean` once.

### C. Already running

Reuse MCP pid + DTD; do not start a second copy unless the user asks for restart.

## Mode details

| Mode | Entrypoint | Driver | Use |
| --- | --- | --- | --- |
| **run** | `lib/main.dart` | off | Human daily use; faster; real keyboard |
| **debug** | `lib/main_mcp.dart` | on | Agent screenshots, taps, dual-truth Capture |

Widgetbook: no OAuth/secrets. Host: requires `.env.windows.local` (gitignored); script chain uses `run-windows.ps1`.

## After launch checklist (reply to user)

- [ ] Which target (app / widgetbook) and mode (run / debug)
- [ ] Absolute host path used (note if `F:\d2w\…`)
- [ ] MCP pid + DTD **or** shell background task id
- [ ] How to stop: MCP `stop_app` or close the Flutter window / kill task

## Related

- `scripts/run-flutter-windows.ps1` — unified launcher  
- `scripts/link-worktree-env.ps1` — env/cert symlinks into worktrees  
- `scripts/link-worktree-windows-build.ps1` — bulk short junctions  
- `flutter/apps/windows_host/run-windows.ps1` · `flutter/apps/widgetbook/run-windows.ps1`  
- Skill **`flutter-windows-debug-driver`** — DTD + Driver + hot reload/tap/screenshot loop after launch  
- Skill `impeccable-flutter` for design passes on a **running** debug host  
