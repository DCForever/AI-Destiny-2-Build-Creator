# Quickstart: DART-023 Flutter Windows OAuth

## Prerequisites

- Flutter SDK with Windows desktop enabled
- Dart workspace at repo root (`dart pub get`)
- Public Bungie application (Public + PKCE) with redirect `http://127.0.0.1:8765/callback`

## Configure (dev)

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart\apps\windows_host
flutter run -d windows `
  --dart-define=BUNGIE_CLIENT_ID=your_public_client_id `
  --dart-define=BUNGIE_API_KEY=your_public_api_key `
  --dart-define=BUNGIE_REDIRECT_URI=http://127.0.0.1:8765/callback
```

Never pass `CLIENT_SECRET` / `BUNGIE_CLIENT_SECRET`.

## Manual smoke (optional)

1. Open **Settings** → Account card → **Sign in**
2. Browser opens Bungie authorize; approve
3. Browser redirects to loopback; app captures code and closes the wait
4. Settings shows membership id; **Sign out** clears secure tokens

## Automated tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart\apps\windows_host
flutter test
```

Tests use `MemoryTokenStore`, fake browser, injected loopback results, and mock OAuth HTTP — no live Bungie.

## Token storage location

- Production: `flutter_secure_storage` key `destiny2.bungie.oauth.tokens`
- **Not** in `app.db` / Drift tables
