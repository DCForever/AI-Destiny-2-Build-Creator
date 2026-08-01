// Next parity: `src/lib/inventory/instances/classifyWeaponSocket.ts` (DART-052).

/// Column kinds for instance perk grids / stored socket plugs.
enum SocketColumnKind {
  barrel,
  magazine,
  trait,
  intrinsic,
  origin,
  masterwork,
  catalyst,
}

/// Wire string for [SocketColumnKind] (product JSON / Drift maps).
String socketColumnKindWire(SocketColumnKind kind) => kind.name;

/// Parse wire string → kind; unknown → null.
SocketColumnKind? socketColumnKindFromWire(String? wire) {
  if (wire == null || wire.isEmpty) return null;
  for (final k in SocketColumnKind.values) {
    if (k.name == wire) return k;
  }
  return null;
}

/// Result of classifying one weapon socket for the perk grid.
class SocketClassifyResult {
  const SocketClassifyResult({
    required this.columnKind,
    required this.columnLabel,
    required this.includeInGrid,
  });

  final SocketColumnKind columnKind;
  final String columnLabel;
  final bool includeInGrid;
}

final _excludedPatterns = <RegExp>[
  RegExp(r'shader', caseSensitive: false),
  RegExp(r'tracker', caseSensitive: false),
  RegExp(r'ornament', caseSensitive: false),
  RegExp(r'^enhancements\.', caseSensitive: false),
  RegExp(r'kill.?tracker', caseSensitive: false),
  RegExp(r'objective', caseSensitive: false),
  RegExp(r'emote', caseSensitive: false),
  RegExp(r'clan.?banner', caseSensitive: false),
  RegExp(r'armor\.mods', caseSensitive: false),
  RegExp(r'v400\.', caseSensitive: false),
];

const _columnLabels = <SocketColumnKind, String>{
  SocketColumnKind.barrel: 'Barrel',
  SocketColumnKind.magazine: 'Magazine',
  SocketColumnKind.intrinsic: 'Intrinsic',
  SocketColumnKind.origin: 'Origin Trait',
  SocketColumnKind.masterwork: 'Masterwork',
  SocketColumnKind.catalyst: 'Catalyst',
};

String _intrinsicLabel(String category) {
  if (RegExp(r'^frames$', caseSensitive: false).hasMatch(category) ||
      RegExp(r'frames\.', caseSensitive: false).hasMatch(category)) {
    return 'Frame';
  }
  return _columnLabels[SocketColumnKind.intrinsic]!;
}

bool _isCosmeticCategory(String category) {
  for (final pattern in _excludedPatterns) {
    if (pattern.hasMatch(category)) return true;
  }
  return false;
}

SocketColumnKind? _kindFromCategory(
  String category,
  String? itemTypeDisplayName,
) {
  if (category.contains('masterwork')) return SocketColumnKind.masterwork;
  if (category.contains('catalyst')) return SocketColumnKind.catalyst;
  if (category.contains('origins')) return SocketColumnKind.origin;
  if (RegExp(r'^intrinsics$', caseSensitive: false).hasMatch(category) ||
      RegExp(r'^intrinsics\.', caseSensitive: false).hasMatch(category)) {
    return SocketColumnKind.intrinsic;
  }
  // Bare "frames" is often Enhanced Traits — not the weapon intrinsic.
  // Check after origin: "Origin Trait" item type must not become a trait column.
  final type = itemTypeDisplayName ?? '';
  if (RegExp(r'trait', caseSensitive: false).hasMatch(type) &&
      !RegExp(r'origin', caseSensitive: false).hasMatch(type)) {
    return SocketColumnKind.trait;
  }
  if (RegExp(r'^frames$', caseSensitive: false).hasMatch(category)) {
    // Fall through to socket-index trait labeling when type is unknown.
    return null;
  }
  if (RegExp(r'^frames\.', caseSensitive: false).hasMatch(category)) {
    return SocketColumnKind.intrinsic;
  }
  if (RegExp(r'barrels\.?|launchers\.|sights\.|scopes\.').hasMatch(category)) {
    return SocketColumnKind.barrel;
  }
  if (RegExp(r'magazines\.?|batteries\.|hilt\.|guard\.').hasMatch(category)) {
    return SocketColumnKind.magazine;
  }
  if (RegExp(r'traits\.|perks\.|trait').hasMatch(category)) {
    return SocketColumnKind.trait;
  }
  return null;
}

String _traitLabelForIndex(int perkPosition) {
  final traitNumber = perkPosition - 1;
  if (traitNumber <= 1) return 'Trait 1';
  if (traitNumber == 2) return 'Trait 2';
  return 'Trait $traitNumber';
}

/// Classify a weapon socket for inclusion in the instance perk grid.
///
/// Next parity: `classifyWeaponSocket`.
SocketClassifyResult classifyWeaponSocket({
  required int socketIndex,
  required int equippedPlugHash,
  required Map<int, String> plugCategoryByHash,
  Map<int, String>? plugItemTypeByHash,
  required List<int> weaponPerkSocketIndexes,
}) {
  final category = plugCategoryByHash[equippedPlugHash] ?? '';
  final itemType = plugItemTypeByHash?[equippedPlugHash];
  final SocketColumnKind? kind = category.isNotEmpty
      ? _kindFromCategory(category, itemType)
      : (itemType != null &&
              RegExp(r'trait', caseSensitive: false).hasMatch(itemType)
          ? SocketColumnKind.trait
          : null);

  if (kind == SocketColumnKind.intrinsic) {
    return SocketClassifyResult(
      columnKind: SocketColumnKind.intrinsic,
      columnLabel: _intrinsicLabel(category),
      includeInGrid: true,
    );
  }
  if (kind == SocketColumnKind.origin) {
    return SocketClassifyResult(
      columnKind: SocketColumnKind.origin,
      columnLabel: _columnLabels[SocketColumnKind.origin]!,
      includeInGrid: true,
    );
  }
  if (kind == SocketColumnKind.masterwork) {
    // Kill trackers often use a masterwork-like category; hide pure trackers.
    if (RegExp(r'tracker', caseSensitive: false).hasMatch(itemType ?? '') ||
        RegExp(r'tracker', caseSensitive: false).hasMatch(category)) {
      return const SocketClassifyResult(
        columnKind: SocketColumnKind.masterwork,
        columnLabel: '',
        includeInGrid: false,
      );
    }
    return SocketClassifyResult(
      columnKind: SocketColumnKind.masterwork,
      columnLabel: _columnLabels[SocketColumnKind.masterwork]!,
      includeInGrid: true,
    );
  }
  if (kind == SocketColumnKind.catalyst) {
    return SocketClassifyResult(
      columnKind: SocketColumnKind.catalyst,
      columnLabel: _columnLabels[SocketColumnKind.catalyst]!,
      includeInGrid: true,
    );
  }

  if (category.isNotEmpty && _isCosmeticCategory(category)) {
    return const SocketClassifyResult(
      columnKind: SocketColumnKind.trait,
      columnLabel: '',
      includeInGrid: false,
    );
  }

  if (kind == SocketColumnKind.barrel) {
    return SocketClassifyResult(
      columnKind: SocketColumnKind.barrel,
      columnLabel: _columnLabels[SocketColumnKind.barrel]!,
      includeInGrid: true,
    );
  }
  if (kind == SocketColumnKind.magazine) {
    return SocketClassifyResult(
      columnKind: SocketColumnKind.magazine,
      columnLabel: _columnLabels[SocketColumnKind.magazine]!,
      includeInGrid: true,
    );
  }

  final perkPosition = weaponPerkSocketIndexes.indexOf(socketIndex);
  if (perkPosition == -1) {
    return const SocketClassifyResult(
      columnKind: SocketColumnKind.trait,
      columnLabel: '',
      includeInGrid: false,
    );
  }
  if (perkPosition == 0) {
    return SocketClassifyResult(
      columnKind: SocketColumnKind.barrel,
      columnLabel: _columnLabels[SocketColumnKind.barrel]!,
      includeInGrid: true,
    );
  }
  if (perkPosition == 1) {
    return SocketClassifyResult(
      columnKind: SocketColumnKind.magazine,
      columnLabel: _columnLabels[SocketColumnKind.magazine]!,
      includeInGrid: true,
    );
  }

  return SocketClassifyResult(
    columnKind: SocketColumnKind.trait,
    columnLabel: _traitLabelForIndex(perkPosition),
    includeInGrid: true,
  );
}

/// Whether a plug is an enhanced variant (display helper).
bool isEnhancedPlug(String? name, String category) {
  if (RegExp(r'enhanced', caseSensitive: false).hasMatch(name ?? '')) {
    return true;
  }
  return RegExp(r'enhancements\.v2|enhanced', caseSensitive: false)
      .hasMatch(category);
}

/// Format perk display name with optional Enhanced suffix.
String formatPerkDisplayName(String? name, int hash, bool isEnhanced) {
  final base = name ?? '$hash';
  if (isEnhanced && !RegExp(r'enhanced', caseSensitive: false).hasMatch(base)) {
    return '$base (Enhanced)';
  }
  return base;
}
