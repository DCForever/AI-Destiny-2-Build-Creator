# destiny2_ui_tokens (DART-029)

Shared **neutral readable** design tokens and **FlapBoard layout contracts** for the multiplatform Dart port.

| Property | Value |
| -------- | ----- |
| Pub name | `destiny2_ui_tokens` |
| Path | `packages/ui_tokens` |
| Runtime deps | **SDK only** (no Flutter / Jaspr / IO) |
| Source of truth (product design) | repo root [`DESIGN.md`](../../DESIGN.md) (palette values live here) |

## Why pure Dart?

Port architecture ([docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)): shells do **not** share one widget tree. Flutter Windows, Flutter mobile, and Jaspr web share **tokens + layout contracts** only. ARGB ints map to `Color(...)` or CSS hex without pulling Flutter into Jaspr.

## Colors

**Dual face (Flutter product choice):**

| Face | Mode | Character |
| ---- | ---- | --------- |
| **Neutral stage** | light (**default**) | Whites / greys / black ink; charcoal CTA `#1a1a1a` |
| **Neutral charcoal** | dark | Blacks / greys; light-grey CTA `#e0e0e0` |

| Token | Dark (Neutral charcoal) | Light (Neutral stage) | Role |
| ----- | ----------------------- | --------------------- | ---- |
| `background` | `#121212` | `#f5f5f5` | Canvas / stage |
| `surface` | `#1e1e1e` | `#ffffff` | Elevated zone |
| `surfaceRaised` | `#2a2a2a` | `#eeeeee` | Nested / inset |
| `line` / `lineStrong` | white hairline @22%/38% | black hairline @16%/28% | Structure |
| `foreground` / `muted` | `#f5f5f5` / `#a3a3a3` | `#111111` / `#595959` | Lettering (AA body) |
| `accent` | `#e0e0e0` | `#1a1a1a` | Selection / focus / CTA |
| `danger` / `success` / `warning` | `#ff003c` / `#2ee6a6` / `#f5c542` | same status set | Status (≠ primary); warn = cap |
| Element ink | kinetic…prismatic | contrast set | Identity cells only |
| Exotic gold | `#ceae33` | same | Rarity wash |

```dart
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';

final stage = FlapColorTokens.light.background; // 0xFFF5F5F5
final css = argbToCssHex(kFlapAccentLight);    // #1a1a1a
```

API names (`kFlap*`, `FlapColorTokens`) remain for host compatibility.

## Spacing & radii

- Density scale: 4, 8, 12, 16, 24, 32, 48 (+ board extras 2/6/10).
- Control height seed: **40**.
- **Flap row gap = 0** (board not cards).
- **Radii default = 0**; soft max **2px** (hard cap 4px).

## Typography

Family names + metrics only — **fonts not bundled** in this package:

- Display: Orbitron (Electrolize / Rajdhani fallbacks)  
- Body: Inter  
- Metrics: JetBrains Mono  

## FlapBoard layout contracts

Not widgets — constants for library boards (unchanged structure):

| Contract | Value |
| -------- | ----- |
| Library rail width | `320` |
| Row gap | `0` |
| Rule thickness | `1` |
| Page frame max | `1600` |
| Column templates | `sets`, `synergy`, `builds` (see `flap_board_layout.dart`) |

### Board anti-rules (do not regress)

- **No colored cages** — structure is white/grey hairline; accent is chrome only  
- **Board not cards** — no nested elevated panels per library row  
- **One strong signal** — accent for selection/focus/CTA, not every border  
- **Element ink** — Destiny colors on identity/seals only  
- **Semantic color** — exotic gold, element ink, cap warning stay meaningful  
- **No soft consumer chrome** — radius ≤ 2px (cap 4px)  

## Flutter host themes

Hosts map tokens via `destiny2_ui_flutter` / `buildFlapThemeBase`:

- `theme` = Neutral stage (light, **default**), `darkTheme` = Neutral charcoal
- `ThemeMode` defaults to **light**; Settings **Appearance** cycles faces
- Explicit `ColorScheme` from tokens (not `ColorScheme.fromSeed`)
- `FlapPalette` ThemeExtension carries success/warning/element roles

Jaspr maps these tokens to CSS custom properties in `apps/web_host` via `argbToCssHex` — this package stays pure SDK.

## Tests

```powershell
dart test packages/ui_tokens
```

## Non-goals (this package)

- FlapRow / FlapBoard Flutter widgets — see **`packages/ui_flutter`** (`destiny2_ui_flutter`)  
- Environment stage photo / signal-fade motion (host chrome later)  
- Soft guidance auto-apply / domain rules  
- CLIENT_SECRET / network  
