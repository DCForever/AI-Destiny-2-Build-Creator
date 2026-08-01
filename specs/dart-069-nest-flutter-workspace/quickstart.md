# Quickstart validation: DART-069

## Prerequisites

- Dart SDK matching workspace `environment.sdk`
- Flutter SDK for host smoke (optional if only pure gate)
- Node for monorepo `npm` smoke

## Validate layout

```powershell
Test-Path flutter/pubspec.yaml
-not (Test-Path packages/domain)   # monorepo root
Test-Path flutter/packages/domain
Test-Path package.json
```

## Validate Dart workspace

```powershell
Set-Location flutter
dart pub get
dart run tool/p0_parity_gate.dart
# expect exit 0
```

## Validate root detection (from monorepo root)

```powershell
# from monorepo root, after tool tests updated:
Set-Location <monorepo>
dart test flutter/tool/test   # or run from flutter/ with tests covering parent start dir
```

## Validate Next.js still healthy

```powershell
Set-Location <monorepo>
npm run typecheck
# or: npm test
```

## IDE

Open launch config `windows_host` or `mobile_host` — `cwd` must start with `flutter/`.
