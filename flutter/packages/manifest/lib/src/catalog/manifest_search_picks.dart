/// Manifest/catalog name search for identity + subclass kit pickers (DART-064).
///
/// Filters offline [CatalogItem] rows — hashes are not the primary UI input.
library;

import '../types/stores.dart';
import 'catalog_item.dart';

/// Kind of Manifest pick surface.
enum ManifestPickKind {
  exoticArmor,
  exoticWeapon,
  superAbility,
  aspect,
  fragment,
  melee,
  grenade,
  classAbility,
}

/// One named pick for host pickers (GAP-UI-BUILD-05).
class ManifestPick {
  const ManifestPick({
    required this.hash,
    required this.name,
    this.icon,
    this.subtitle,
    this.sourceStore,
  });

  final int hash;
  final String name;
  final String? icon;
  final String? subtitle;
  final String? sourceStore;
}

bool _matchesQuery(CatalogItem item, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return true;
  final name = item.name.toLowerCase();
  final desc = (item.description ?? '').toLowerCase();
  final slot = (item.slot ?? '').toLowerCase();
  return name.contains(q) || desc.contains(q) || slot.contains(q);
}

bool _isStore(CatalogItem item, String stem) =>
    (item.sourceStore ?? '').toLowerCase() == stem.toLowerCase();

bool _looksLikeSuper(CatalogItem item) {
  final type = (item.itemTypeName ?? '').toLowerCase();
  final slot = (item.slot ?? '').toLowerCase();
  final desc = (item.description ?? '').toLowerCase();
  if (type.contains('super') || slot == 'super' || slot.contains('super')) {
    return true;
  }
  // Abilities store often uses itemTypeName / description markers.
  if (_isStore(item, MvpStoreName.abilities.fileStem)) {
    return type == 'super' ||
        type.contains('super') ||
        desc.startsWith('super:') ||
        slot == AbilityKindMarker.superAbility;
  }
  return false;
}

/// Lightweight markers when catalog rows lack full AbilityKind.
abstract final class AbilityKindMarker {
  static const superAbility = 'super';
  static const melee = 'melee';
  static const grenade = 'grenade';
  static const classAbility = 'classability';
}

bool _abilityKindMatch(CatalogItem item, String kind) {
  if (!_isStore(item, MvpStoreName.abilities.fileStem) &&
      (item.sourceStore ?? '').isNotEmpty) {
    // Still allow if itemTypeName/slot encode kind without store stem (tests).
  }
  final type = (item.itemTypeName ?? '').toLowerCase();
  final slot = (item.slot ?? '').toLowerCase();
  final k = kind.toLowerCase();
  return type == k ||
      type.contains(k) ||
      slot == k ||
      slot.contains(k) ||
      (item.description ?? '').toLowerCase().startsWith('$k:');
}

/// Filter catalog base items into searchable named picks for [kind].
List<ManifestPick> searchManifestPicks({
  required List<CatalogItem> items,
  required ManifestPickKind kind,
  String query = '',
  String? classType,
  int limit = 40,
}) {
  final classFilter = classType?.trim().toLowerCase();
  bool classOk(CatalogItem i) {
    if (classFilter == null || classFilter.isEmpty) return true;
    final c = (i.classType ?? '').toLowerCase();
    if (c.isEmpty) return true; // classless fragments etc.
    return c == classFilter;
  }

  Iterable<CatalogItem> filtered;
  switch (kind) {
    case ManifestPickKind.exoticArmor:
      filtered = items.where(
        (i) =>
            (_isStore(i, MvpStoreName.exoticArmor.fileStem) ||
                (i.isExotic &&
                    (i.slot == 'Helmet' ||
                        i.slot == 'Gauntlets' ||
                        i.slot == 'Chest' ||
                        i.slot == 'Legs' ||
                        i.slot == 'ClassItem' ||
                        (i.itemTypeName ?? '').toLowerCase().contains('armor')))) &&
            classOk(i) &&
            _matchesQuery(i, query),
      );
    case ManifestPickKind.exoticWeapon:
      filtered = items.where(
        (i) =>
            (_isStore(i, MvpStoreName.exoticWeapons.fileStem) ||
                (i.isExotic &&
                    (i.ammo != null ||
                        (i.itemTypeName ?? '')
                            .toLowerCase()
                            .contains('weapon')))) &&
            _matchesQuery(i, query),
      );
    case ManifestPickKind.superAbility:
      filtered = items.where(
        (i) => _looksLikeSuper(i) && classOk(i) && _matchesQuery(i, query),
      );
    case ManifestPickKind.aspect:
      filtered = items.where(
        (i) =>
            _isStore(i, MvpStoreName.aspects.fileStem) &&
            classOk(i) &&
            _matchesQuery(i, query),
      );
    case ManifestPickKind.fragment:
      filtered = items.where(
        (i) =>
            _isStore(i, MvpStoreName.fragments.fileStem) &&
            _matchesQuery(i, query),
      );
    case ManifestPickKind.melee:
      filtered = items.where(
        (i) =>
            _abilityKindMatch(i, AbilityKindMarker.melee) &&
            classOk(i) &&
            _matchesQuery(i, query),
      );
    case ManifestPickKind.grenade:
      filtered = items.where(
        (i) =>
            _abilityKindMatch(i, AbilityKindMarker.grenade) &&
            classOk(i) &&
            _matchesQuery(i, query),
      );
    case ManifestPickKind.classAbility:
      filtered = items.where(
        (i) =>
            _abilityKindMatch(i, AbilityKindMarker.classAbility) &&
            classOk(i) &&
            _matchesQuery(i, query),
      );
  }

  final ranked = filtered.toList()
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  return [
    for (final i in ranked.take(limit))
      ManifestPick(
        hash: i.hash,
        name: i.name,
        icon: i.icon,
        subtitle: [
          if (i.slot != null && i.slot!.isNotEmpty) i.slot!,
          if (i.element != null && i.element!.isNotEmpty) i.element!,
          if (i.classType != null && i.classType!.isNotEmpty) i.classType!,
        ].join(' · '),
        sourceStore: i.sourceStore,
      ),
  ];
}
