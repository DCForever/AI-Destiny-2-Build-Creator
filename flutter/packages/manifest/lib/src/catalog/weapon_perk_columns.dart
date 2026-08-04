import '../types/records.dart';

/// Client-safe labels for definition perk column indexes (Next `columnIndexToLabel`).
String columnIndexToLabel(int column) {
  const labels = [
    'Barrel',
    'Magazine',
    'Trait 1',
    'Trait 2',
    'Trait 3',
    'Trait 4',
  ];
  if (column < 0) return 'Intrinsic';
  if (column < labels.length) return labels[column];
  return 'Trait ${column - 1}';
}

/// Project entity [WeaponPerkColumn] rows into socket-plug maps for the perk grid.
///
/// Shape matches inventory `socket_plugs` so [buildCatalogPerkColumns] can reuse
/// the same path. Does **not** invent plugs — only curated/randomized from stores.
///
/// - [includeRandomized]: when true, `reusablePlugHashes` = curated ∪ randomized
///   (can-roll pool). When false, reusables = curated only (selected defaults).
List<Map<String, Object?>> weaponPerkColumnsToSocketPlugs(
  List<WeaponPerkColumn> columns, {
  bool includeRandomized = true,
}) {
  final out = <Map<String, Object?>>[];
  for (final col in columns) {
    final curated = <int>[
      for (final h in col.curated)
        if (h != 0) h,
    ];
    final randomized = <int>[
      for (final h in col.randomized)
        if (h != 0) h,
    ];
    if (curated.isEmpty && randomized.isEmpty) continue;

    final equipped = curated.isNotEmpty
        ? curated.first
        : (randomized.isNotEmpty ? randomized.first : 0);
    if (equipped == 0) continue;

    final reusable = <int>{
      ...curated,
      if (includeRandomized) ...randomized,
    }.toList(growable: false);

    out.add({
      'socketIndex': col.column,
      'equippedPlugHash': equipped,
      'reusablePlugHashes': reusable,
      'columnKind': _kindForColumnIndex(col.column),
      'columnLabel': columnIndexToLabel(col.column),
    });
  }
  return out;
}

/// Collect all non-zero plug hashes from definition perk columns.
Set<int> collectPlugHashesFromPerkColumns(Iterable<WeaponPerkColumn> columns) {
  final out = <int>{};
  for (final col in columns) {
    for (final h in col.curated) {
      if (h != 0) out.add(h);
    }
    for (final h in col.randomized) {
      if (h != 0) out.add(h);
    }
  }
  return out;
}

/// Merge definition can-roll pools into instance socket maps (by column order).
///
/// Instance sockets keep equipped plugs; definition randomized hashes expand
/// `reusablePlugHashes` when can-roll is on. Skips intrinsic/masterwork/catalyst
/// instance columns when aligning to definition perk indexes.
List<Map<String, Object?>> mergeDefinitionPoolsIntoSockets(
  List<Map<String, Object?>> instanceSockets,
  List<WeaponPerkColumn> definitionColumns,
) {
  if (definitionColumns.isEmpty) return instanceSockets;

  final defByIndex = <int, WeaponPerkColumn>{
    for (final c in definitionColumns) c.column: c,
  };

  // Align non-meta instance columns to definition column 0,1,2…
  var defCursor = 0;
  final out = <Map<String, Object?>>[];
  for (final raw in instanceSockets) {
    final kind = (raw['columnKind'] as String?)?.toLowerCase() ?? '';
    final isMeta = kind == 'intrinsic' ||
        kind == 'masterwork' ||
        kind == 'catalyst' ||
        kind == 'origin';

    final map = Map<String, Object?>.from(raw);
    if (!isMeta) {
      final def = defByIndex[defCursor] ??
          (defCursor < definitionColumns.length
              ? definitionColumns[defCursor]
              : null);
      defCursor++;
      if (def != null) {
        final existing = <int>{};
        final reusableRaw = map['reusablePlugHashes'];
        if (reusableRaw is List) {
          for (final e in reusableRaw) {
            final h = e is int
                ? e
                : e is num
                    ? e.toInt()
                    : int.tryParse('$e');
            if (h != null && h != 0) existing.add(h);
          }
        }
        for (final h in def.curated) {
          if (h != 0) existing.add(h);
        }
        for (final h in def.randomized) {
          if (h != 0) existing.add(h);
        }
        map['reusablePlugHashes'] = existing.toList(growable: false);
      }
    }
    out.add(map);
  }
  return out;
}

String _kindForColumnIndex(int column) {
  if (column < 0) return 'intrinsic';
  if (column == 0) return 'barrel';
  if (column == 1) return 'magazine';
  return 'trait';
}
