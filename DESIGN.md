---
name: Destiny 2 Build Creator — Neon Network
description: Neon Network / Vex Network Interface language on dense FlapBoard libraries for intent→compose→equip; dual-face Flutter palettes (Neon void dark / cool technical light); cyan signal accent; Destiny element ink; soft spatial zoning—no cyan cages, no brushed steel.
design_system_id: "user:neon-network-design-system"
colors:
  background: "#05050f"
  surface: "#0a0a18"
  surface-raised: "#101028"
  line: "#e8eef238"
  line-strong: "#e8eef261"
  foreground: "#f0fdff"
  muted: "#7dd3e0"
  accent: "#00e5ff"
  accent-strong: "#00b8d4"
  accent-dim: "#00e5ff26"
  accent-secondary: "#ff1a8c"
  danger: "#ff003c"
  success: "#2ee6a6"
  warning: "#f5c542"
  element-kinetic: "#ffffff"
  element-arc: "#85c5ec"
  element-solar: "#f2721b"
  element-void: "#b184c5"
  element-stasis: "#4d88ff"
  element-strand: "#35e366"
  element-prismatic: "#d67ee2"
typography:
  display:
    fontFamily: "Orbitron, Electrolize, Rajdhani, system-ui, sans-serif"
    fontWeight: 600
    letterSpacing: "0.04em"
  body:
    fontFamily: "Inter, system-ui, -apple-system, Segoe UI, sans-serif"
    fontWeight: 400
    fontSize: "0.8125rem"
  mono:
    fontFamily: "JetBrains Mono, Share Tech Mono, ui-monospace, monospace"
    fontWeight: 400
  headline:
    fontFamily: "Orbitron, Electrolize, system-ui, sans-serif"
    fontSize: "1.125rem"
    fontWeight: 600
  title:
    fontFamily: "Orbitron, Electrolize, system-ui, sans-serif"
    fontSize: "0.8125rem"
    fontWeight: 600
    letterSpacing: "0.06em"
  label:
    fontFamily: "Orbitron, Electrolize, system-ui, sans-serif"
    fontSize: "0.6875rem"
    fontWeight: 600
    letterSpacing: "0.12em"
  label-xs:
    fontFamily: "Orbitron, Electrolize, system-ui, sans-serif"
    fontSize: "0.625rem"
    fontWeight: 600
    letterSpacing: "0.1em"
rounded:
  none: "0px"
  flap: "0px"
  max: "2px"
spacing:
  2: "2px"
  4: "4px"
  6: "6px"
  8: "8px"
  10: "10px"
  12: "12px"
  16: "16px"
  24: "24px"
  32: "32px"
  48: "48px"
  control-h: "40px"
  panel-sm: "8px"
  panel-md: "12px"
  panel-lg: "16px"
  page-x-sm: "8px"
  page-x: "20px"
  page-y-sm: "6px"
  page-y: "12px"
  flap-row-y: "6px"
  flap-gap: "0px"
components:
  button-accent:
    backgroundColor: "{colors.accent-dim}"
    textColor: "{colors.accent}"
    rounded: "{rounded.none}"
    padding: "6px 10px"
    typography: "{typography.label}"
  button-outline:
    backgroundColor: "transparent"
    textColor: "{colors.foreground}"
    rounded: "{rounded.none}"
    padding: "6px 10px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.muted}"
    rounded: "{rounded.none}"
    padding: "6px 10px"
  button-danger:
    backgroundColor: "transparent"
    textColor: "{colors.danger}"
    rounded: "{rounded.none}"
    padding: "6px 10px"
  button-sm:
    padding: "3px 8px"
  panel-default:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.foreground}"
    rounded: "{rounded.none}"
    padding: "{spacing.panel-md}"
  panel-raised:
    backgroundColor: "{colors.surface-raised}"
    textColor: "{colors.foreground}"
    rounded: "{rounded.none}"
    padding: "{spacing.panel-md}"
  chip-default:
    backgroundColor: "transparent"
    textColor: "{colors.muted}"
    rounded: "{rounded.none}"
    padding: "1px 6px"
  chip-accent:
    backgroundColor: "transparent"
    textColor: "{colors.accent}"
    rounded: "{rounded.none}"
    padding: "1px 6px"
  filter-chip-include:
    backgroundColor: "{colors.accent-dim}"
    textColor: "{colors.accent}"
    rounded: "{rounded.none}"
    padding: "3px 8px"
  filter-chip-exclude:
    backgroundColor: "color-mix(in srgb, #e2654f 10%, transparent)"
    textColor: "{colors.danger}"
    rounded: "{rounded.none}"
    padding: "3px 8px"
  input-default:
    backgroundColor: "{colors.surface-raised}"
    textColor: "{colors.foreground}"
    rounded: "{rounded.none}"
    padding: "5px 8px"
    height: "auto"
  flap-row:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.foreground}"
    rounded: "{rounded.none}"
    padding: "6px 8px"
---

# Design System: Neon Network

> **Supersedes** Matte Flap Ledger thermal/palette language (Cold Graphite / Paper Ledger).  
> **Keeps** FlapBoard layout contracts (rail width, row gap 0, fixed library columns).  
> **Source package:** Open Design `user:neon-network-design-system` (Neon Network / Vex Network Interface).

## Overview

**Creative North Star: "Neon Network"**

The product UI is a high-signal construct console over infinite void: modular floating zones, white/grey structural hairlines, and cyan-neon as interaction signal—not decoration. Libraries remain continuous **FlapBoard** rows you skim densely; compose is the selected construct expanded into the work floor.

Mood is cold digital logic made visible—precise, mechanical, weightless. Magenta is sparse secondary energy. Soft spatial zoning (gap → tonal step → gradient fade) beats outlined cyan cages. No brushed steel, no warm beige canvases, no purple SaaS gradients, no cozy consumer chrome.

Hard anti-references: cyan wireframe cages on every module; permanent dim-neon rest states; flat orthographic grid wallpapers; purple AI gradients; soft bounce motion; radius > 4px; light SaaS dashboards; DIM pixel-clone chrome.

**Key Characteristics:**
- Void canvas `#05050f`; elevated zones `#0a0a18` / `#101028`
- White/grey hairline structure; cyan signal ≤ ~2 strong hits per region
- Fixed-column **FlapRow** libraries (NAME · IDENTITY · EXOTICS · SYNERGY · STATUS)
- Destiny element + class color as cell ink only
- Status: danger `#ff003c` · success `#2ee6a6` · warn `#f5c542`
- Orbitron display · Inter body · JetBrains Mono metrics
- Radius 0 default (soft max 2px); control height 40
- Viewport-locked shell; dual-pane Workspace; independent scroll

## Colors

Flutter product dual-face: **Neon void** dark default + **cool technical** light. Board language (square, gap-0, element ink) is unchanged—atmosphere and signal lamp follow Neon Network.

### Dark face — Neon void (default)
Palette character: deep void, elevated modular zones, cyan-neon signal accent.

#### Primary (signal)
- **Cyan-neon** (`#00e5ff` / `--accent`): Selected wash, primary CTA, focus ring. Deep `#00b8d4`; soft wash `#00e5ff26`. Never body text floods or every hairline.

#### Secondary (status + sparse energy)
- **Success** (`#2ee6a6`): verified / healthy soft coverage  
- **Warn** (`#f5c542`): soft miss / fuzzy  
- **Danger** (`#ff003c`): illegal / exclude / hard block  
- **Magenta** (`#ff1a8c`): sparse secondary energy only  

#### Neutral (dark)
- **Void** `#05050f` · **Surface** `#0a0a18` · **Raised** `#101028`  
- **Rule** white/grey @ ~22% / strong @ ~38%  
- **Lettering** `#f0fdff` / **Muted** `#7dd3e0`

### Light face — Cool technical stage
Cool greys; cyan is signal chrome only (not body text on white). Still board-not-cards.

- **Stage** `#f4f7fb` · **Surface** `#ffffff` · **Inset** `#eef2f7`  
- **Rule** near-void ink hairlines · **Ink** `#0a0a18` / muted `#4a5a68`  
- **Accent** `#00c4db` (deep `#00a8bc`, soft wash)  
- **Status:** same success / warn / danger signals  

### Tertiary (sandbox elements — data authoritative, both faces)
- Dark board: Kinetic `#ffffff` · Arc `#85c5ec` · Solar `#f2721b` · Void `#b184c5` · Stasis `#4d88ff` · Strand `#35e366` · Prismatic `#d67ee2`
- Light board uses higher-contrast element set in `FlapColorTokens.light` (identity/seals only). Never recolor neutral chrome.

### Theme switching
- Flutter: `ThemeMode` **system** | **dark** (Neon void) | **light** (cool technical). Settings **Appearance** cycles System → Neon void → Cool technical.
- MaterialApp maps `theme` → light tokens, `darkTheme` → dark tokens; OS dark when preference is system.
- Tokens: `flutter/packages/ui_tokens` → Flutter `buildFlapThemeBase` + Jaspr `flapDarkCssVariables()`.

### Named Rules
**The No Steel Rule.** No brushed metal, chrome bezels, or metallic gradients.

**The No Cyan Cage Rule.** Structure is white/grey hairline (or tonal/gap zoning). Cyan is signal for selection, focus, and CTA—not module outlines by default.

**The One Signal Rule.** Strong cyan ≤ ~2 applications per view region. Status success never uses `ColorScheme.primary`. Magenta stays sparse.

**The Element Ink Rule.** Element hexes stay correct for damage-type truth; they tint identity cells, channel washes, and seals—not neutral chrome.

**The Channel Lattice Rule.** Flap rows may carry a `--flap-channel` CSS color for left lamp + hover/select wash. Dosage stays thin (~8–12% washes); full chroma only on icons, type stamps, and READY stamps.

**The Badge Wash Rule.** Status badges use ~10–12% fills and ~45% borders via `color-mix`.

## Typography

**Display / Board:** Orbitron (Electrolize / Rajdhani fallbacks) via `--font-display`  
**Body:** Inter via `--font-body`  
**Mono / metrics:** JetBrains Mono via `--font-mono`

### Hierarchy
- Page titles: condensed ~`text-lg`, uppercase tracking
- Section labels: condensed 10–11px uppercase tracking
- Flap cell text: condensed 11–13px uppercase or tight caps for names
- Body guidance: Plex Sans sentence case `text-sm`
- Tallies (V#, counts): mono 10–11px tabular

### Named Rules
**The Condensed Board Rule.** Interactive chrome and flap cells use condensed uppercase. Long guidance stays Plex sentence case.

**The Tally Mono Rule.** Variant counts, READY/HOLD, and numeric tallies use mono—not display costume on paragraphs.

## Layout

Spatial model unchanged in contract: **viewport-locked** shell; scroll in panes.

- **PageFrame:** max 1600px; denser padding (page-y 12 / panel-md 12)
- **Workspace:** dual-pane; library rail prefers **320px** on Sets/Synergy/Build for flap columns
- **Libraries:** zero-gap stacked FlapRows; 1px rules between rows—not card stacks with 8px gaps
- **Compose floor:** selected entity owns main; variants as dense strips/sections, not airy card grids when scanning
- **Chrome caps:** filter chrome still height-capped on narrow

### Named Rules
**The Viewport Lock Rule.** Document does not grow; panes scroll.

**The Board Not Cards Rule.** Library lists are ruled flap boards. Nested panels-inside-panels for each row are forbidden.

**The Focus Swap Rule.** Narrow: library XOR detail.

## Elevation & Depth

Tonal only: Void → Flap → Raised. No resting shadows. Hotspot popovers may use functional shadow when portaled.

### Named Rules
**The Flat Flap Rule.** Rows do not lift; selection is amber rule + wash, not shadow.

**The Portal Escape Rule.** Overlays portal above overflow clips.

## Shapes

**Square. No notches. No large radii.**

- Containers: 1px rule border, square corners
- Prior `.panel-notch` clip-path is retired from production chrome (class may remain as alias to square panel for one release)
- Controls/chips/inputs: square
- Flap cells: internal hairline dividers optional; no pills on core chrome

### Named Rules
**The Square Board Rule.** Primary containers are square matte plates.

**The No Soft Blob Rule.** No consumer pills on core chrome.

## Components

### Buttons
- Square; condensed uppercase
- Accent = amber badge wash; outline = rule border; ghost = muted; danger = coral

### FlapRow (signature)
- Full-width button/row with CSS grid columns per surface
- States: idle, hover (channel-tinted), selected (amber + channel wash + amber lamp), warning/danger lamps, optional `--flap-channel` identity ink
- Cells: name (truncate), identity (class/element icons in channel wash), exotics (gold seals 20–24px), synergy (verbs/types), status (READY/HOLD stamps)
- Type stamps: Weapon/Armor/Mod/Pair/Fashion category chroma

### Chips / Filters
- Square dense; include = amber wash; exclude = coral + line-through
- Prefer icon-first filters

### Panels
- Square matte; tones default/raised/accent/muted/danger/warning
- Pad sm/md/lg → 8/12/16 (denser than prior 12/16/20)

### Workspace / Page
- PageHeader tighter; WorkspaceMain default gap 12
- CardGrid gap-2; still available for multi-variant when needed

### Hotspots / Badges
- Unchanged contracts; visual skin follows matte + amber

## Do's and Don'ts

### Do:
- Compose from `src/components/ui` (Panel, FlapRow, Workspace, chips, hotspots)
- Put Sets/Synergy/Build libraries on FlapRow boards
- Use element/class color only on identity and seals
- Keep viewport lock and portal overlays
- Prefer 320px rails where flap columns need air

### Don't:
- Restore notched vault plates or dual radial "vault glow" as brand
- Introduce brushed steel, chrome, or metallic frames
- Nest a Panel inside every library row
- Spray amber or element color across every rule
- Use long condensed paragraphs for guidance copy
