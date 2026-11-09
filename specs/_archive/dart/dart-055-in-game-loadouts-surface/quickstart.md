# Quickstart: DART-055 In-Game Loadouts

## Tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/bungie/test/character_loadouts_test.dart
dart test packages/bungie
flutter test apps/windows_host/test/shell_nav_loadouts_test.dart apps/windows_host/test/loadouts_page_test.dart
dart test apps/web_host/test/shell_nav_compose_test.dart apps/web_host/test/loadouts_page_test.dart
dart test tool/test/cutover_parity_checklist_validate_test.dart
```

## Manual (Windows)

1. Sign in (Settings → Bungie Public+PKCE).
2. Ensure manifest refreshed once (Loadout* tables on disk).
3. Open **Loadouts** on NavigationRail.
4. Confirm character slots list; toggle class / show empty; Refresh.

## Manual (Jaspr)

1. Open web host; navigate **Loadouts** or `/loadouts`.
2. Sign in if needed; confirm list or sign-in gate.
