// Canonical Destiny weapon itemTypeDisplayName values for preference pickers.
// Port of `src/data/weaponTypes.ts`.

const List<String> knownWeaponTypes = [
  'Auto Rifle',
  'Bow',
  'Fusion Rifle',
  'Glaive',
  'Grenade Launcher',
  'Hand Cannon',
  'Linear Fusion Rifle',
  'Machine Gun',
  'Pulse Rifle',
  'Rocket Launcher',
  'Scout Rifle',
  'Shotgun',
  'Sidearm',
  'Sniper Rifle',
  'Submachine Gun',
  'Sword',
  'Trace Rifle',
];

final Set<String> _knownSet = knownWeaponTypes.toSet();

bool isKnownWeaponType(String name) => _knownSet.contains(name.trim());

// Keep only vocabulary members; drop unknown free-text entries.
List<String> filterKnownWeaponTypes(Iterable<String> names) {
  final out = <String>[];
  final seen = <String>{};
  for (final raw in names) {
    final name = raw.trim();
    if (!isKnownWeaponType(name) || seen.contains(name)) continue;
    seen.add(name);
    out.add(name);
  }
  return out;
}

List<String> toggleWeaponType(Iterable<String> selected, String type) {
  final current = filterKnownWeaponTypes(selected);
  if (current.contains(type)) {
    return current.where((t) => t != type).toList(growable: false);
  }
  return [...current, type];
}
