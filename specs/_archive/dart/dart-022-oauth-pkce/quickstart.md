# Quickstart: DART-022 Public+PKCE OAuth Core

## Run tests

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart pub get
dart test packages/bungie
```

## Build authorize URL (host sketch)

```dart
import 'package:destiny2_bungie/destiny2_bungie.dart';

final redirects = PlatformRedirectUriConfig({
  OAuthRedirectPlatform.windows: 'http://127.0.0.1:8765/callback',
});

final redirectUri = redirects.resolve(OAuthRedirectPlatform.windows);
final pkce = generatePkcePair();
final state = generateOAuthState();
final pending = OAuthPendingAuth(
  state: state,
  codeVerifier: pkce.codeVerifier,
  redirectUri: redirectUri,
);

final client = BungieOAuthClient(
  clientId: hostPublicClientId,
  redirectUri: redirectUri,
  transport: myTransport, // or default
);

final url = client.buildAuthorizeUrl(
  state: state,
  codeChallenge: pkce.codeChallenge,
);
// Host opens [url] in system browser (DART-023). Keep [pending] for callback.
```

## Exchange code (after redirect)

```dart
// Host validates: validateOAuthState(expected: pending.state, actual: queryState)
final tokens = await client.exchangeCode(
  code: authCode,
  codeVerifier: pending.codeVerifier,
);
// Store tokens securely (DART-023) — not in this package.
```

## Refresh

```dart
if (needsRefresh(tokens)) {
  tokens = await client.refreshTokens(tokens);
}
```

## Security notes

- Never put `BUNGIE_CLIENT_SECRET` in Flutter/Jaspr.
- Register each platform `redirect_uri` on the Bungie **Public** application.
- Tokens must not be logged by hosts.
