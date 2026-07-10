# Contract: POST Variant DIM Export

`POST /api/user/builds/:id/variants/:variantId/dim-export`

```json
{ "jsonOnly": false }
```

**Preconditions**
- Auth required
- Variant equip-ready → else `NOT_EQUIP_READY` (409)
- When `jsonOnly` is false/omitted: `DIM_API_KEY` required else 503; Bungie session required for share

**Behavior**
1. `assertEquipReady`
2. Collect mods; `buildVariantDimLoadout`
3. If not jsonOnly: DimSync auth + share → `shareUrl`
4. Return `{ loadout, shareUrl? }`

**Response 200**
```json
{
  "loadout": { "id": "...", "name": "...", "classType": 1, "equipped": [], "unequipped": [], "parameters": {} },
  "shareUrl": "https://dim.gg/..."
}
```

**Response 200 (jsonOnly)**
```json
{ "loadout": { "...": "..." } }
```

**Errors**: 401 not signed in; 404 missing; 409 NOT_EQUIP_READY; 503 DIM/Bungie not configured; 502 DIM share failure.
