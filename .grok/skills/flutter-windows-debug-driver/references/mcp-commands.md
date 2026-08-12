# Dart MCP + Flutter Driver command cheat sheet

Use with skill **flutter-windows-debug-driver**. Always `search_tool` first when schemas are unknown; tool names may be qualified (`dart__…`).

## Lifecycle

| Step | Tool / command | Notes |
| --- | --- | --- |
| Devices | `list_devices` | Pick **windows**, not chrome/web |
| Stale apps | `list_running_apps` → `stop_app` `{ pid }` | Before every new launch |
| Launch | `launch_app` | `root`, `device`, `target: lib/main_mcp.dart` |
| Connect | `connect_dart_tooling_daemon` | URI from launch result |
| Health | `flutter_driver` `get_health` | Driver extension must be on |
| Stop | `stop_app` | Or close window |

## Live edit

| Tool | When |
| --- | --- |
| `hot_reload` | UI/logic; keep navigation state |
| `hot_restart` | init/config/const/stuck state |
| `get_runtime_errors` | After reload; optional `clearRuntimeErrors: true` |
| `get_app_logs` | Red screen / unclear failure |

## Inspect

| Tool | Args |
| --- | --- |
| `get_widget_tree` | `summaryOnly: true` for keys/text |
| `get_selected_widget` | After inspector selection |

## Driver (`flutter_driver` / `flutter_driver_command`)

Common fields: `command`, `finderType`, `timeout` (ms string when required).

| command | Typical args |
| --- | --- |
| `get_health` | — |
| `screenshot` | — |
| `waitFor` | `finderType`, key/text fields |
| `waitForAbsent` | same |
| `waitForTappable` | same |
| `tap` | finder |
| `scroll` | finder + `dx` `dy` `duration` `frequency` |
| `scrollIntoView` | finder + `alignment` |
| `get_text` | finder |
| `enter_text` | `text` (after focusing field) |
| `set_frame_sync` | `enabled`: `"true"` / `"false"` — try false if timeouts on animated UI |
| `get_diagnostics_tree` | finder + `diagnosticsType` + `subtreeDepth` |

### Finder fields

**ByValueKey**

- `finderType`: `ByValueKey`
- `keyValueString`: e.g. `sets_optimize_rerun`
- `keyValueType`: `String` or `int`

**ByText**

- `finderType`: `ByText`
- `text`: exact label

**ByTooltipMessage**

- `finderType`: `ByTooltipMessage`
- `text`: tooltip string

Never invent keys. Discover from tree or source.

## Shell fallback launch

```powershell
pwsh -NoProfile -File scripts/run-flutter-windows.ps1 -Target app -Mode debug -SkipPubGet
# host cwd:
.\run-windows.ps1 -EnableFlutterDriver
```

Then connect DTD from log / user paste.

## Widget tests (not Driver)

```powershell
cd flutter/packages/ui_flutter
flutter test test/sets_armor_widgets_test.dart --name "Optimize shell"
```

Do **not** use `dart test` for Flutter widget packages.
