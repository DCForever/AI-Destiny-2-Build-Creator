# Research: DART-045 Jaspr Browser Public+PKCE

**Date**: 2026-07-25  
**Slice**: DART-045 `jaspr-oauth-pkce`

## Decisions

### R1 — Reuse DART-022 pure OAuth client

**Decision**: Use `packages/bungie` `BungieOAuthClient`, `generatePkcePair`, `generateOAuthState` / `validateOAuthState`, `OAuthPendingAuth`, `BungieTokens` unchanged.

**Rationale**: Port decisions freeze Public+PKCE in pure package; Windows (DART-023) already proves the contract. Web is a host adapter, not a second OAuth protocol.

**Alternatives rejected**: Re-implement authorize/token in web_host; confidential token exchange via Next BFF (violates D-IO / D-WEB-AUTH).

### R2 — Same-tab redirect + `/auth/callback`

**Decision**: Sign-in navigates the current browsing context to Bungie authorize URL. Registered `redirect_uri` is `{origin}/auth/callback`. Jaspr router serves `AuthCallbackPage` which completes exchange then navigates to `/settings`.

**Rationale**: Browser Public clients cannot bind loopback servers like Windows. Same-origin callback is the standard SPA pattern and matches D-BUNGIE platform `web`.

**Alternatives rejected**: Popup-only flow (harder to test, popup blockers); custom protocol handlers (not for web); confidential cookie session via helper process.

### R3 — Token storage strategy (browser)

**Decision**:

| Layer | Production | Tests |
| ----- | ---------- | ----- |
| Tokens | `localStorage` key `destiny2.bungie.oauth.tokens` (JSON codec, same shape as Windows `token_codec`) | `MemoryTokenStore` |
| Pending PKCE | `sessionStorage` key `destiny2.bungie.oauth.pending` | in-memory pending store |
| SQLite / Drift | **Never** store access/refresh tokens | N/A |

**Rationale**: Browser has no OS Credential Locker. Port decisions forbid SQLite plaintext tokens and confidential secrets. Origin isolation + HTTPS (prod / HTTPS loopback) is the practical web equivalent. `sessionStorage` for pending PKCE limits verifier lifetime to the redirect tab. `localStorage` for tokens enables restore after reload (parity with Windows secure restore).

**Documented limits**: XSS can read web storage — mitigate with CSP later; not this slice. Never log raw tokens. Prefer HTTPS origins in Bungie app registration.

**Alternatives rejected**: Put refresh token in OPFS SQLite (violates D-BUNGIE); cookies with `CLIENT_SECRET` BFF; IndexedDB encryption without key management story (overkill for this slice).

### R4 — Config injection

**Decision**: `BUNGIE_CLIENT_ID` and optional `BUNGIE_REDIRECT_URI` via `--dart-define` (or constructor injection). Empty client id disables Sign in with Settings hint. Default redirect from `window.location.origin + '/auth/callback'`.

**Rationale**: Mirrors Windows host pattern; public client id is not a secret.

### R5 — Navigation / transport injectability

**Decision**: Abstract `WebAuthNavigator` (assign `window.location` / read query) and reuse bungie injectable `BungieHttpTransport` so CI needs no live Bungie or real browser navigation.

## References

- [docs/multiplatform-dart-port-decisions.md](../../docs/multiplatform-dart-port-decisions.md) — D-WEB-AUTH, D-BUNGIE
- [specs/dart-022-oauth-pkce/](../dart-022-oauth-pkce/) — pure PKCE
- [specs/dart-023-flutter-windows-oauth/](../dart-023-flutter-windows-oauth/) — Windows host pattern
