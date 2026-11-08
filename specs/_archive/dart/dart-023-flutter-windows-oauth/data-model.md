# Data Model: DART-023 Flutter Windows OAuth

## BungieTokens (from DART-022 — persisted shape)

Persisted **only** via `TokenStore` (secure storage). JSON keys:

| JSON key | Source field | Notes |
| -------- | ------------ | ----- |
| `access_token` | `accessToken` | Secret |
| `refresh_token` | `refreshToken` | Secret |
| `expires_at` | `expiresAt` | ISO-8601 UTC |
| `refresh_expires_at` | `refreshExpiresAt` | ISO-8601 UTC |
| `membership_id` | `bungieMembershipId` | Public-ish id; still not shown with raw tokens |

**Forbidden storage:** SQLite columns, unencrypted prefs, log files, error messages.

## TokenStore

| Operation | Behavior |
| --------- | -------- |
| `read()` | `BungieTokens?` — null if missing/corrupt |
| `write(tokens)` | Overwrite single secure entry |
| `clear()` | Delete entry |

### Implementations

- **SecureTokenStore** — `flutter_secure_storage` key `destiny2.bungie.oauth.tokens`
- **MemoryTokenStore** — tests

## OAuthPendingAuth (in-memory only)

Held by `WindowsOAuthSession` during active sign-in (DART-022 DTO):

| Field | Notes |
| ----- | ----- |
| `state` | CSRF — must match callback |
| `codeVerifier` | PKCE — token exchange only |
| `redirectUri` | Must match authorize + exchange |
| `createdAt` | Optional |

Never written to SQLite.

## LoopbackCallbackResult

| Field | Notes |
| ----- | ----- |
| `code` | Authorization code (nullable if error) |
| `state` | CSRF return |
| `error` | OAuth error code from query |
| `errorDescription` | Optional |

## WindowsOAuthSessionState

| Status | UI meaning |
| ------ | ---------- |
| `signedOut` | Show Sign in (if configured) |
| `signingIn` | Busy; disable double-start |
| `signedIn` | Show membership + Sign out |
| `error` | Show message; remain signed-out unless tokens already present |

## Host config (not secrets)

| Define / field | Example |
| -------------- | ------- |
| `BUNGIE_CLIENT_ID` | Public app client id |
| `BUNGIE_REDIRECT_URI` | `http://127.0.0.1:8765/callback` |
| `BUNGIE_API_KEY` | Existing public API key (DART-019) |

No `BUNGIE_CLIENT_SECRET` / `CLIENT_SECRET`.
