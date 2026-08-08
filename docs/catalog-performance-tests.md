# Catalog performance tests

**Status:** active  
**Updated:** 2026-08-08  
**Ledger:** [multiplatform-dart-feature-gaps.md](./multiplatform-dart-feature-gaps.md) **GAP-PERF-01–06**  
**Cutover:** does **not** re-open PRODUCTION_CUTOVER  

## Goal

Catch **structural regressions** on Catalog browse hot paths (filter, group, project) with:

1. **Always-on package tests** — large synthetic corpora, correctness + soft time budgets  
2. **Optional strict budgets** — `PERF_ASSERT=1` for tighter thresholds on local/CI perf jobs  
3. **No DevTools dependency** — pure Dart / package tests first; frame timings later  

## Mapping to GAPs

| GAP | Test focus (today) | Package / file |
| --- | --- | --- |
| **GAP-PERF-01** | `filterCatalogClient` on N items; query + facets | `packages/manifest/test/catalog_performance_test.dart` |
| **GAP-PERF-02** | `groupCatalogItemsNested` + flatten/collapse on N items; scroll-spy throttle unit | same + `packages/ui_flutter/test/catalog_scroll_spy_throttle_test.dart` |
| **GAP-PERF-03** | (planned) loadBase/project isolate harness | future `offline_catalog_performance_test` / fixture store |
| **GAP-PERF-04** | (planned) inventory hash-only list | future `packages/db` |
| **GAP-PERF-05** | (planned) not unit-timed; smoke optional | host / integration later |
| **GAP-PERF-06** | (planned) widget pump budget optional | `ui_flutter` later |

## Run

From Melos root `flutter/`:

```powershell
# Always-on (CI-friendly soft budgets)
dart test packages/manifest/test/catalog_performance_test.dart

# Host scroll-spy throttle (GAP-PERF-02)
flutter test packages/ui_flutter/test/catalog_scroll_spy_throttle_test.dart

# Strict budgets (local / optional CI job)
$env:PERF_ASSERT = "1"
dart test packages/manifest/test/catalog_performance_test.dart
```

Melos (optional script name):

```powershell
dart test packages/manifest/test/catalog_performance_test.dart
```

## Design rules

| Rule | Why |
| --- | --- |
| Synthetic items only | No 190 MB Destiny JSON in unit tests |
| Soft default budgets | Avoid flaky CI on slow runners |
| `PERF_ASSERT=1` for tight | Opt-in regression gate |
| Prefer pure package | No Flutter driver for core browse cost |
| Print elapsed ms always | Baseline visibility in CI logs |

## Soft vs strict budgets (current)

| Case | N | Soft max (always) | Strict max (`PERF_ASSERT=1`) |
| --- | --- | --- | --- |
| Full filter (all facets off, empty query) | 5 000 | 2 000 ms | 250 ms |
| Query + facet include | 5 000 | 2 000 ms | 300 ms |
| Nested group slot→element | 5 000 | 3 000 ms | 400 ms |
| Nested flatten visible (all expanded) | 5 000 | 1 000 ms | 150 ms |
| Scale check: 4 000 vs 1 000 filter ratio | — | ratio &lt; 12 | ratio &lt; 6 |

Adjust thresholds only with a dated note in this file + changelog on GAP-PERF rows.

## Exit criteria for “performance tests landed”

- [x] Plan doc (this file)  
- [x] Manifest package harness for filter + nested group (GAP-PERF-01/02)  
- [x] Documented in feature-gaps current pointer + GAP-PERF rows  
- [x] Melos script `perf:catalog` (`dart test packages/manifest/test/catalog_performance_test.dart`)  
- [ ] Optional dedicated CI job with `PERF_ASSERT=1`  
- [ ] PERF-03/04 package tests when system APIs exist  

## Out of scope (for now)

- Frame-time / jank assertions (need DevTools / integration)  
- Network latency mocks as perf gate  
- Widget pump micro-benchmarks as CI gate (too noisy)  
