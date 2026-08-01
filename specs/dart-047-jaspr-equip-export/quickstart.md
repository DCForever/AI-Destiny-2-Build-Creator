# Quickstart: DART-047 Jaspr Equip Export

## Prerequisites

- Dart SDK ^3.10
- Writer-tab DB (compose spine from DART-046)
- Optional: `BUNGIE_CLIENT_ID`, `BUNGIE_API_KEY` (public only) for live equip

## Run tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart\apps\web_host
dart pub get
dart test
```

Focused:

```powershell
dart test test/equip_format_test.dart test/dim_export_format_test.dart test/equip_controller_test.dart test/dim_export_controller_test.dart
```

## Manual smoke (browser)

1. `jaspr serve` (or project-documented serve) for `apps/web_host`
2. Writer tab → Sets → create weapon set with item + instance id if desired
3. Builds → create → non-default variant → attach → pin instance
4. Seed inventory only via tests or future sync; readiness shows equip-ready when inventory matches pins
5. **Copy DIM JSON** when equip-ready
6. Sign in (Public+PKCE) → pick character → **Apply to character** (optional equip)

## Gates

- Soft never auto-applies on equip/export
- DIM blocked when not equip-ready
- No `CLIENT_SECRET` in sources
