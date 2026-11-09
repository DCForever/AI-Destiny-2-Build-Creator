# Data Model: Build Synergy Types

## Synergy Type (build designation)

| Field | Notes |
|-------|-------|
| type | Creatable synergy category (`verb`, `melee`, `primary_weapon`, …) |
| subType | Required when category requires it (verb, melee, grenade, super, element, weapon_archetype); else null |

Stored on `build_synergy_types`: `(build_id, type, sub_type, attached_at)` with unique `(build_id, type, sub_type)`.

## Synergy (library)

Unchanged: `synergies` + `synergy_links` — Type + Object(s).

## Bridge result

| Field | Notes |
|-------|-------|
| designations | Synergy Type[] on the build |
| matchedSynergies | SynergyWithLinks[] matching any designation |
| byDesignation | Map designation key → matched records |

Matching: `user_id` + `type` + `sub_type` (null-safe equality). Multiple library rows for the same key are **unioned**.

## Migration

From `build_synergies` join `synergies` → distinct `(build_id, type, sub_type)` into `build_synergy_types`; drop `build_synergies`.
