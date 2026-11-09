# Data Model: DART-069 Nest Flutter Workspace

No runtime product entities. Layout entities only:

## MonorepoRoot

- **Path**: repository root
- **Contains**: Next.js app, `specs/`, `docs/`, `flutter/`, Node tooling
- **Must not contain** (after feature): live `packages/`, `apps/`, Dart `tool/`, workspace `pubspec.yaml`

## DartWorkspaceRoot

- **Path**: `flutter/`
- **Identity markers**: `pubspec.yaml` with `name: destiny2_build_creator_workspace` and/or `workspace:` key
- **Contains**: `packages/`, `apps/`, `tool/`, melos config, analysis_options

## PackageTree

- **Path**: `flutter/packages/*`
- **Relations**: path deps between siblings (`../domain`, etc.) unchanged

## AppTree

- **Path**: `flutter/apps/{windows_host,mobile_host,web_host}`
- **Relations**: path deps `../../packages/...` unchanged vs pre-move sibling depth

## ToolingRoot

- **Path**: `flutter/tool/`
- **Pure package list**: relative dirs `packages/domain`, `packages/sandbox_data` (relative to DartWorkspaceRoot)
