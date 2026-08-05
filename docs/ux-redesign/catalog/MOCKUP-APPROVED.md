# Catalog · Residual polish — mockup approval

**continue with workflow**

Approved after interactive review of:

- `docs/ux-redesign/catalog/mockups/001-residual-polish-desktop.html`
- `docs/ux-redesign/catalog/mockups/001-residual-polish-mobile.html`

**Workflow:** `area-ux-redesign-7`  
**Date:** 2026-08-04  
**Dual ground truth:** `implementation-shots/001-full/` + `COMPARE.md` residuals + prior 001-full mockups

---

## Slice on this gate

**Catalog residual polish** (windows + mobile chrome SSoT)  
Close COMPARE gaps after 001-full implement: meta strip density, type silhouettes, ③ header polish @400, Enhanced host map (instance), soft catalyst honesty, enhance/craft presentation rules.

**Out of scope:** greenfield redesign, armor optimizer, live Set/Synergy weapons CTAs, mobile Catalog push as gate, Confidential OAuth implement, inventing plugs/origin/craft, new design system.

---

## Locked UX decisions (residual polish)

### Perk tiers (unchanged from 001-full)

| Tier | Name | Meaning | Visual |
| --- | --- | --- | --- |
| **①** | **Selected** | On this owned instance | Blue fill, badge `1` |
| **②** | **Unselected** | Other options on this owned instance | Solid + gold chevron, badge `2` |
| **③** | **Possible rolls** | Weapon definition can-roll pool | Dashed muted, badge `3` |

### Enhanced (refined this gate)

| Context | Behavior |
| --- | --- |
| **① / ②** (owned instance) | Gold ring + **E** when *this copy’s* plug is enhanced (`plugEnhancedByHash` / host map) |
| **③ Possible rolls**, **unowned**, **Possible crafted** | **One cell per perk identity** — never base + enhanced as two cells |
| Same definition pools | **Note only:** “Can be enhanced” when pool supports it — **no E cells** |
| Future | Description popup compares base vs enhanced (not cell chrome) |

### Possible crafted (refined this gate)

- Same design as **Possible rolls**: toggle **OFF by default**, equal-width dashed ③-style cells, not a bullet list
- Toggle hidden until `craftAvailable` + `craftColumns` exist
- Same enhance rules as ③ (note only, no duplicate cells)

### Residual chrome locks

- Meta: fixed **22×22** chips · horizontal strip (not full-width bars)
- Type: official silhouettes · letter last-resort · never invent art
- ③ ON headers: ellipsis + Tooltip + Semantics @400 · no widen / no H-scroll
- Soft catalyst: omit when empty · display-only when present
- Owned default: ①+② only · ③ OFF · unowned ③-only
- Origin only when data exists
- Stub outbound Set/Synergy only
- Mock structure SSoT; implement uses official Destiny icons + Neon/Flap

### Prior 001-full decisions still in force

- Icon-only meta strip (type · frame · element · slot · ammo + ×N)
- Equal-width perk columns; no H-scroll at ~400px detail
- Composition aid only (DBR-PUR-002)

Phrase required by workflow gate: continue with workflow
