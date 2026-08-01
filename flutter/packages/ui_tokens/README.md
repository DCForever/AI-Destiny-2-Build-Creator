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

**Dual face (Flutter product choice):**

| Face | Mode | Character |
| ---- | ---- | --------- |
| **Cold Graphite** | dark (default) | Blue-gray void, cyan-teal One Lamp `#4ec4bc` |
| **Paper Ledger** | light | Cream stock, rubber-stamp amber `#9a6418` |

| Token | Dark (Cold Graphite) | Light (Paper Ledger) | Role |
| ----- | -------------------- | -------------------- | ---- |
| `background` | `#070b10` | `#ebe6db` | Canvas / stock field |
| `surface` | `#0e1319` | `#f7f3ea` | Flap plate |
| `surfaceRaised` | `#141a22` | `#fffdf7` | Raised plate |
| `line` / `lineStrong` | `#1f2733` / `#2a3342` | `#c4bba8` / `#9a9488` | Hairline rules |
| `foreground` / `muted` | `#e4eaf2` / `#8492a6` | `#1a1b1f` / `#5a5f6a` | Lettering |
| `accent` | `#4ec4bc` teal | `#9a6418` amber | Readiness / selection only |
| `danger` / `success` / `warning` | coral / green / gold | paper-deep status | Status lamps (≠ primary) |
| Element ink | kinetic…prismatic | paper contrast set | Identity cells only |

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

## Flutter host themes

Hosts map tokens via `destiny2_ui_flutter` / `buildFlapThemeBase`:

- `theme` = Paper Ledger (light), `darkTheme` = Cold Graphite (dark)
- `ThemeMode` system | dark | light; Settings **Appearance** cycles faces
- Explicit `ColorScheme` from tokens (not `ColorScheme.fromSeed`)
- `FlapPalette` ThemeExtension carries success/warning/element roles

Jaspr maps these tokens to CSS custom properties in `apps/web_host` via `argbToCssHex` — this package stays pure SDK.

## Tests

```powershell
dart test packages/ui_tokens
```

## Non-goals (this package)

- FlapRow / FlapBoard Flutter widgets — see **`packages/ui_flutter`** (`destiny2_ui_flutter`)  
- Full Settings/Catalog brand rewrite  
- Soft guidance auto-apply / domain rules  
- CLIENT_SECRET / network  
