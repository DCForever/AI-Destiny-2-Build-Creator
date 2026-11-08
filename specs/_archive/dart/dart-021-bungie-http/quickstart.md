# Quickstart: DART-021 Bungie HTTP

## Resolve & test

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart pub get
dart test packages/bungie
```

## Use client (host)

```dart
import 'package:destiny2_bungie/destiny2_bungie.dart';

final client = BungieHttpClient(
  apiKey: hostInjectedPublicApiKey, // never CLIENT_SECRET
  onRateLimit: (signal) {
    // Observe throttle; orchestrator may delay or surface WAIT
  },
);

// Authenticated GET — unwraps Response when ErrorCode == 1
final memberships = await client.getJson(
  '/User/GetMembershipsForCurrentUser/',
  accessToken: token,
);

// POST with JSON body
await client.postJson(
  '/Destiny2/Actions/Items/EquipItem/',
  body: {
    'itemId': instanceId,
    'characterId': characterId,
    'membershipType': membershipType,
  },
  accessToken: token,
);
```

## Mock transport (tests)

```dart
BungieHttpTransport mock = (request) async {
  return BungieHttpResponse(
    statusCode: 200,
    body: '{"ErrorCode":1,"Message":"Ok","ThrottleSeconds":0,"Response":{}}',
  );
};

final client = BungieHttpClient(apiKey: 'test-key', transport: mock);
```

## Constraints

- Public API key only; no `CLIENT_SECRET` in this package.
- Soft guidance never auto-applies (N/A for HTTP client).
- Not a pure-domain package — do not import from `destiny2_domain` graph-guard list as a pure dep.
