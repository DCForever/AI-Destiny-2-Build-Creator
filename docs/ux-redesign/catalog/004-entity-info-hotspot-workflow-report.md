# area-ux-component report

**Area:** catalog  
**Component:** EntityInfoHotspot  
**Date:** 2026-08-08  
**Track:** UX-CATALOG-ENTITY-DESC / GAP-UI-DESC-01 Track B  

## Phases

| Phase | Result |
| --- | --- |
| Context | Ship: Material Tooltip name·tier only on perk cells; no description popover. System: DART-071 `EntityPresentation` landed. |
| UX delta | Hover/focus = info; click/tap = primary select; mobile long-press / Alt+tap = info. Never invent text. |
| Mockup | `004-entity-info-hotspot-desktop.html` + `-mobile.html` (human-revised) |
| Human gate | **Approved** — user `continue with workflow` 2026-08-08; residual sticky multi-perk sheet out of scope |
| Brief | `docs/ux-redesign/catalog/004-entity-info-hotspot-brief.md` **locked** |

## Mockups

```json
{
  "desktop_path": "docs/ux-redesign/catalog/mockups/004-entity-info-hotspot-desktop.html",
  "mobile_path": "docs/ux-redesign/catalog/mockups/004-entity-info-hotspot-mobile.html",
  "flows_demonstrated": [
    "hover-info-desktop",
    "click-primary-select",
    "long-press-alt-tap-mobile-info",
    "honest-empty",
    "unknown-no-invent",
    "enhanced-and-compare",
    "single-open",
    "roll-target-primary-nonblocking",
    "missing-icon"
  ],
  "notes": "Pin model removed; primary never opens info. Sticky multi-perk inspect deferred."
}
```

## Approval

- `docs/ux-redesign/catalog/MOCKUP-APPROVED.md` — EntityInfoHotspot (004) contains **continue with workflow**

## Brief

See `004-entity-info-hotspot-brief.md`.

## Next

Do **not** freehand implement. Run:

```text
/workflow area-implement
args: {
  "area": "catalog",
  "subarea": "entity-info-hotspot",
  "brief_path": "docs/ux-redesign/catalog/004-entity-info-hotspot-brief.md",
  "hosts": ["windows", "widgetbook"]
}
```

Or ask the agent to run `area-implement` with that brief path.
