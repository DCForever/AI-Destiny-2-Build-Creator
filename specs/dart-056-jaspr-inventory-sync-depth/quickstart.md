# Quickstart: DART-056 Jaspr Inventory Sync Depth

## Dev validation (browser)

1. Run Jaspr web host with `BUNGIE_API_KEY` + Public `BUNGIE_CLIENT_ID` and redirect for origin.
2. Sign in (Public+PKCE) on Settings.
3. Ensure this tab is the **writer** (OPFS single-tab policy).
4. Load Catalog (entity prebuilt bundle) so slot lookup has data.
5. Settings → **Sync now** → expect item count > 0; diagnostics show raw/parsed/dropped and `resolvedFromTransfer` when vault gear exists.
6. Catalog → **Owned** → select a definition → copy **instance id** into Build compose pin field → equip-ready / DIM jsonOnly.

## Automated

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart\apps\web_host
dart pub get
dart test
```

Focus suites: `inventory_sync_controller_test.dart`, `inventory_sync_card_test.dart`, `catalog_owned_page_test.dart`, `settings_page_test.dart`.

## Exit evidence checklist

- [ ] Vault fixture: stored equipment bucket + `resolvedFromTransfer > 0`
- [ ] Owned filter + instanceId visible
- [ ] GAP-WEB-01 closed; RB-02 cleared; RC-SYNC not FAIL for web depth alone
