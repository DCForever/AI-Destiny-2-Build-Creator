# area-ux-redesign report — Catalog Armor (C8)

**Status:** complete (2026-08-08)  
**Workflow:** `area-ux-redesign` · area `catalog` · subarea `armor`  
**Session report source:** workflow scratch `area-ux-redesign-report.md`

## Artifacts

| Artifact | Path |
| --- | --- |
| Mockups | `docs/ux-redesign/catalog/mockups/001-armor-desktop.html`, `001-armor-mobile.html` |
| Approval | `docs/ux-redesign/catalog/MOCKUP-APPROVED.md` |
| Brief | `docs/ux-redesign/catalog/001-armor-brief.md` |
| Vault UX note | `requirements/.../UX/UX Catalog — Armor.md` |

## Flows demonstrated (mockups)

- signed-out Armor All dual-pane idle grid  
- signed-out Owned sign-in prompt  
- signed-in loading skeletons + facet bar  
- identity icon grid class/slot/exotic facets, no row stats  
- facet include + exotic exclude zero-match Clear  
- owned empty Sync/Settings CTA  
- unowned detail (fix residual: no invent Base)  
- owned multi-copy strip + Base\|Live board  
- owned mods+energy read-only  
- set-bonus 2pc/4pc vs explicit none + exotic perk  
- detail footer disabled Set/Synergy stubs  
- soft load/sync error banner  

## Verify summary (adversarial — all three raised issues)

| Lane | Outcome | Top issues |
| --- | --- | --- |
| Product | fail (residuals) | Invented unowned Base; instance Base not rebound; empty mods note; vault note was missing at verify |
| UX | fail (residuals) | Base vs strip mismatch; dense chrome; mobile structure-only gaps |
| Arch | fail (pre-implement) | God CatalogPage; no dual-board API; no energy on projection; no armor sort pure helpers; no CatalogArmor* widgets yet |

These are **expected pre-implement** architecture gaps plus **must-fix honesty residuals** captured in the brief.

## Next

```text
/workflow area-implement
# { "area": "catalog", "subarea": "armor",
#   "brief_path": "docs/ux-redesign/catalog/001-armor-brief.md" }
```
