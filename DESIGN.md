---
name: Destiny 2 Build Creator — Vault Terminal
description: Dark, notched arsenal console for intent→compose→equip; amber readiness, icon-dense chips, Destiny element color as data and atmosphere.
colors:
  background: "#0a0c10"
  surface: "#11151d"
  surface-raised: "#161b25"
  line: "#232b3a"
  line-strong: "#36415677"
  foreground: "#d9dee8"
  muted: "#8b94a7"
  accent: "#e8b86d"
  accent-strong: "#f5cf8e"
  accent-dim: "#e8b86d2c"
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
    fontFamily: "Chakra Petch, ui-sans-serif, system-ui, sans-serif"
    fontWeight: 600
    letterSpacing: "0.02em"
  body:
    fontFamily: "IBM Plex Sans, ui-sans-serif, system-ui, sans-serif"
    fontWeight: 400
    fontSize: "1rem"
  mono:
    fontFamily: "IBM Plex Mono, ui-monospace, monospace"
    fontWeight: 400
  headline:
    fontFamily: "Chakra Petch, ui-sans-serif, system-ui, sans-serif"
    fontSize: "1.125rem"
    fontWeight: 600
  title:
    fontFamily: "Chakra Petch, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.875rem"
    fontWeight: 600
    letterSpacing: "0.05em"
  label:
    fontFamily: "Chakra Petch, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.6875rem"
    fontWeight: 600
    letterSpacing: "0.14em"
  label-xs:
    fontFamily: "Chakra Petch, ui-sans-serif, system-ui, sans-serif"
    fontSize: "0.625rem"
    fontWeight: 600
    letterSpacing: "0.1em"
rounded:
  none: "0px"
  notch: "12px"
spacing:
  2: "2px"
  4: "4px"
  6: "6px"
  8: "8px"
  10: "10px"
  12: "12px"
  16: "16px"
  24: "24px"
  panel-sm: "12px"
  panel-md: "16px"
  panel-lg: "20px"
  page-x-sm: "8px"
  page-x: "24px"
  page-y-sm: "8px"
  page-y: "16px"
components:
  button-accent:
    backgroundColor: "{colors.accent-dim}"
    textColor: "{colors.accent}"
    rounded: "{rounded.none}"
    padding: "8px 12px"
    typography: "{typography.label}"
  button-outline:
    backgroundColor: "transparent"
    textColor: "{colors.foreground}"
    rounded: "{rounded.none}"
    padding: "8px 12px"
  button-ghost:
    backgroundColor: "transparent"
    textColor: "{colors.muted}"
    rounded: "{rounded.none}"
    padding: "8px 12px"
  button-danger:
    backgroundColor: "transparent"
    textColor: "{colors.danger}"
    rounded: "{rounded.none}"
    padding: "8px 12px"
  button-sm:
    padding: "4px 8px"
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
    padding: "2px 8px"
  chip-accent:
    backgroundColor: "transparent"
    textColor: "{colors.accent}"
    rounded: "{rounded.none}"
    padding: "2px 8px"
  filter-chip-include:
    backgroundColor: "{colors.accent-dim}"
    textColor: "{colors.accent}"
    rounded: "{rounded.none}"
    padding: "4px 8px"
  filter-chip-exclude:
    backgroundColor: "color-mix(in srgb, #e2654f 10%, transparent)"
    textColor: "{colors.danger}"
    rounded: "{rounded.none}"
    padding: "4px 8px"
  input-default:
    backgroundColor: "{colors.surface-raised}"
    textColor: "{colors.foreground}"
    rounded: "{rounded.none}"
    padding: "6px 8px"
    height: "auto"
---

# Design System: Vault Terminal

## Overview

**Creative North Star: "Silent Fireteam Ops"**

The product UI is a quiet after-action kit desk: spare, precise, and instrument-grade, lit like a vault console after the fireteam is already home. Surfaces are angular notched plates on deep charcoal; type is tight and uppercase where it marks controls; chips and entity icons carry density so the player can scan gear truth without hunting chrome.

The mood leans **richer Destiny fan-UI** than a sterile ops dashboard: soft ambient vault glows in the page background, amber readiness accents, and permission to use elemental color as atmospheric glow and section ornament—not only as strict data labels. Ornament still serves readiness and identity (exotic, element, class, coverage), never carnival noise. Depth stays tonal and flat-by-default; shadows are rare and functional (e.g. portaled hotspots), not card float.

Hard anti-references: light-mode SaaS pastel dashboards; DIM pixel-clone as a design goal; rounded friendly-consumer blobs and thick universal drop shadows; generic AI purple-gradient hero aesthetics.

**Key Characteristics:**
- Dark vault field with dual radial atmosphere and notched plate surfaces
- Single product accent (amber) for readiness/selection; status greens/reds/ambers for system state
- Destiny element palette for real damage-type data **and** restrained decorative glow
- Chakra Petch display + IBM Plex Sans body + IBM Plex Mono for operator detail
- Viewport-locked shell: dual-pane Workspace/Catalog, independent scroll regions
- Icon-first entity language (ItemIcon, designation glyphs, filter icons)
- Compose via Vault Terminal primitives (`src/components/ui`) — no one-off panel chrome

## Colors

Palette character: cold void-steel neutrals with a single warm **readiness amber**, plus official-adjacent Destiny damage-type hues for sandbox truth and allowed atmospheric tint.

### Primary
- **Readiness Amber** (`#e8b86d` / `--accent`): Selection, primary CTAs (badge-style), include-mode filters, keylines, pinned hotspot borders. Stronger face (`#f5cf8e` / `--accent-strong`) for emphasis; wash (`#e8b86d2c` / `--accent-dim`) for fills and badge grounds.

### Secondary
- Omitted as a second brand accent. **Status** colors fill the secondary communication role:
  - **Signal Green** (`#6fc28b` / `--success`): verified / healthy coverage
  - **Caution Gold** (`#d9a93f` / `--warning`): fuzzy, soft miss, attention
  - **Breach Coral** (`#e2654f` / `--danger`): illegal, exclude-mode filters, hard blockers

### Tertiary
- **Sandbox Elements** (data-authoritative; may tint decoration):
  - Kinetic `#ffffff` · Arc `#85c5ec` · Solar `#f2721b` · Void `#b184c5` · Stasis `#4d88ff` · Strand `#35e366` · Prismatic `#d67ee2`
  - Use full strength on icons, MetaChips, and entity accents tied to real damage/class typing. Decorative glow/section washes should stay low-opacity mixes so amber readiness still wins the hierarchy.

### Neutral
- **Void Field** (`#0a0c10` / `--background`): App canvas under atmospheric radials
- **Plate** (`#11151d` / `--surface`): Default notched panel body
- **Raised Plate** (`#161b25` / `--surface-raised`): Nested/raised panels, inputs, hotspot popovers
- **Seam** (`#232b3a` / `--line`): Default 1px borders
- **Seam Strong** (`#36415677` / `--line-strong`): Softer structural dividers when needed
- **Readout** (`#d9dee8` / `--foreground`): Primary text
- **Dim Readout** (`#8b94a7` / `--muted`): Labels, secondary copy, idle chips

### Named Rules
**The One Amber Rule.** Product accent amber is the only non-status brand accent. It marks readiness, selection, and primary action—not every heading and border.

**The Element Truth Rule.** Element hexes always remain correct for real damage-type data. Decorative elemental glow is allowed but must not recolor neutral chrome or impersonate selection amber.

**The Badge Wash Rule.** Status and accent badges use low-opacity fills (`~10–12%`) plus mid-opacity borders (`~45%`) via `color-mix`—never solid candy blocks.

## Typography

**Display Font:** Chakra Petch (via `--font-display`; weights 500/600/700)  
**Body Font:** IBM Plex Sans (via `--font-body`; weights 400/500/600)  
**Label/Mono Font:** IBM Plex Mono (via `--font-mono`; weights 400/500)

**Character:** Angular technical display against calm industrial body type—ops briefing titles with readable inventory prose. Controls and section labels speak in tight uppercase tracking; body stays sentence case.

### Hierarchy
- **Display / Page title** (Chakra, ~`text-lg`, medium weight, slight tracking): `Heading` level 1 — page names only.
- **Headline / Section accent** (Chakra, ~`text-sm`, uppercase, wide tracking, accent color): `Heading` level 2 — in-panel section titles that need amber pull.
- **Title / Micro label** (Chakra, `11px` / `0.6875rem` common; `10px` dense, uppercase, `tracking-[0.14em]`, muted): `Heading` level 3, `SectionLabel`, badge text, panel section titles — structural labels.
- **Body** (Plex Sans, `text-base` / `text-sm` / `text-[11px]`): `Text` sizes md/sm/xs — descriptions, coverage copy, form values.
- **Label / Control** (Chakra-flavored via badge/button classes, `10–11px`, uppercase, `tracking-widest`): Buttons, filter chips, badges — action chrome.

### Named Rules
**The Uppercase Instrument Rule.** Interactive chrome (buttons, filter chips, badges, section labels) defaults to uppercase + wide tracking. Long-form guidance and descriptions stay sentence case in Plex Sans.

**The Display Restraint Rule.** Chakra Petch is for titles, labels, and badges—not long paragraphs.

## Layout

Spatial model: **viewport-locked app shell** (`h-dvh`, `overflow-hidden`). Document does not grow; each page fills remaining main height via `PageFrame` → chrome (shrink-0) + body (`flex-1 min-h-0`).

- **PageFrame:** `max-w-[1600px]` wide product default; Settings may use `max-w-3xl`. Horizontal padding `8px` → `24px` from `sm`; vertical `8px` → `16px`.
- **Workspace (master–detail):** Below `lg` (1024px), library-or-detail focus (`focusMain`); at `lg+`, CSS grid dual-pane with rail widths **240 / 280 / 320px** and independent scroll. Gap `8px` mobile / `16px` desktop.
- **Catalog body:** Same master–detail contract; dual-pane only when an item is selected at `lg+`.
- **CardGrid:** `gap-3`; 1 col → `md` 2 cols → `xl` 3 cols.
- **Stack rhythm:** Prefer `Stack`/`Row`/`Cluster` gaps from the shared scale (2–24px). Default stack gap `12px`; section internals often `6px`; clusters of chips `6px`.
- **Chrome caps:** Page filter/title chrome height-capped on narrow (`max-h ~28dvh / 12rem`) so lists stay usable.

### Named Rules
**The Viewport Lock Rule.** Do not let page content expand `document` height. Scroll inside panes (`overflow-y-auto overscroll-contain`), not the body.

**The Focus Swap Rule.** On narrow viewports, library and detail never fight for half a phone—one owns the column; back control returns to library.

## Elevation & Depth

Depth is **tonal layering first**: Void Field → Plate → Raised Plate, separated by 1px seams. Panels are flat at rest. The page background adds two soft radial atmospheres (cool steel washes), not card shadows. Portaled hotspots may use a strong shadow (`shadow-xl`) because they float above clipped plates.

### Shadow Vocabulary
- **Hotspot float** (`box-shadow` via Tailwind `shadow-xl` on raised notched popovers): Only for portaled overlays that must clear `clip-path` panels.
- **No resting card shadow:** Default `Panel` / list rows do not lift with ambient shadow.

### Named Rules
**The Flat Plate Rule.** Surfaces stay flat; elevation is a darker/lighter plate or a border tone shift, not a universal drop shadow.

**The Portal Escape Rule.** Anything that must overlay notched panels (hotspots, menus) portals to `document.body` so `clip-path` cannot crop it.

## Shapes

Form language: **angular plates with 45° opposite notches**, square corners everywhere else, hairline borders. No large continuous radii on product chrome.

- **Signature silhouette:** `.panel-notch` clip-path notches **12px** on top-left and bottom-right corners (bevel language, not rounded-md).
- **Controls/chips/inputs:** Square corners (`rounded.none`); 1px `border-line` or tonal border.
- **Keyline:** 1px horizontal gradient under headers — amber → transparent (~70%).
- **Badges:** Square, bordered, tiny padding; wash fill.

### Named Rules
**The Notch Signature Rule.** Primary containers use the notched plate. Do not replace it with generic rounded cards on production surfaces.

**The No Soft Blob Rule.** Avoid large border-radius “consumer app” shapes and pill-everything patterns on core chrome (pills only if a specific control already establishes them).

## Components

Character line: **instrument-grade and icon-dense** — chips, filter icons, and hotspots carry scan weight; buttons stay badge-like and quiet until amber.

### Buttons
- **Shape:** Square; no radius. Uppercase, wide tracking.
- **Primary (`accent`):** Amber badge treatment (`.badge.badge-accent`) — accent text, translucent amber wash, accent-tinted border; hover opacity ~90%.
- **Outline (default):** Transparent, `border-line`, foreground text; hover border → accent.
- **Ghost:** Muted text; hover → foreground. Used for back-to-library and low emphasis.
- **Danger:** Danger text + `border-danger/40`; hover wash `bg-danger/10`.
- **Sizes:** `sm` `px-2 py-1 text-[10px]`; `md` `px-3 py-2 text-[11px]`.

### Chips
- **Chip / MetaChip:** `10px`, tracking-wide, 1px border, square; idle = line + muted; accent = accent border/text; MetaChip may take **element accentColor** for border/text; icon-only dense padding allowed.
- **FilterChip:** Uppercase instrument control; modes **off / include / exclude** (include = amber wash; exclude = danger + line-through). Supports icon-only and `xs` dense catalog toolbars; optional `activeStyle` for element-colored include states.
- **ConceptTagChip / ClassFilterChip / DesignationLabel:** Prefer official icons + color maps; text fallback when art missing.

### Cards / Containers
- **Panel:** Always notched; tones `default | raised | accent | muted | danger | warning`; pad `none|sm|md|lg` → 0/12/16/20px.
- **EmptyState:** Muted raised plate, calm copy, optional action.
- **Callout:** Panel tone mapped from info/success/warning/danger; small medium-weight title + sm body.

### Inputs / Fields
- **Style:** Full-width raised plate fill, 1px line border, `px-2 py-1.5`, `text-sm` foreground; square.
- **Label:** Muted xs text above control.
- **Focus:** Prefer browser/focus-visible consistency with border → accent when extending; do not invent thick glow rings that fight notches.

### Navigation
- **AppShell:** Full viewport column; main is `flex-1 min-h-0 overflow-hidden`. Top/side nav stays compact; short labels on small widths; horizontal scroll with scrollbar hidden where needed (`.scrollbar-none`).
- Active route should read with amber or stronger foreground—not a bright filled tab blob.

### Workspace / Page structure
- **PageHeader:** Title + optional muted description (`max-w-2xl`, line-clamp on narrow) + actions cluster.
- **Workspace + WorkspaceMain + CardGrid:** Canonical dual-pane feature layout; Build page is the reference composition.
- **Section + SectionLabel:** Labeled blocks inside panels; optional trailing action.

### Signature: InfoHotspot / EntityHotspot
- Hover opens, click pins; **single active hotspot** globally.
- Popover: portaled, raised notched plate, min ~240–300px, optional ItemIcon 36px + accent ring, kind label uppercase muted, pin uses accent border.
- EntityHotspot: icon-first chip; prefers art over name when available.

### Badges
- **Component:** `Badge` in `src/components/ui/Badge.tsx` (`tone`: `verified` | `accent` | `fuzzy` | `warning` | `unresolved` | `illegal` | `danger`).
- Shared `.badge` CSS system for verified / accent / fuzzy / unresolved / illegal — display font, uppercase, tiny, wash fills. Prefer the React primitive over raw `badge badge-*` classes in feature code.

## Do's and Don'ts

### Do:
- **Do** compose production screens from `src/components/ui` primitives (`Panel`, `Workspace`, `Button`, `FilterChip`, `Text`/`Heading`, hotspots) instead of raw `panel-notch` one-offs.
- **Do** keep the page viewport-locked; put scroll on rails, mains, and lists.
- **Do** use amber for selection/readiness and status colors for system truth; use element colors on real sandbox typing and restrained atmospheric tint.
- **Do** prefer official item/designation/filter icons and icon-dense chips for scanability.
- **Do** portal overlays that must escape notched clip-paths.
- **Do** preserve square instrument chrome and the 12px opposite-corner notch on primary plates.

### Don't:
- **Don't** introduce light-mode SaaS layouts, soft pastel cards, or airy white dashboards as the default product skin.
- **Don't** treat pixel-perfect DIM clone as a design goal (parity of *information* is fine; chrome is Vault Terminal).
- **Don't** round everything into friendly consumer pills or bury plates in thick universal drop shadows.
- **Don't** ship generic AI purple-gradient heroes or decorative glassmorphism as brand identity.
- **Don't** spray amber or elemental color across every border until selection and damage-type truth stop reading.
- **Don't** let long Chakra display paragraphs replace Plex body for guidance copy.
- **Don't** auto-animate attention (beyond rare functional pulses like progress) in a way that fights Silent Fireteam calm.
