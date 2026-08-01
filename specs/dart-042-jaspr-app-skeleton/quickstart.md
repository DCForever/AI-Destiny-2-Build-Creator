# Quickstart: DART-042 Jaspr Web Host

## Prerequisites

- Dart SDK ^3.5+ (Jaspr 0.23 prefers recent stable; repo uses ^3.5 workspace constraint with host override as needed)
- Jaspr CLI: `dart pub global activate jaspr_cli`
- Ensure `%LOCALAPPDATA%\Pub\Cache\bin` (Windows) is on `PATH` for `jaspr`

## Setup

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart pub get
cd apps\web_host
dart pub get
```

## Run (dev)

```powershell
cd apps\web_host
jaspr serve
```

Open the printed localhost URL (typically `http://localhost:8080`). You should see the **Settings** shell with **Hello** copy. No Next.js process is required.

## Test

```powershell
cd apps\web_host
dart test
```

## Build (static client output)

```powershell
cd apps\web_host
jaspr build
```

Artifacts under `build/jaspr/` (client mode).

## Non-goals reminder

- No OAuth / CLIENT_SECRET
- No OPFS SQLite until DART-043
- Do not run `npm run dev` for this host
