# UI iteration with Widgetbook

Use Widgetbook when polishing **look, layout, and component states**. Use `windows_host` when you need OAuth, inventory, or full Catalog flows.

## Daily loop (recommended)

### 1. Start Widgetbook once (leave it running)

```powershell
cd flutter/apps/widgetbook   # or C:\d2f\apps\widgetbook
.\run-windows.ps1 -SkipPubGet   # after first successful launch of the day
```

Or from the IDE: **Run and Debug → `widgetbook`**.

Keep that terminal open. Hot reload is what makes UI work fast.

### 2. Edit real UI code (not host pages)

| Edit here | Why |
| --- | --- |
| `packages/ui_flutter/lib/src/catalog/**` | Catalog chrome (cards, filter bar, detail, …) |
| `packages/ui_flutter/lib/src/neon_*.dart`, `flap_*.dart` | Shared Neon / Flap primitives |
| `packages/ui_tokens/**` | Colors, density constants (often needs **hot restart**) |
| `apps/widgetbook/lib/use_cases/**` | Stories / fixtures / knobs only |
| `apps/widgetbook/lib/fixtures/**` | Demo data for edge states |

Avoid bouncing through `windows_host` for pure visual tweaks.

### 3. Refresh the running app

In the **Widgetbook** terminal (or Debug Console):

| Key | When |
| --- | --- |
| **`r`** hot reload | Body/style/layout of an existing widget |
| **`R`** hot restart | Constructor changes, new fields, theme init, tokens |
| full re-run | Only after `-Clean`, dependency changes, or broken engine |

Then pick the matching story in the left nav (search helps).

### 4. New story / renamed use case

`@UseCase` files are code-generated. In a **second** terminal:

```powershell
cd flutter/apps/widgetbook
dart run build_runner watch -d
# or one-shot: .\run-windows.ps1 -Gen   (next launch)
```

Then hot restart Widgetbook (`R`).

### 5. Nav layout, knobs & viewports

Tree shape (each component owns its fixed stories + a **Knobs** subgroup):

```text
[Catalog]
  Cards/                 item cards (fixed states)
  Cards/Knobs/           interactive NeonItemCard
  Cards/Family/          family cards (Base/Adept, signed-out, …)
  Cards/Family/Knobs/    owned / signed-out / adept
  Meta/ + Meta/Knobs/
  Detail/, FilterBar/, …
[Neon]
  Atmosphere/ + Atmosphere/Knobs/
  Board/
```

- **Knobs** panel — only on `…/Knobs` stories (element / slot / owned, etc.)  
- **Viewport** addon — None · iPhone 13 · iPad · Windows Desktop  
- **Theme** addon — Flap Dark / Light  

Use knobs before inventing new boolean flags in widgets. Keep fixed stories for named dual-truth states.

## Faster options

| Goal | Command |
| --- | --- |
| Fidelity (default) | `.\run-windows.ps1` or `-SkipPubGet` |
| Faster cold start (web) | `.\run-windows.ps1 -Device chrome -SkipPubGet` |
| After bad Windows build | `.\run-windows.ps1 -Clean` |
| Driver / agent screenshots | `.\run-windows.ps1 -EnableFlutterDriver` |
| IDE | Launch config **`widgetbook`** (and **`widgetbook (Driver)`**) |

Chrome is quicker to start; Windows is closer to the product shell. Prefer Windows when judging density/chrome.

## Mental model

```text
  fixtures + use_cases  ──►  Widgetbook story  ──►  your eye / knobs
         │                         ▲
         │                         │ hot reload r / R
         ▼                         │
  packages/ui_flutter  ────────────┘
         │
         └── same widgets used by windows_host / mobile_host
```

Host remains the dual-truth gate; Widgetbook is the **tight loop**.

## Windows console noise (`accessibility_bridge.cc`)

Those logs usually come from **shared UI** (`destiny2_ui_flutter` / host icons),
not Widgetbook chrome: nested `Semantics`/`Tooltip`/`FilterChip`, and especially
`Image.network` (which always publishes an image node unless
`excludeFromSemantics: true`). Prefer fixing the widget; only silence as a last
resort:

```powershell
flutter run -d windows --dart-define=EXCLUDE_WIDGETBOOK_SEMANTICS=true
```

After a11y-related widget changes, **hot restart (`R`)** or relaunch.

## Smoke tests (optional, while iterating)

```powershell
cd flutter/apps/widgetbook
flutter test
```

Does not replace looking at the story, but catches throw-on-build regressions.

## When to leave Widgetbook

- OAuth / inventory / owned real data  
- Navigation between product surfaces  
- Dual-truth Capture shots for area-implement  

Then: `flutter/apps/windows_host/run-windows.ps1`.
