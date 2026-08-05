# destiny2_widgetbook

Isolated **Widgetbook** app for Matte Flap / Neon catalog composables from
[`packages/ui_flutter`](../../packages/ui_flutter).

Not a product host: **no** OAuth, inventory sync, Drift, or secrets.

## Iterate on UI (start here)

**Day-to-day loop:** [ITERATE.md](./ITERATE.md)

Short version:

1. Leave Widgetbook running: `.\run-windows.ps1 -SkipPubGet` (or IDE launch **`widgetbook`**)
2. Edit `packages/ui_flutter` (or use cases / fixtures)
3. Press **`r`** hot reload (or **`R`** hot restart) in the Flutter terminal
4. Open the matching story in the left nav; use knobs / Viewport addon

Only run `build_runner` when you add or rename `@UseCase` entries (`-Gen` or `melos run widgetbook:watch`).

## Prerequisites

- Workspace root: `flutter/`
- `dart pub get` from `flutter/` (workspace member) once per session / dep change

## Generate directories

After adding or changing `@UseCase` / `@App` annotations:

```powershell
cd flutter/apps/widgetbook
dart run build_runner build -d
```

Or from `flutter/` (Melos):

```powershell
melos run widgetbook:gen
```

## Run

Preferred (mirrors `windows_host/run-windows.ps1`):

```powershell
cd flutter/apps/widgetbook
.\run-windows.ps1
```

| Flag | Effect |
| --- | --- |
| (none) | `flutter run -d windows` → `lib/main.dart` (+ workspace `dart pub get`) |
| `-SkipPubGet` | Faster re-launch while iterating (skip workspace pub get) |
| `-EnableFlutterDriver` | `lib/main_mcp.dart` (Driver on for MCP screenshots) |
| `-Gen` | `dart run build_runner build -d` first |
| `-Clean` | `flutter clean` + wipe `build/` and `windows/flutter/ephemeral` (fixes C1083 / empty wrapper) |
| `-Device chrome` | Run on Chrome instead of Windows (faster cold start) |

If MSBuild fails with **C1083** on `cpp_client_wrapper\*.cc`, run:

```powershell
.\run-windows.ps1 -Clean
```

From monorepo root:

```powershell
pwsh -File flutter/apps/widgetbook/run-windows.ps1
pwsh -File flutter/apps/widgetbook/run-windows.ps1 -EnableFlutterDriver
```

Raw Flutter (no script):

```powershell
cd flutter/apps/widgetbook
flutter run -d windows
# or
flutter run -d chrome
flutter run -d windows -t lib/main_mcp.dart
```

Dart MCP: prefer `launch_app` with `target=lib/main_mcp.dart` when available, then
`flutter_driver` · `get_health` / `screenshot`.

## Layout

```text
lib/
  main.dart                 # @App + Flap dark/light theme addons
  main.directories.g.dart   # generated — do not hand-edit
  fixtures/                 # pure CatalogItem / family / plug fixtures
  use_cases/catalog/        # Phase 1 catalog stories
```

## Coverage

**Phase 1:** Meta, cards, family (multi-hash Base chip), facets, scope, empty,
group chrome, detail/perks, workspace.

**Phase 2:** Sort/group sheet, type-icon filter bar, outline jump expand+scroll,
mobile list→push detail, knobs (element/slot/owned), Neon shell/board.

**Phase 3:** Viewport addon (phone/tablet/desktop), host-parity filter bar exotic
cycle, sort reorder interaction smoke tests.

See `docs/ux-redesign/widgetbook.md` for phase notes.

## Rules

- Depend on `destiny2_ui_flutter` + pure data packages only for fixtures
- Do **not** add Widgetbook deps to `ui_flutter` or pure packages
- Dual-truth Capture remains the area-implement visual gate; Widgetbook is isolation for design review
