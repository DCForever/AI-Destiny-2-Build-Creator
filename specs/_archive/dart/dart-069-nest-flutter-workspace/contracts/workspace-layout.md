# Contract: Workspace layout after DART-069

## Paths (relative to monorepo root)

| Path | Required |
| --- | --- |
| `flutter/pubspec.yaml` | yes — workspace root |
| `flutter/packages/domain/pubspec.yaml` | yes |
| `flutter/apps/windows_host/pubspec.yaml` | yes |
| `flutter/apps/mobile_host/pubspec.yaml` | yes |
| `flutter/apps/web_host/pubspec.yaml` | yes |
| `flutter/tool/p0_parity_gate.dart` | yes |
| `packages/` at monorepo root | **must not exist** as live tree |
| `apps/` at monorepo root | **must not exist** as live tree |
| `package.json` at monorepo root | yes (Next.js) |

## Commands

```text
# from monorepo root
cd flutter
dart pub get
dart run tool/p0_parity_gate.dart

# optional host
cd apps/windows_host
flutter pub get   # if needed beyond workspace get
```

## Root detection

Given `Directory.current` = monorepo root **or** `flutter/`, `findWorkspaceRoot()` returns the absolute path of `flutter/` (the directory whose pubspec is the workspace).
