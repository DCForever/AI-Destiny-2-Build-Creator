# destiny2_ui_tokens (DART-029)

Shared **Neon Network** design tokens and **FlapBoard layout contracts** for the multiplatform Dart port.

| Property | Value |
| -------- | ----- |
| Pub name | `destiny2_ui_tokens` |
| Path | `packages/ui_tokens` |
| Runtime deps | **SDK only** (no Flutter / Jaspr / IO) |
| Source of truth (product design) | repo root [`DESIGN.md`](../../DESIGN.md) |
| Open Design system id | `user:neon-network-design-system` |

## Why pure Dart?

Port architecture ([docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md)): shells do **not** share one widget tree. Flutter Windows, Flutter mobile, and Jaspr web share **tokens + layout contracts** only. ARGB ints map to `Color(...)` or CSS hex without pulling Flutter into Jaspr.

## Colors

**Dual face (Flutter product choice):**

| Face | Mode | Character |
| ---- | ---- | --------- |
| **Neon void** | dark (default) | Void canvas `#05050f`, cyan-neon signal `#00e5ff` |
| **Cool technical** | light | Cool greys, cyan signal chrome only (`#00c4db`) |

| Token | Dark (Neon void) | Light (Cool technical) | Role |
| ----- | ---------------- | ---------------------- | ---- |
| `background` | `#05050f` | `#f4f7fb` | Void / stage |
| `surface` | `#0a0a18` | `#ffffff` | Elevated zone |
| `surfaceRaised` | `#101028` | `#eef2f7` | Nested / inset |
| `line` / `lineStrong` | white/grey hairline @22%/38% | ink hairline @14%/22% | Structure (not cyan cages) |
| `foreground` / `muted` | `#f0fdff` / `#7dd3e0` | `#0a0a18` / `#4a5a68` | Lettering |
| `accent` | `#00e5ff` | `#00c4db` | Signal / selection / focus |
| `danger` / `success` / `warning` | `#ff003c` / `#2ee6a6` / `#f5c542` | same status set | Status (≠ primary) |
| Element ink | kinetic…prismatic | contrast set | Identity cells only |

```dart
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';

final voidBg = FlapColorTokens.dark.background; // 0xFF05050F
final css = argbToCssHex(kFlapAccentDark);      // #00e5ff
```

API names (`kFlap*`, `FlapColorTokens`) remain for host compatibility; values are Neon Network.

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

- **No cyan cages** — structure is white/grey hairline; cyan is signal only  
- **Board not cards** — no nested elevated panels per library row  
- **One strong signal** — cyan for selection/focus/CTA, not every border  
- **Element ink** — Destiny colors on identity/seals only  
- **No soft consumer chrome** — radius ≤ 2px (cap 4px)  

## Flutter host themes

Hosts map tokens via `destiny2_ui_flutter` / `buildFlapThemeBase`:

- `theme` = cool technical (light), `darkTheme` = Neon void (dark)
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
- Environment stage photo / signal-fade motion (host chrome later)  
- Soft guidance auto-apply / domain rules  
- CLIENT_SECRET / network  
