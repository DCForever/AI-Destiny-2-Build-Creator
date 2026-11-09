# Data Model: DART-022 Public+PKCE OAuth Core

## BungieTokens

| Field | Type | Notes |
| ----- | ---- | ----- |
| `accessToken` | `String` | Bearer for Platform API |
| `refreshToken` | `String` | Refresh grant |
| `expiresAt` | `DateTime` | Access expiry (UTC), **after** 60s margin applied at map time |
| `refreshExpiresAt` | `DateTime` | Refresh expiry (UTC), no margin |
| `bungieMembershipId` | `String` | Bungie.net membership id from token response |

**Not stored by this package.** Hosts (DART-023+) persist securely.

## PkcePair

| Field | Type | Notes |
| ----- | ---- | ----- |
| `codeVerifier` | `String` | High-entropy unreserved string |
| `codeChallenge` | `String` | BASE64URL(SHA256(verifier)), no padding |
| `method` | const `S256` | Only supported method |

## OAuthPendingAuth

In-memory / host-held handoff between authorize and callback:

| Field | Type | Notes |
| ----- | ---- | ----- |
| `state` | `String` | CSRF |
| `codeVerifier` | `String` | PKCE verifier |
| `redirectUri` | `String` | Must match authorize + token exchange |
| `createdAt` | `DateTime` | Optional bookkeeping |

## BungieOAuthClientConfig

| Field | Type | Notes |
| ----- | ---- | ----- |
| `clientId` | `String` | Public Bungie application client id (not secret) |
| `redirectUri` | `String` | Active platform redirect |
| `authorizeBaseUrl` | `Uri` | Default Bungie authorize |
| `tokenEndpoint` | `Uri` | Default Bungie token |
| `transport` | `BungieHttpTransport` | Injectable |

**Forbidden fields:** `clientSecret`, `client_secret`, any confidential secret.

## PlatformRedirectUriConfig

| Field | Type | Notes |
| ----- | ---- | ----- |
| entries | `Map<OAuthRedirectPlatform, String>` | Host-registered URIs |

### OAuthRedirectPlatform

- `windows` — loopback (e.g. `http://127.0.0.1:<port>/callback`)
- `android` — custom scheme / app link
- `ios` — custom scheme / universal link
- `web` — HTTPS origin callback

## Token request bodies (logical)

### authorization_code

- `grant_type=authorization_code`
- `code`
- `client_id`
- `code_verifier`
- `redirect_uri`

### refresh_token

- `grant_type=refresh_token`
- `refresh_token`
- `client_id`

No `client_secret` key in either body.
