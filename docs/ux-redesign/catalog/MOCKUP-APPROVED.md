# Catalog · Browse chrome — mockup approval

**continue with workflow**

Approved after interactive review of:

- `docs/ux-redesign/catalog/mockups/001-browse-chrome-desktop.html`
- `docs/ux-redesign/catalog/mockups/001-browse-chrome-mobile.html`

**Workflow:** `area-ux-redesign-8`  
**Date:** 2026-08-05  
**Gaps:** GAP-CAT-BROWSE-001 … 004 (`docs/ux-redesign/DUAL-TRUTH-GAPS.md`)

---

## Slice on this gate

**Catalog browse chrome** (windows + mobile structure SSoT)

1. **Family weapon cards** — one card per regular / Adept / Holofoil / … family  
2. **Collapsible group-by** sections  
3. **User sort priority reorder**  
4. **User group-by dimension priority reorder**  
5. **Weapon type filters as official type icons**  
6. **Group outline** for jump when grouping is applied  

**Out of scope:** live Set/Synergy CTAs, armor family as gate, inventing collectible graph without data, Catalog-as-home, new design system, selectable version chips on grid.

---

## Locked UX decisions

### Family cards (GAP-CAT-BROWSE-001)

| Rule | Decision |
| --- | --- |
| Grid identity | **One card per weapon family** (name-normalized + slot/element/type guard) |
| Card tap | Opens **primary** version detail (owned max-power if available, else base, else stable default) |
| Version chips on **grid card** | **Owned-only** indicators · **not selectable** · not version pickers |
| Unowned versions on card | **Do not** show as chips on the grid card |
| Detail | Shows **all** known family versions; owned clearly marked; user **switches inspected version on detail** (plugs/instances rebind) |
| Owned aggregate | Sum of version counts; honest tooltip breakdown OK |
| Filter | Family appears if **any** version matches; exclude drops family only if all versions excluded |

### Groups (GAP-CAT-BROWSE-002)

- Group headers **collapse / expand** (default expanded)  
- When grouping is on: **outline** of groups (label + count) for **quick jump** to section  
- Jump may expand a collapsed group  

### Sort & group priority (GAP-CAT-BROWSE-003)

- **Sort:** multi-key **priority list reorder** (e.g. Slot → Exotic → Ammo → Type → Name)  
- **Group-by:** multi-dimension **priority list reorder** (first = outer)  
- Pure logic in manifest; host holds order state  

### Weapon type filters (GAP-CAT-BROWSE-004)

- Type filters use **official weapon-type silhouettes** (`iconOnly`)  
- Full type name via tooltip + Semantics  
- Prefer visible/primary line (not buried text-only under More only)  

### Carry-forward

- Composition aid only (DBR-PUR-002)  
- Neon / Flap + official Destiny icons  
- Residual-polish perk detail rules still in force (not reopened this slice)  

Phrase required by workflow gate: continue with workflow
