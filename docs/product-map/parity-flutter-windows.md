# Parity: flutter-windows

Generated: 2026-08-01

| Metric | Value |
|--------|-------|
| Platform status | planned |
| Stubs | 63 |
| Deferred | 7 |
| Missing platform block | 0 |
| Captures on disk | 0 |

## Same rules, different shell

DBR/DAC/BR IDs are shared. Do not create Flutter-only domain rules.

## Surfaces (stub or missing)

| Surface | Status | Flutter route | Capture id | Shot | Rules |
|---------|--------|---------------|------------|------|-------|
| `shell` | stub | / | — | no | 9 |
| `shell.nav.loadouts` | stub | /loadouts | — | no | 0 |
| `shell.nav.build` | stub | /build | — | no | 0 |
| `shell.nav.synergy` | stub | /synergy | — | no | 0 |
| `shell.nav.sets` | stub | /sets | — | no | 0 |
| `shell.nav.catalog` | stub | /catalog | — | no | 0 |
| `shell.nav.settings` | stub | /settings | — | no | 0 |
| `shell.signed-out-gate` | stub | / | — | no | 2 |
| `build.signed-out` | stub | /build | build-signed-out | no | 2 |
| `build.library` | stub | /build | build-library | no | 8 |
| `build.library.selected` | stub | /build | build-library-selected | no | 3 |
| `build.create` | stub | /build | — | no | 9 |
| `build.create.general` | stub | /build | — | no | 3 |
| `build.edit.general` | stub | /build | build-edit-general | no | 5 |
| `build.edit.subclass` | stub | /build | build-edit-subclass | no | 7 |
| `build.edit.armor` | stub | /build | — | no | 7 |
| `build.edit.armor.reuse` | stub | /build | build-edit-armor-reuse | no | 3 |
| `build.edit.armor.improve` | stub | /build | build-edit-armor-improve | no | 2 |
| `build.edit.armor.create` | stub | /build | build-edit-armor-create | no | 4 |
| `build.edit.armor.exotic-limit` | stub | /build | — | no | 3 |
| `build.edit.weapon` | stub | /build | — | no | 5 |
| `build.edit.weapon.reuse` | stub | /build | build-edit-weapon-reuse | no | 2 |
| `build.edit.weapon.create` | stub | /build | build-edit-weapon-create | no | 3 |
| `build.edit.weapon.exotic-limit` | stub | /build | — | no | 2 |
| `build.edit.stale-pin` | stub | /build | — | no | 2 |
| `build.finish` | stub | /build | — | no | 9 |
| `build.finish.armor-optimize` | stub | /build | — | no | 6 |
| `build.finish.equip-gate` | stub | /build | — | no | 4 |
| `build.conflicts` | stub | /build | — | no | 6 |
| `catalog.signed-out.weapons` | stub | /catalog | catalog-signed-out-weapons | no | 4 |
| `catalog.signed-out.armor` | stub | /catalog | catalog-signed-out-armor | no | 3 |
| `catalog.weapons.owned` | stub | /catalog | catalog-weapons-owned | no | 6 |
| `catalog.weapons.manifest` | stub | /catalog | catalog-weapons-manifest | no | 4 |
| `catalog.weapon.detail` | stub | /catalog | catalog-weapon-detail | no | 4 |
| `catalog.armor.owned` | stub | /catalog | catalog-armor-owned | no | 4 |
| `catalog.armor.manifest` | stub | /catalog | catalog-armor-manifest | no | 2 |
| `catalog.armor.detail` | stub | /catalog | catalog-armor-detail | no | 3 |
| `catalog.universal` | stub | /catalog | catalog-universal | no | 4 |
| `sets.signed-out` | stub | /sets | sets-signed-out | no | 2 |
| `sets.library` | stub | /sets | sets-library | no | 8 |
| `sets.create` | stub | /sets | sets-create | no | 7 |
| `sets.detail` | stub | /sets | sets-detail | no | 6 |
| `sets.edit` | stub | /sets | sets-edit | no | 3 |
| `sets.fill-slot` | stub | /sets | sets-fill-slot | no | 6 |
| `sets.fill-slot.exotic-block` | stub | /sets | — | no | 4 |
| `synergy.signed-out` | stub | /synergy | synergy-signed-out | no | 1 |
| `synergy.library` | stub | /synergy | synergy-library | no | 6 |
| `synergy.create` | stub | /synergy | synergy-create | no | 8 |
| `synergy.detail` | stub | /synergy | synergy-detail | no | 8 |
| `synergy.edit` | stub | /synergy | — | no | 3 |
| `loadouts.signed-out` | stub | /loadouts | loadouts-signed-out | no | 2 |
| `loadouts.list` | stub | /loadouts | — | no | 5 |
| `loadouts.slot-expanded` | stub | /loadouts | loadouts-slot-expanded | no | 0 |
| `settings.signed-out` | stub | /settings | settings-signed-out | no | 1 |
| `settings.signed-in` | stub | /settings | settings-signed-in | no | 2 |
| `build.finish.one-tap-create` | stub | /build | — | no | 0 |
| `build.finish.capture` | stub | /build | — | no | 0 |
| `build.finish.slot-loop` | stub | /build | — | no | 0 |
| `build.create.draft.general` | stub | /build | build-create-draft-general | no | 0 |
| `build.create.draft.locked.tabs` | stub | /build | build-create-draft-locked-tabs | no | 0 |
| `build.edit.finish` | stub | /build | build-edit-finish | no | 0 |
| `catalog.filters.open` | stub | /catalog | catalog-filters-open | no | 0 |
| `loadouts.signed.in` | stub | /loadouts | loadouts-signed-in | no | 0 |

## Checklist

- [ ] Flutter Windows shell routes match `platforms.flutter-windows.route`
- [ ] Hard/soft guidance parity tests (domain package)
- [ ] Capture stubs filled as screens land (`npm run atlas:capture:flutter-windows` when available)
- [ ] No DBR/DAC forks for Flutter
