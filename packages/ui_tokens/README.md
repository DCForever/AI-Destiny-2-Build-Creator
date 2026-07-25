# destiny2_ui_tokens (DART-029)

Shared **Matte Flap Ledger** design tokens and **FlapBoard layout contracts** for the multiplatform Dart port.

| Property | Value |
| -------- | ----- |
| Pub name | `destiny2_ui_tokens` |
| Path | `packages/ui_tokens` |
| Runtime deps | **SDK only** (no Flutter / Jaspr / IO) |
| Source of truth (product design) | repo root [`DESIGN.md`](../../DESIGN.md) |
| Product CSS | [`src/app/globals.css`](../../src/app/globals.css) |

## Why pure Dart?

Port architecture ([docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)): shells do **not** share one widget tree. Flutter Windows, Flutter mobile, and Jaspr web share **tokens + layout contracts** only. ARGB ints map to `Color(...)` or CSS hex without pulling Flutter into Jaspr.

## Colors

Dark is the **default** (Windows theme stub). Light constants exist for a future ThemeToggle.

| Token | Dark hex | Role |
| ----- | -------- | ---- |
| `background` | `#050608` | Void canvas |
| `surface` | `#0c0e12` | Flap plate |
| `surfaceRaised` | `#12151c` | Raised flap |
| `line` / `lineStrong` | `#1c212c` / `#2a3140` | Hairline rules |
| `foreground` / `muted` | `#e8eaef` / `#8a93a6` | Lettering |
| `accent` | `#e6b35c` | Readiness / selection lamp |
| `danger` / `success` / `warning` | coral / green / gold | Status lamps |
| Element ink | kinetic…prismatic | Identity cells only |

```dart
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';

final voidBg = FlapColorTokens.dark.background; // 0xFF050608
final css = argbToCssHex(kFlapAccentDark);      // #e6b35c
```

## Spacing & radii

- Density scale: 2, 4, 6, 8, 10, 12, 16, 24 (+ panel/page paddings).
- **Flap row gap = 0** (board not cards).
- **All radii = 0** (square board rule).

## Typography

Family names + metrics only — **fonts not bundled** in this slice:

- Display/board: Barlow Condensed  
- Body: IBM Plex Sans  
- Tallies: IBM Plex Mono  

## FlapBoard layout contracts

Not widgets — constants for DART-030+ libraries:

| Contract | Value |
| -------- | ----- |
| Library rail width | `320` |
| Row gap | `0` |
| Rule thickness | `1` |
| Page frame max | `1600` |
| Column templates | `sets`, `synergy`, `builds` (see `flap_board_layout.dart`) |

```dart
assert(kFlapLibraryRailWidth == 320);
assert(kFlapBoardRowGap == 0);
final cols = flapColumnTemplateById('builds');
// cols.columnsCss → CSS grid-template-columns
// cols.cellRoles → name, identity, exotics, synergy, status
```

### Board anti-rules (do not regress)

- **No steel** — no brushed metal, chrome bezels, metallic gradients  
- **Board not cards** — no nested elevated panels per library row  
- **One lamp** — amber for selection/readiness, not every border  
- **Element ink** — Destiny colors on identity/seals only  

## Flutter Windows theme stub

Host maps tokens → `ThemeData` in `apps/windows_host/lib/theme/flap_theme.dart`:

- Explicit dark `ColorScheme` from tokens (not `ColorScheme.fromSeed` blue)
- `cardTheme`: elevation `0`, border radius `0`, surface color = flap surface

Jaspr maps these tokens to CSS custom properties in `apps/web_host` (DART-042) via `argbToCssHex` — this package stays pure SDK.

## Tests

```powershell
dart test packages/ui_tokens
```

## Non-goals (this package)

- FlapRow / FlapBoard Flutter widgets  
- Full Settings/Catalog brand rewrite  
- Soft guidance auto-apply / domain rules  
- CLIENT_SECRET / network  
