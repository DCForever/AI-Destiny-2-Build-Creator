---
name: Destiny 2 Build Creator — Matte Flap Ledger
description: Void-black matte split-flap board for intent→compose→equip; fixed-column dense libraries, Destiny element ink, amber readiness lamps—no brushed steel.
colors:
  background: "#050608"
  surface: "#0c0e12"
  surface-raised: "#12151c"
  line: "#1c212c"
  line-strong: "#2a3140"
  foreground: "#e8eaef"
  muted: "#8a93a6"
  accent: "#e6b35c"
  accent-strong: "#f0c878"
  accent-dim: "#e6b35c24"
  danger: "#e2654f"
  success: "#6fc28b"
  warning: "#d9a93f"
  element-kinetic: "#ffffff"
  element-arc: "#85c5ec"
  element-solar: "#f2721b"
  element-void: "#b184c5"
  element-stasis: "#4d88ff"
  element-strand: "#35e366"
  element-prismatic: "#d67ee2"
typography:
  display:
    fontFamily: "Barlow Condensed, ui-sans-serif, system-ui, sans-serif"
    fontWeight: 600
    letterSpacing: "0.04em"
  body:
    fontFamily: "IBM Plex Sans, ui-sans-serif, system-ui, sans-serif"
    fontWeight: 400
    fontSize: "0.9375rem"
  mono:
    fontFamily: "IBM Plex Mono, ui-monospace, monospace"
    fontWeight: 400
  headline:
    fontFamily: "Barlow Condensed, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.125rem"
    fontWeight: 600
  title:
    fontFamily: "Barlow Condensed, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.8125rem"
    fontWeight: 600
    letterSpacing: "0.08em"
  label:
    fontFamily: "Barlow Condensed, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.6875rem"
    fontWeight: 600
    letterSpacing: "0.12em"
  label-xs:
    fontFamily: "Barlow Condensed, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.625rem"
    fontWeight: 600
    letterSpacing: "0.1em"
rounded:
  none: "0px"
  flap: "0px"
spacing:
  2: "2px"
  4: "4px"
  6: "6px"
  8: "8px"
  10: "10px"
  12: "12px"
  16: "16px"
  24: "24px"
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

# Design System: Matte Flap Ledger

## Overview

**Creative North Star: "Matte Flap Ledger"**

The product UI is a void-black split-flap departure board with the metal chassis torn off: only matte flap faces, ruled columns, and ink. Libraries are not card stacks—they are continuous boards of fixed cells you skim like a concourse board at rush hour. Compose is the selected row expanded into the work floor; tools hang on a quiet perimeter rail.

Mood is dense, chromatic where Destiny truth lives (class, element, exotic seals), and restrained everywhere else. Amber is a readiness lamp, not a brand flood. No brushed steel, no chrome bezels, no notched vault plates, no warm amber-on-charcoal "ops terminal" nostalgia from the prior world.

Hard anti-references: Vault Terminal notches and dual radial glows; brushed metal instrument bezels; light SaaS dashboards; DIM pixel-clone chrome; purple AI gradients; sports-score neon yellow floods.

**Key Characteristics:**
- Void-black matte field; hairline rules; square everything
- Fixed-column **FlapRow** libraries (NAME · IDENTITY · EXOTICS · SYNERGY · STATUS)
- Destiny element + class color as cell ink only
- Amber readiness / selection lamps; status coral/green/gold
- Barlow Condensed for board type; IBM Plex Sans body; IBM Plex Mono tallies
- Viewport-locked shell; dual-pane Workspace; independent scroll
- Icon seals for exotics; designation glyphs for synergy verbs

## Colors

Palette character: colder and blacker than the prior vault—pure matte void with white flap lettering and rare lamps.

### Primary
- **Readiness Amber** (`#e6b35c` / `--accent`): Selected row, primary CTA wash, include filters, READY stamp. Stronger face `--accent-strong`; wash `--accent-dim`.

### Secondary (status lamps)
- **Signal Green** (`#6fc28b`): verified / healthy
- **Caution Gold** (`#d9a93f`): soft miss / fuzzy
- **Breach Coral** (`#e2654f`): illegal / exclude / hard block

### Tertiary (sandbox elements — data authoritative)
- Kinetic `#ffffff` · Arc `#85c5ec` · Solar `#f2721b` · Void `#b184c5` · Stasis `#4d88ff` · Strand `#35e366` · Prismatic `#d67ee2`
- Full strength on icons and identity cells. Never recolor neutral chrome.

### Neutral (dark default)
- **Void** `#050608` canvas
- **Flap** `#0c0e12` surface
- **Raised flap** `#12151c`
- **Rule** `#1c212c` / **Rule strong** `#2a3140`
- **Lettering** `#e8eaef` / **Dim** `#8a93a6`

### Theme switching
- Preferences: **dark** | **light** | **system** (`localStorage` key `d2bc-theme`).
- Resolved theme on `html[data-theme="dark"|"light"]`; preference on `data-theme-pref`.
- Light ledger remaps neutrals to paper board (`#e8e6e1` field / `#f4f2ec` plates) and deepens accent/status for AA on light surfaces; Destiny element hexes stay sandbox-true at higher contrast on paper.
- Shell **ThemeToggle** cycles Dark → Light → System. Default preference is system (resolved dark when OS is dark).

### Named Rules
**The No Steel Rule.** No brushed metal, chrome bezels, or metallic gradients. Matte only.

**The One Lamp Rule.** Amber marks readiness and selection—not every border. Channel lamps may show element/class ink on idle rows; amber always wins when selected.

**The Element Ink Rule.** Element hexes stay correct for damage-type truth; they tint identity cells, channel washes, and seals—not neutral chrome.

**The Channel Lattice Rule.** Flap rows may carry a `--flap-channel` CSS color for left lamp + hover/select wash. Dosage stays thin (~8–12% washes); full chroma only on icons, type stamps, and READY stamps.

**The Badge Wash Rule.** Status badges use ~10–12% fills and ~45% borders via `color-mix`.

## Typography

**Display / Board:** Barlow Condensed (500/600/700) via `--font-display`  
**Body:** IBM Plex Sans via `--font-body`  
**Mono / tallies:** IBM Plex Mono via `--font-mono`

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
