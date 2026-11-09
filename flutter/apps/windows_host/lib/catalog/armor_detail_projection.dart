import 'package:destiny2_db/destiny2_db.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';

/// Map inventory [CatalogInstanceProjection] rows into armor detail DTOs.
///
/// Dual boards: Base from [CatalogInstanceProjection.armorStats] (or plug
/// base when host pre-filled), Live from [statValues] when resolvable.
/// Never invents rolls, energy capacity, or set-bonus text.
///
/// Energy: only when socket/plug data exposes used+capacity honestly.
List<ArmorInstanceStripItem> projectArmorInstances(
  List<CatalogInstanceProjection> instances, {
  Map<int, String> plugNameByHash = const {},
}) {
  final out = <ArmorInstanceStripItem>[];
  for (final inst in instances) {
    final baseBoard = _baseBoard(inst);
    final liveBoard = _liveBoard(inst);
    final mods = _modPlugs(inst, plugNameByHash);
    final energy = _energy(inst, mods);

    out.add(
      ArmorInstanceStripItem(
        instanceId: inst.instanceId,
        power: inst.power,
        baseTotal: baseBoard?.total,
        gearTier: inst.gearTier,
        location: inst.location,
        baseBoard: baseBoard,
        liveBoard: liveBoard,
        liveUnavailable: liveBoard == null,
        mods: mods,
        energy: energy,
      ),
    );
  }
  return ArmorInstanceStrip.sortByBaseTotal(out);
}

ArmorStatBoardData? _baseBoard(CatalogInstanceProjection inst) {
  final board = inst.armorStats;
  if (board == null || !board.hasAny) return null;
  return ArmorStatBoardData(
    stats: Map<String, int>.from(board.stats),
    total: board.total,
    incomplete: board.incomplete,
  );
}

ArmorStatBoardData? _liveBoard(CatalogInstanceProjection inst) {
  final live = buildArmorBaseStatBoard(inst.statValues);
  if (live == null || !live.hasAny) return null;
  return ArmorStatBoardData(
    stats: Map<String, int>.from(live.stats),
    total: live.total,
    incomplete: live.incomplete,
  );
}

List<ArmorModPlugData> _modPlugs(
  CatalogInstanceProjection inst,
  Map<int, String> plugNameByHash,
) {
  final out = <ArmorModPlugData>[];
  final seen = <int>{};

  void add(int hash, {String? label}) {
    if (hash == 0 || seen.contains(hash)) return;
    seen.add(hash);
    final name = plugNameByHash[hash] ?? label;
    if (name == null || name.isEmpty) return;
    // Skip unknown bare-hash presentation as invent — host may omit.
    out.add(ArmorModPlugData(hash: hash, displayName: name));
  }

  for (final card in inst.plugCards) {
    // Prefer non-trait armor plugs as "mods" when columnKind hints mod.
    final kind = (card.columnKind ?? '').toLowerCase();
    final label = (card.columnLabel ?? '').toLowerCase();
    final isMod = kind.contains('mod') ||
        label.contains('mod') ||
        kind.contains('armor') ||
        card.isTrait == false && kind.isNotEmpty;
    if (isMod || inst.plugCards.length <= 6) {
      add(card.hash, label: card.displayName);
    }
  }

  // Flat plug hashes only when we have resolved names (never invent).
  if (out.isEmpty) {
    for (final h in inst.plugHashes) {
      final name = plugNameByHash[h];
      if (name != null && name.isNotEmpty) add(h, label: name);
    }
  }

  return out;
}

ArmorEnergyData? _energy(
  CatalogInstanceProjection inst,
  List<ArmorModPlugData> mods,
) {
  // Honest energy only from statValues keys when present — never invent 10.
  final sv = inst.statValues;
  if (sv == null) return null;
  int? used;
  int? capacity;
  for (final e in sv.entries) {
    final k = e.key.toLowerCase().replaceAll(RegExp(r'[\s_]'), '');
    final n = e.value is int
        ? e.value as int
        : e.value is num
            ? (e.value as num).toInt()
            : int.tryParse('${e.value}');
    if (n == null) continue;
    if (k == 'energyused' || k == 'usedenergy') used = n;
    if (k == 'energycapacity' || k == 'energy' || k == 'energycapacity') {
      capacity = n;
    }
  }
  if (used != null && capacity != null && capacity > 0) {
    return ArmorEnergyData(used: used, capacity: capacity);
  }
  return null;
}

/// Build [ArmorSetBonusData] from optional definition strings (never invent).
ArmorSetBonusData? armorSetBonusFromDefinition({
  String? setName,
  String? twoPiece,
  String? fourPiece,
  bool? knownNone,
}) {
  if (knownNone == true) {
    return const ArmorSetBonusData(explicitNone: true);
  }
  final has = (setName != null && setName.trim().isNotEmpty) ||
      (twoPiece != null && twoPiece.trim().isNotEmpty) ||
      (fourPiece != null && fourPiece.trim().isNotEmpty);
  if (!has) return null;
  return ArmorSetBonusData(
    setName: setName,
    twoPiece: twoPiece,
    fourPiece: fourPiece,
  );
}

/// Exotic perk from catalog identity fields (intrinsic only — no invent pools).
ArmorExoticPerkData? armorExoticPerkFromItem({
  required bool isExotic,
  String? intrinsicName,
  String? description,
}) {
  if (!isExotic) return null;
  final name = intrinsicName?.trim();
  if (name == null || name.isEmpty) return null;
  return ArmorExoticPerkData(
    name: name,
    description: description,
  );
}
