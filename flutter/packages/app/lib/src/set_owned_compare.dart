/// Owned-only armor compare rank for Sets fill (G-SET-002 secondary path).
///
/// Ranks **owned instances only** by total then EoF stats. Instance identity
/// is required (not name-only). Second exotic hard-block is enforced by hosts
/// via [assertSetExoticExclusivity] — this layer ranks and flags only.
library;

import 'package:destiny2_domain/destiny2_domain.dart';

/// One owned armor instance row for the compare table.
class OwnedArmorCompareRow {
  const OwnedArmorCompareRow({
    required this.instanceId,
    required this.itemHash,
    required this.itemName,
    required this.slot,
    this.isExotic = false,
    this.power,
    this.setBonusKey,
    this.statValues = const {},
    this.bonusFit = false,
  });

  /// Stable inventory instance id (required for multi-copy honesty).
  final String instanceId;
  final int itemHash;
  final String itemName;

  /// Equipment bucket / set slot wire (Helmet, helmet, …).
  final String slot;
  final bool isExotic;
  final int? power;
  final String? setBonusKey;

  /// Base six EoF stats (Health · Melee · Grenade · Super · Class · Weapons).
  final Map<ArmorStatName, int> statValues;

  /// Whether this piece contributes to current hard bonus goals.
  final bool bonusFit;

  int get totalStats {
    var sum = 0;
    for (final s in ArmorStatName.all) {
      sum += statValues[s] ?? 0;
    }
    return sum;
  }

  int statOf(ArmorStatName s) => statValues[s] ?? 0;
}

/// Rank key: higher total first, then EoF left→right, then power, then name.
int compareOwnedArmorRows(OwnedArmorCompareRow a, OwnedArmorCompareRow b) {
  final totalCmp = b.totalStats.compareTo(a.totalStats);
  if (totalCmp != 0) return totalCmp;
  for (final s in ArmorStatName.all) {
    final c = b.statOf(s).compareTo(a.statOf(s));
    if (c != 0) return c;
  }
  final powerA = a.power ?? 0;
  final powerB = b.power ?? 0;
  final powerCmp = powerB.compareTo(powerA);
  if (powerCmp != 0) return powerCmp;
  return a.itemName.toLowerCase().compareTo(b.itemName.toLowerCase());
}

/// Sort a copy of [rows] by total / EoF rank (owned-only; caller filters unowned).
List<OwnedArmorCompareRow> rankOwnedArmorCompare(
  Iterable<OwnedArmorCompareRow> rows,
) {
  final list = List<OwnedArmorCompareRow>.from(rows);
  list.sort(compareOwnedArmorRows);
  return List.unmodifiable(list);
}

/// Drop rows without a non-empty [OwnedArmorCompareRow.instanceId] (honesty).
List<OwnedArmorCompareRow> filterOwnedWithInstanceIdentity(
  Iterable<OwnedArmorCompareRow> rows,
) {
  return List.unmodifiable([
    for (final r in rows)
      if (r.instanceId.trim().isNotEmpty) r,
  ]);
}

/// Annotate [bonusFit] when piece set-bonus key is in [goalKeys] (non-exotic).
List<OwnedArmorCompareRow> annotateBonusFit({
  required Iterable<OwnedArmorCompareRow> rows,
  required Iterable<String> goalKeys,
}) {
  final keys = {
    for (final k in goalKeys)
      if (k.trim().isNotEmpty) k.trim().toLowerCase(),
  };
  return List.unmodifiable([
    for (final r in rows)
      OwnedArmorCompareRow(
        instanceId: r.instanceId,
        itemHash: r.itemHash,
        itemName: r.itemName,
        slot: r.slot,
        isExotic: r.isExotic,
        power: r.power,
        setBonusKey: r.setBonusKey,
        statValues: r.statValues,
        bonusFit: !r.isExotic &&
            r.setBonusKey != null &&
            keys.contains(r.setBonusKey!.trim().toLowerCase()),
      ),
  ]);
}

/// True when selecting [candidate] would violate armor exotic exclusivity
/// given [otherOccupied] (excluding the target slot being filled).
bool wouldBlockSecondExotic({
  required bool candidateIsExotic,
  required Iterable<({String slot, bool isExotic, String? name})> otherOccupied,
}) {
  if (!candidateIsExotic) return false;
  for (final o in otherOccupied) {
    if (o.isExotic) return true;
  }
  return false;
}
