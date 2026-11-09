# Quickstart: DART-046 Jaspr Compose Spine

## Prerequisites

- Dart SDK matching workspace
- Writer tab (first open of web host) for live browser use

## Tests (CI path)

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart\apps\web_host
dart pub get
dart test
```

Parity-focused suites:

- `test/builds_controller_test.dart` — create → attach → pin → soft
- `test/sets_controller_test.dart` / `test/synergies_controller_test.dart`
- `test/*_format_test.dart` — pure display helpers
- `test/shell_nav_compose_test.dart` — nav spine

## Manual browser path

```powershell
cd apps\web_host
# ensure drift wasm assets once
powershell -File tool\fetch_drift_web_assets.ps1
jaspr serve
```

1. Open app (first tab = writer).
2. **Sets** → create weapon set → add slot item (hash/name).
3. **Synergies** → create type `melee` (optional evidence link).
4. **Builds** → create class + synergy type → open compose.
5. Create non-default variant → attach set → see pins.
6. Soft guidance chips advisory; soft targets save explicitly.

## Hard / soft rules

- Hard: illegal kits / slot conflicts block via use cases.
- Soft: chips and soft stat targets never auto-apply; never block legal attach.
