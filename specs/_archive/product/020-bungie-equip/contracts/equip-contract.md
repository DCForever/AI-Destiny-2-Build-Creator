# Contract: POST Equip

`POST /api/user/builds/:id/variants/:variantId/equip`

```json
{ "characterId": "230584..." }
```

**Preconditions**
- Auth required
- Variant equip-ready → else `NOT_EQUIP_READY` (409)
- Character class matches build → else `400 INVALID_CHARACTER`

**Behavior**
1. Sync if stale (>60s since lastFullSyncAt)
2. Plan transfers + equips + artifact/fashion
3. Execute best-effort; return status

**Response 200**
```json
{
  "status": {
    "steps": [
      { "id": "transfer-helmet", "kind": "transfer", "ok": true },
      { "id": "equip-helmet", "kind": "equip", "ok": false, "error": "..." }
    ],
    "completed": 1,
    "failed": 1
  }
}
```
