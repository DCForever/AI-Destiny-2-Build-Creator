import 'entity_cache.dart';
import 'types/records.dart';
import 'types/services.dart';
import 'types/stores.dart';

/// Deterministic perk legality checks from entity stores.
class StorePerkValidator {
  StorePerkValidator(this.cache);

  final FileEntityCache cache;

  Future<PerkLegality> checkWeaponPerk(Hash weaponHash, Hash perkHash) async {
    final weapons = await cache.getStore<WeaponRecord>(MvpStoreName.weapons);
    WeaponRecord? weapon;
    for (final w in weapons) {
      if (w.hash == weaponHash) {
        weapon = w;
        break;
      }
    }
    if (weapon == null) {
      return PerkIllegal(
        'weapon hash $weaponHash not found in legendary weapon store',
      );
    }

    for (final column in weapon.perkColumns) {
      if (column.curated.contains(perkHash)) {
        return PerkLegal(column: column.column, curated: true);
      }
      if (column.randomized.contains(perkHash)) {
        return PerkLegal(column: column.column, curated: false);
      }
    }
    return PerkIllegal(
      'perk hash $perkHash is not available on ${weapon.name} (hash ${weapon.hash})',
    );
  }

  Future<FragmentCountCheck> checkFragmentCount(
    List<Hash> aspectHashes,
    int fragmentCount,
  ) async {
    final aspects = await cache.getStore<AspectRecord>(MvpStoreName.aspects);
    final byHash = {for (final a in aspects) a.hash: a};

    var capacity = 0;
    for (final hash in aspectHashes) {
      final aspect = byHash[hash];
      if (aspect != null) capacity += aspect.fragmentCapacity;
    }

    return FragmentCountCheck(
      legal: fragmentCount <= capacity,
      capacity: capacity,
      requested: fragmentCount,
    );
  }
}
