# area-ux-component report

**Area:** catalog  
**Component:** CatalogFilterCollections  
**Date:** 2026-08-08  
**Gate:** mockups approved — **continue with workflow**

## Mockups

| | Path |
| --- | --- |
| Desktop | `docs/ux-redesign/catalog/mockups/004-catalog-filter-collections-desktop.html` |
| Mobile | `docs/ux-redesign/catalog/mockups/004-catalog-filter-collections-mobile.html` |
| Approval | `docs/ux-redesign/catalog/MOCKUP-APPROVED.md` (004 section) |

### Flows demonstrated

- Open Saved → empty / list  
- Save · replace-by-name  
- Soft apply → criteria only (grid fixture constant)  
- Applied · dirty  
- Rename · delete confirm  
- At-cap (20) · persist-error · signed-out · narrow band  

## Brief

- Locked: `docs/ux-redesign/catalog/004-catalog-filter-collections-brief.md`

## System dependency (already landed)

- Commit `74ce3e4` — domain model, Drift `catalog_filter_collections`, app use cases  
- Soft apply; per mode; replace-by-name; cap 20  

## Next

```text
/workflow area-implement
# brief_path: docs/ux-redesign/catalog/004-catalog-filter-collections-brief.md
# hosts: windows, widgetbook
# build: F:\d2w\filters
```

Implement in `packages/ui_flutter` (filter-band chrome) + thin `windows_host` wire; Widgetbook + tests; Capture dual-truth after structure green.
