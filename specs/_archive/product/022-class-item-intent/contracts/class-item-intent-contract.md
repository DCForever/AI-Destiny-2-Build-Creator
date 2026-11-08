# Contract: Class-Item Intent Identity

## Detection

`resolveExoticArmorIdentityMode(build, resolved?)` → `"classic" | "class_item_intent"`

## PATCH build exoticArmorHash

When change is class-item → class-item (intent mode): **200** without `identityAction`.

When change is classic hash swap or mode flip: **409** `IDENTITY_CONFIRM_REQUIRED` unless `identityAction` is `confirm`|`fork` (015 contract).

## Resolved claim (intent)

```json
{
  "slot": "class_item",
  "itemHash": 123,
  "itemName": "...",
  "source": "set" | "build_exotic_armor" | "pair_set",
  "selectedPerks": [1, 2, 3],
  "instanceId": "optional"
}
```

## Soft coverage

Intent mismatch surfaces as existing synergy `weak`/`missing` rows — not a new error code.
