# Quickstart: DART-045 Jaspr OAuth PKCE

## Prerequisites

- Dart SDK ^3.10
- Bungie **Public** application with redirect URI registered, e.g.:
  - `https://127.0.0.1:8080/auth/callback` (HTTPS loopback / local TLS)
  - `https://your.production.origin/auth/callback`
- Public client id only — **never** put `CLIENT_SECRET` in the web client

## Run with OAuth config

```powershell
cd apps\web_host
dart pub get
jaspr serve --dart-define=BUNGIE_CLIENT_ID=your_public_client_id
# optional override:
# --dart-define=BUNGIE_REDIRECT_URI=https://127.0.0.1:8080/auth/callback
```

1. Open the app origin (prefer HTTPS for registered prod/loopback URIs).
2. Settings → **Sign in** → Bungie consent → returns to `/auth/callback` → Settings signed-in.
3. **Sign out** clears origin-scoped tokens.

## Test (no live Bungie)

```powershell
cd apps\web_host
dart test
```

## Token storage strategy (summary)

| What | Where |
| ---- | ----- |
| Access + refresh tokens | `localStorage` (origin-scoped) |
| Pending PKCE verifier/state | `sessionStorage` |
| SQLite / Drift | **Never** for OAuth secrets |
| Client secret | **Never** |

See [research.md](./research.md) R3 for limits (XSS, HTTPS).
