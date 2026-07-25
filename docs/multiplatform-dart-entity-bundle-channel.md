# Web entity-bundle production channel (DART-059)

**Status:** decided  
**Updated:** 2026-07-25  
**Slice:** DART-059 `entity-bundle-prod-channel`  
**Gaps:** GAP-WEB-02 (closed)  
**Cutover:** RB-05 cleared / **RC-WEB-DATA** PASS  
**Architecture:** [multiplatform-dart-port-decisions.md](./multiplatform-dart-port-decisions.md) — **D-WEB-DB** prebuilt entities on web  

This note freezes the **production distribution channel** for Destiny entity definitions on the Jaspr web host. It does not change product DBR/DAC rules.

## Chosen channel: **hybrid**

| Role | Mechanism | Offline after install? |
| ---- | --------- | ---------------------- |
| **Primary** | **Ship-in-app** same-origin static JSON packaged with the Jaspr deploy | **Yes** — assets ship with the app install/deploy |
| **Optional** | **CDN** absolute URL for hot version bumps without full SPA redeploy | Only after successful prior fetch/cache; not the offline guarantee |
| **Fallback** | Legacy DART-044 demo path `/entities/prebuilt/bundle.json` | Yes (demo sample only) |

**Rejected for production-only:**

- **CDN-only** — fails “Catalog offline after install” without a full offline cache layer.
- **Ship-in-app-only** — workable offline but no documented hot-update path.
- **Browser raw manifest rebuild** — desktop (Windows) first; not the web product path.

## Versioning

Two layers:

1. **Channel pointer** — `/entities/channel.json`

```json
{
  "schemaVersion": 1,
  "channelId": "prod",
  "bundleVersion": "entity-bundle-prod-1",
  "distribution": "hybrid",
  "shipInAppPath": "/entities/prod/bundle.json",
  "cdnUrl": null,
  "notes": "…"
}
```

2. **Bundle body** — `/entities/prod/bundle.json` (or CDN object)  
   - Existing `EntityBundleDocument` shape (`manifestVersion`, `builtAt`, `counts`, `stores`).  
   - Production versions use `entity-bundle-prod-*` (not `prebuilt-mvp-*`).  
   - Operator should keep `manifestVersion` aligned with pointer `bundleVersion`.

### Load order (hybrid)

1. Fetch channel pointer (if missing → built-in `EntityBundleChannel.defaultProd`).
2. If `cdnUrl` set → try CDN.
3. Try `shipInAppPath` (default `/entities/prod/bundle.json`).
4. Try legacy `/entities/prebuilt/bundle.json`.

First successful parse wins. Loader status reports `loadSource` (`cdn` | `ship-in-app` | `legacy-prebuilt`).

Pure types: `packages/manifest/lib/src/entity_bundle_channel.dart`  
Web loader: `apps/web_host/lib/catalog/entity_bundle_loader.dart`

## Offline Catalog + compose (no Next manifest API)

| Surface | Entity source | Persistence |
| ------- | ------------- | ----------- |
| Catalog facets / names | Channel prebuilt bundle (in-memory after fetch) | Static install assets |
| Builds / sets / synergies | Domain + Drift | OPFS / IndexedDB (DART-043 single-writer) |
| Inventory owned join | Bundle defs + Drift inventory | OPFS + entities |

**Forbidden on web entity path:** Next.js `/api/manifest*`, `/api/entities`, browser isolate raw rebuild, `CLIENT_SECRET`.

Compose works offline once the writer tab has OPFS open and entity channel has loaded (or Catalog was loaded earlier in-session). No Next runtime dependency (D-IO).

## Operator: publish a new prod bundle

1. On Windows desktop, refresh/extract MVP stores (DART-018) into `EntityBundleDocument` JSON.
2. Set `manifestVersion` to a new `entity-bundle-prod-*` id.
3. Deploy body to `web/entities/prod/bundle.json` **and/or** CDN object.
4. Update `channel.json` `bundleVersion` (and `cdnUrl` if using CDN).
5. Redeploy Jaspr static host (required for ship-in-app; CDN-only bump may skip SPA when hybrid CDN is configured).

Repo ships a **small sample** prod bundle for CI/demo. Size parity with full Destiny catalog is an ops packaging concern, not a channel-schema change.

## Evidence (RC-WEB-DATA)

| Check | Evidence |
| ----- | -------- |
| OPFS single-writer UX | [multiplatform-dart-web-opfs-limits.md](./multiplatform-dart-web-opfs-limits.md) |
| Prebuilt load offline | DART-044 + DART-059 loader tests |
| Prod distribution chosen | This doc — **hybrid** |
| Non-fixture prod path | `/entities/prod/bundle.json` + `entity-bundle-prod-*` |
| No Next manifest API | `assertNoNextManifestEntityUrls` + candidate paths under `/entities/` or CDN |

## Related

- Spec: `specs/dart-059-entity-bundle-prod-channel/`
- Cutover checklist: [multiplatform-dart-cutover-parity-checklist.md](./multiplatform-dart-cutover-parity-checklist.md)
- Feature gaps: [multiplatform-dart-feature-gaps.md](./multiplatform-dart-feature-gaps.md) — GAP-WEB-02
