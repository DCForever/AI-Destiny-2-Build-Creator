# destiny2_widgetbook

Isolated **Widgetbook** app for Matte Flap / Neon catalog composables from
[`packages/ui_flutter`](../../packages/ui_flutter).

Not a product host: **no** OAuth, inventory sync, Drift, or secrets.

## Prerequisites

- Workspace root: `flutter/`
- `dart pub get` from `flutter/` (workspace member)

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

```powershell
cd flutter/apps/widgetbook
flutter run -d windows
# or
flutter run -d chrome
```

### Flutter Driver / MCP screenshots

```powershell
cd flutter/apps/widgetbook
# Agent entrypoint (driver always on):
flutter run -d windows -t lib/main_mcp.dart
# Or everyday main with define:
flutter run -d windows --dart-define=ENABLE_FLUTTER_DRIVER=true
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

See `docs/ux-redesign/widgetbook.md` for phase notes.

## Rules

- Depend on `destiny2_ui_flutter` + pure data packages only for fixtures
- Do **not** add Widgetbook deps to `ui_flutter` or pure packages
- Dual-truth Capture remains the area-implement visual gate; Widgetbook is isolation for design review
