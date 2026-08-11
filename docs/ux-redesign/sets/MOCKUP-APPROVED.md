# Mockup approvals — Sets UX

## Sets Armor MVP (001-armor) — current gate

**continue with workflow**

- Desktop: `docs/ux-redesign/sets/mockups/001-armor-desktop.html`
- Mobile: `docs/ux-redesign/sets/mockups/001-armor-mobile.html`
- Approved: 2026-08-10 (human mockup gate — **continue with workflow**)
- Grounding: `docs/ux-redesign/sets/000-sets-grill.md` (G-SET-*) · `docs/ux-redesign/sets/000-sets-update-plan.md`
- Track: Sets Armor redesign · product Domain/Area Set · vault Destiny Armor base board

### Locked product / visual notes (mock review)

1. **Bonus goals (G-SET-013)** — Legal only: **none · 1×2pc · 2×2pc (different families) · 1×4pc** (4pc includes that family’s 2pc). Not 4pc+extra 2pc, not three 2pcs.
2. **Chrome** — Library `/sets` + large **modal** lifecycle (G-SET-001). Create: Type → Class → optional goals → name/tags.
3. **Board / detail (G-SET-030)** — EoF stats **Health · Melee · Grenade · Super · Class · Weapons**. **Totals row as columns directly above piece rows**. Base roll only.
4. **Tags (G-SET-033)** — Free multi-select; **editable on Set detail + board** (not create-only). Hard-block Synergy Type vocabulary.
5. **Fill primary: Optimizer (DIM-like)**  
   - Constraints: exotic + dual-thumb min/max kit totals (ends = any)  
   - When re-optimizing a filled board: default exotic = **current exotic** (or No exotic if none)  
   - Results: **one kit per row**; columns = Σ · EoF stats · Helm–Class pieces · goals (no separate Exotic column)  
   - Vs current: **green/red ±delta** on stat columns  
   - Apply **one** selected kit with confirm; replace-all confirm if pins exist  
6. **Fill secondary** — Owned-only compare pick (base six + total + power + bonus fit + exotic).
7. **Mods** — Deep link Mod Set only; no inline edit; hide energy/mods when unknown.
8. **Synergy Type UI** — Out of Armor MVP chrome.
9. **Pins** — Owned instances only.
10. **Windows** Capture exit gate; mobile structure-first.

### Next

- Synthesis: lock brief under `docs/ux-redesign/sets/` (e.g. `001-armor-brief.md`)
- Architect notes + vault UX Sets note
- Then `area-implement` with `brief_path` when ready

---

## RES-SET-CREATE-01 Create wizard dual-truth — residual implement

**continue with workflow**

- Residual brief: `docs/ux-redesign/sets/002-create-wizard-brief.md`
- Mockups: same `001-armor-desktop.html` / `001-armor-mobile.html` (create wizard steps Type→Class→Bonus→Name)
- Approved: 2026-08-10 (human residual plan — stepped create flow + chrome vs single-scroll wizard)
- Scope: step machine, Back/Continue, hide quick create, post-create board
- Out of scope: owned fill, Optimize primary shell
