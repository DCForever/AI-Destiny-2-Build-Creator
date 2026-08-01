# Flutter platform slot (product map)

Domain rules (**DBR / DAC / BR**) stay **platform-agnostic**. Flutter Windows is the first Dart shell ([`docs/multiplatform-dart-port-decisions.md`](../multiplatform-dart-port-decisions.md) **D-SHELL-1**).

## What Phase 4 adds

| Item | Purpose |
|------|---------|
| `platforms.flutter-windows` on surfaces | Route + captureId stubs (same logical ids as Next) |
| `status: stub \| deferred` | Track intent without claiming UI exists |
| Capture plan | `docs/atlas/screenshots/flutter-windows/capture-plan.json` |
| Parity report | `docs/product-map/parity-flutter-windows.md` |

## Commands

```powershell
# Seed / refresh flutter-windows blocks from nextjs surfaces
npm run product-map:seed-flutter

# Parity report (stubs vs captures vs rules)
npm run product-map:parity

# Capture plan only (no real screenshots yet)
npm run product-map:capture-stub -- --platform=flutter-windows --write-plan

npm run product-map:sync
```

## Surface binding shape

```yaml
- id: build.edit.general
  rules: [DAC-P1-002, DBR-ID-001]
  platforms:
    nextjs:
      path: /build
      captureId: build-edit-general
    flutter-windows:
      status: stub
      route: /build
      captureId: build-edit-general   # same id when possible
```

## Deferred on first Flutter Windows shell

Per multiplatform non-goals / later:

- Analyze / multi-pass LLM as primary spine  
- Full `/debug/*` operator surfaces  
- Prefer not cloning every Next chrome field as a separate Flutter screen  

Those surfaces get `status: deferred` rather than fake “done” stubs.

## When a Flutter screen lands

1. Implement route matching `platforms.flutter-windows.route`
2. Set `status: capturing` or `done`
3. Drop PNG under `docs/atlas/screenshots/flutter-windows/{captureId}__signed-in.png`
4. `npm run product-map:parity` + `product-map:sync`
5. **Do not** add Flutter-only DBR/DAC — attach existing rule IDs

## Viewer

Unified companion (`npm run product-map:view`): platform filter shows Next vs Flutter stub state (Export / Screens).
