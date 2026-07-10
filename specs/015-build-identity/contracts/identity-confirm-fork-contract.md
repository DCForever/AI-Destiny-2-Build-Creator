# Contract: Identity Confirm / Fork

**Feature**: 015-build-identity  
**Type**: API two-step confirm + fork  
**Related**: [data-model.md](../data-model.md), set `confirmReplace` / `SLOT_OCCUPIED` pattern

## Purpose

Changing identity fields requires an explicit **confirm in-place** or **fork** before mutation applies.

## Identity fields

A PATCH is an **identity edit** if any of these change (including clear → null):

- `synergyIds`
- `exoticArmorHash` / `exoticArmorName` (when treated as set/clear of armor identity)
- `exoticWeaponHash` / `exoticWeaponName` at **build** level (shared weapon)
- `pinnedSuper`

Non-identity (no confirm): `tagIds`, `name` (rename), variant-only exotic weapon via variant PATCH, attachment edits.

## PATCH `/api/user/builds/:id`

### First attempt (identity change, no action)

```json
{
  "synergyIds": ["new-synergy-id"]
}
```

**Response**: `409` (or `400` consistent with set occupied pattern — prefer **409**)

```json
{
  "error": "IDENTITY_CONFIRM_REQUIRED",
  "identityFields": ["synergyIds"],
  "message": "Confirm in-place or fork to apply identity changes."
}
```

### Confirm in-place

```json
{
  "synergyIds": ["new-synergy-id"],
  "identityAction": "confirm"
}
```

**Result**: Same build id updated; all variants remain under this build.

### Fork

```json
{
  "synergyIds": ["new-synergy-id"],
  "identityAction": "fork"
}
```

**Result**:

| Target | State |
|--------|--------|
| Original build | Unchanged identity |
| New build | New id; identity from request; copies all variants (default preserved); tags + subclass copied; attachments **snapshot-cloned** |

Response includes `{ build: <new build detail>, forkedFromId: "<original>" }` (exact shape in implementation tests).

## Debug UI

`BuildsDebugPage` MUST surface Confirm in-place / Fork when API returns `IDENTITY_CONFIRM_REQUIRED`, then resubmit with `identityAction` (same pattern as set slot confirm).
