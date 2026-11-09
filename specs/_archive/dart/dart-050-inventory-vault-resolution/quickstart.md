# Quickstart: DART-050 Inventory Vault Resolution

## Verify package

```powershell
cd F:\Destiny2BuildCreator-multiplatform-dart
dart test packages/bungie
```

Expect vault-with-lookup tests to show `resolvedFromTransfer > 0` and Kinetic (or armor) stored buckets.

## Verify Windows host tests

```powershell
cd apps/windows_host
flutter test test/inventory_sync_controller_test.dart
```

Vault fixtures must pass only when lookup is wired.

## Production path (Windows)

1. Manifest refresh downloads `DestinyInventoryItemDefinition` (DART-018).
2. Settings **Sync inventory** builds lookup for transfer hashes and calls `syncUserInventory`.
3. Equip **syncIfStale** uses the same builder.
4. Owned catalog still needs entity stores populated (GAP-INV-06 → DART-053).

## Non-goals

Do not expect roll tags, socket column labels, or live Next dual-run counts from this slice.
