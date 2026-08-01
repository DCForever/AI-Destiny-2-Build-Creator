# Data Model: DART-045 Web OAuth

## BungieTokens (existing — destiny2_bungie)

| Field | Type | Notes |
| ----- | ---- | ----- |
| accessToken | String | Never log / display in UI |
| refreshToken | String | Never log / display in UI |
| expiresAt | DateTime UTC | Access expiry with 60s margin applied at map time |
| refreshExpiresAt | DateTime UTC | Session expiry |
| bungieMembershipId | String | Safe to show in Settings |

**Persistence JSON** (web storage; same keys as Windows host):

```json
{
  "access_token": "...",
  "refresh_token": "...",
  "expires_at": "ISO-8601",
  "refresh_expires_at": "ISO-8601",
  "membership_id": "..."
}
```

Storage key: `destiny2.bungie.oauth.tokens`  
**Must not** appear in Drift tables.

## OAuthPendingAuth (existing)

| Field | Storage |
| ----- | ------- |
| state | sessionStorage pending payload |
| codeVerifier | sessionStorage pending payload |
| redirectUri | sessionStorage pending payload |
| createdAt | optional |

Storage key: `destiny2.bungie.oauth.pending`

## WebOAuthSession status

`signedOut` | `signingIn` | `signedIn` | `error`

## Config

| Name | Secret? | Source |
| ---- | ------- | ------ |
| BUNGIE_CLIENT_ID | No (public) | dart-define / inject |
| BUNGIE_REDIRECT_URI | No | dart-define / origin default |
| CLIENT_SECRET | **Forbidden** | — |
