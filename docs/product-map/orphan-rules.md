# Orphan rules (not on product map)

Generated: 2026-07-27

Rules listed here exist in domain/feature markdown but are **not** referenced by any surface or flow phase `rules:` list.
That can be intentional (backend-only, not yet mapped, superseded).

| Layer | Total | Attached | Orphan |
|-------|-------|----------|--------|
| DAC | 34 | 34 | 0 |
| DBR | 105 | 90 | 15 |
| BR | 112 | 94 | 18 |

## DAC (0)

_None._

## DBR (15)

| ID | Section |
|----|---------|
| `DBR-CMPL-003` | 9. Completeness: default vs other variants |
| `DBR-CMPL-004` | 9. Completeness: default vs other variants |
| `DBR-FASH-006` | 14. Fashion / cosmetics |
| `DBR-ID-010` | 3. Build identity |
| `DBR-LLM-003` | 6. Synergies |
| `DBR-LLM-004` | 6. Synergies |
| `DBR-LLM-005` | 6. Synergies |
| `DBR-MOD-004` | 11. Armor energy / tier / mods |
| `DBR-NAME-003` | 4. Naming |
| `DBR-NAME-005` | 4. Naming |
| `DBR-ROLL-003` | 8. Rolls, instances, wishlist |
| `DBR-ROLL-009` | 8. Rolls, instances, wishlist |
| `DBR-SETB-001` | 12. Armor set bonuses |
| `DBR-SETB-002` | 12. Armor set bonuses |
| `DBR-STAT-007` | 10. Stats (Edge of Fate) |

## BR (18)

| ID | Section |
|----|---------|
| `BR-ATT-005` | 9. Set Attachments |
| `BR-BLD-002` | 7. Builds — Structure |
| `BR-BLD-005` | 7. Builds — Structure |
| `BR-EXO-006` | 16. Exotic Loadout Filtering (Feature 002) |
| `BR-EXO-007` | 16. Exotic Loadout Filtering (Feature 002) |
| `BR-EXO-008` | 16. Exotic Loadout Filtering (Feature 002) |
| `BR-ROLL-003` | 5. Set Items and Weapon Rolls |
| `BR-ROLL-004` | 5. Set Items and Weapon Rolls |
| `BR-ROLL-005` | 5. Set Items and Weapon Rolls |
| `BR-SUG-003` | 14. Suggestions |
| `BR-SUG-004` | 14. Suggestions |
| `BR-SUG-005` | 14. Suggestions |
| `BR-SYN-006` | 13. Synergies |
| `BR-SYN-007` | 13. Synergies |
| `BR-SYN-008` | 13. Synergies |
| `BR-SYN-009` | 13. Synergies |
| `BR-SYN-010` | 13. Synergies |
| `BR-VAR-002` | 12. Build Variants |

## How to fix

1. Attach to a surface/flow: Screens mode in companion or edit `surfaces.yaml` / `flows.yaml`
2. Or mark intentional: leave orphan if backend-only / not user-visible
3. Re-run `npm run product-map:orphan-rules`
