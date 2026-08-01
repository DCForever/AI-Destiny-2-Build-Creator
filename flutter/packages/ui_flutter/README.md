# destiny2_ui_flutter

Flutter-only **Matte Flap Ledger** composition kit for Windows + mobile hosts.

| Property | Value |
| -------- | ----- |
| Pub name | `destiny2_ui_flutter` |
| Path | `packages/ui_flutter` |
| Tokens SSOT | [`destiny2_ui_tokens`](../ui_tokens) (pure Dart) |
| Consumers | `apps/windows_host`, `apps/mobile_host` only |

## Why separate from ui_tokens?

Port architecture: shells share **tokens + layout contracts**, not one widget tree.
Jaspr maps tokens to CSS; Flutter maps them via `ThemeExtension` + these widgets.
**Do not** import this package from `apps/web_host`.

## Contents

- **`FlapPalette`** — `ThemeExtension` for success / warning / line / element ink (roles that do not fit `ColorScheme`)
- **`buildFlapThemeBase`** — shared `ThemeData` from tokens + palette
- **`flapToneColor` / `flapToneWash`** — status lamps (One Lamp: never use amber primary for “supported”)
- **`flapElementColor`** — Destiny element ink lookup
- **`FlapBoardHeader` / `FlapBoardRow` / `FlapTextCell` / `FlapSeal`** — board primitives
- **`LibraryWorkspace`** — dual-pane rail + detail shell

## Usage

```dart
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';

theme: buildFlapThemeBase(
  customize: (theme, tokens, palette) => theme.copyWith(
    navigationRailTheme: /* windows */,
  ),
);

final palette = Theme.of(context).extension<FlapPalette>()!;
final success = flapToneColor(context, 'success');
```

## Tests

```powershell
flutter test packages/ui_flutter
```
