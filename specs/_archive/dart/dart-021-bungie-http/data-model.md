# Data Model: DART-021 Bungie HTTP

## Types (logical)

### BungieHttpClientConfig / constructor

| Field | Type | Notes |
| ----- | ---- | ----- |
| apiKey | String | Required non-empty public API key |
| baseUrl | Uri | Default `https://www.bungie.net/Platform` |
| transport | BungieHttpTransport | Injected or default |
| onRateLimit | RateLimitHook? | Optional observer |
| defaultAccessToken | String? | Optional default Bearer |

### BungieHttpRequest

| Field | Type | Notes |
| ----- | ---- | ----- |
| method | String | `GET` / `POST` |
| uri | Uri | Absolute request URI |
| headers | Map<String,String> | Includes X-API-Key; optional Authorization |
| body | String? | JSON for POST |

### BungieHttpResponse

| Field | Type | Notes |
| ----- | ---- | ----- |
| statusCode | int | HTTP status |
| body | String | Raw body |
| headers | Map<String,String> | Lowercased or as-returned for Retry-After |

### BungieEnvelope

| Field | Type | Notes |
| ----- | ---- | ----- |
| errorCode | int | 1 = Success |
| message | String? | Platform message |
| throttleSeconds | int | Default 0 |
| response | Object? | Unwrapped payload (often Map) |
| errorStatus | String? | Optional |

### RateLimitSignal

| Field | Type | Notes |
| ----- | ---- | ----- |
| path | String | Request path/url |
| throttleSeconds | int? | From envelope or Retry-After |
| httpStatus | int? | e.g. 429 |
| errorCode | int? | Platform code when present |
| source | enum/string | `http` / `envelope` |

### Exceptions

- **BungieHttpException**: transport/HTTP layer (`statusCode`, `body` snippet, optional throttle)
- **BungiePlatformException**: extends or sibling — `errorCode`, `message`, `throttleSeconds`
- **BungieParseException**: invalid JSON / non-object envelope

No persistence entities. No secrets stored.
