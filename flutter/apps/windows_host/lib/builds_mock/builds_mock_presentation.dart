import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';

import 'builds_mock_derived_name.dart';
import 'builds_mock_gear_tables.dart';
import 'builds_mock_models.dart';
import 'builds_mock_proposed_sets.dart';
import '../fill_in/fill_in_build_mapper.dart';

bool _nameMatchesExotic(String? pieceName, String exoticName) {
  final piece = (pieceName ?? '').trim();
  final exotic = exoticName.trim();
  if (piece.isEmpty || exotic.isEmpty) return false;
  return piece.toLowerCase() == exotic.toLowerCase();
}

/// Whether a build has any saved Fill In apply / proposed / filled rows.
bool buildsMockHasFillIn(FillInSavedBuildPlan? plan) {
  if (plan == null) return false;
  if (plan.hasAppliedSubstitutes) return true;
  for (final row in plan.rows) {
    final s = row.state.trim().toLowerCase();
    if (s == 'filled' || s == 'proposed') return true;
  }
  return false;
}

BuildsMockSlotStatus _statusForSlot({
  required String slotWire,
  required MockSlotAssignment? assignment,
  FillInSavedBuildPlan? plan,
}) {
  // Substitute fills stay visibly "proposed", not "Filled in".
  if (assignment?.isSubstitute == true &&
      (assignment!.pieceName.trim().isNotEmpty)) {
    return BuildsMockSlotStatus.proposed;
  }
  // Never treat blank / whitespace names as a filled chip/status.
  if (assignment?.filledIn == true &&
      (assignment!.pieceName.trim().isNotEmpty)) {
    return BuildsMockSlotStatus.filled;
  }
  if (plan != null) {
    for (final row in plan.rows) {
      if (row.slotWire == slotWire) {
        return buildsMockSlotStatusFromWire(row.state);
      }
    }
  }
  final name = assignment?.pieceName.trim() ?? '';
  if (name.isEmpty) return BuildsMockSlotStatus.missing;
  return BuildsMockSlotStatus.held;
}

String _setNameFor(MockBuild build, MockSlotAssignment slot) {
  if (slot.isExoticSlot) return 'Exotic';
  final piece = slot.pieceName.trim().toLowerCase();
  final exoticArmor = build.exoticArmor.trim();
  if (piece.isNotEmpty &&
      exoticArmor.isNotEmpty &&
      piece == exoticArmor.toLowerCase()) {
    return 'Exotic';
  }
  for (final b in build.setBonuses) {
    if (b.setId == slot.setId) return b.setName;
  }
  final id = slot.setId.trim();
  if (id.isEmpty || id.startsWith('dim_')) return '';
  return id;
}

List<BuildsMockArmorRow> buildsMockArmorRows({
  required MockBuild build,
  FillInSavedBuildPlan? plan,
  Map<String, List<String>> modsBySlot = const {},
}) {
  const order = [
    ('helmet', 'Helmet'),
    ('arms', 'Gauntlets'),
    ('chest', 'Chest'),
    ('legs', 'Legs'),
    ('class_item', 'Class Item'),
  ];
  final byWire = <String, MockSlotAssignment>{
    for (final s in build.slots) s.slot: s,
  };
  final rows = <BuildsMockArmorRow>[];
  for (final entry in order) {
    final slot = byWire[entry.$1];
    final name = slot?.pieceName.trim() ?? '';
    final mods = modsBySlot[entry.$1] ?? const <String>[];
    // Always emit a row when mods land on this slot (no Unplaced group).
    if (name.isEmpty && slot == null && mods.isEmpty) continue;
    final display = name.isEmpty ? 'Missing' : name;
    rows.add(
      BuildsMockArmorRow(
        slotLabel: entry.$2,
        itemName: display,
        setName: slot == null ? '' : _setNameFor(build, slot),
        // Null when unknown — never invent a placeholder total.
        statTotal: slot?.statTotal,
        isExotic: (slot?.isExoticSlot ?? false) ||
            _nameMatchesExotic(slot?.pieceName, build.exoticArmor),
        status: _statusForSlot(
          slotWire: entry.$1,
          assignment: slot,
          plan: plan,
        ),
        mods: mods,
      ),
    );
  }
  return rows;
}

List<BuildsMockWeaponRow> buildsMockWeaponRows({
  required MockBuild build,
  FillInSavedBuildPlan? plan,
}) {
  const order = [
    ('primary', 'Kinetic'),
    ('special', 'Energy'),
    ('heavy', 'Power'),
  ];
  final byWire = <String, MockSlotAssignment>{
    for (final s in build.slots) s.slot: s,
  };
  return [
    for (final entry in order)
      () {
        final slot = byWire[entry.$1];
        final name = slot?.pieceName.trim() ?? '';
        final empty = name.isEmpty;
        // Substitute tag is session-only ([MockSlotAssignment.isSubstitute]).
        // Do not infer from plan `proposed` — that state is shared with other
        // Fill In paths and is not persisted as a substitute flag.
        final note = slot?.isSubstitute == true
            ? kWeaponOptimizeSubstituteLabel
            : '';
        return BuildsMockWeaponRow(
          slotLabel: entry.$2,
          itemName: empty ? 'Not in DIM link' : name,
          note: note,
          isExotic: (slot?.isExoticSlot ?? false) ||
              _nameMatchesExotic(name, build.exoticWeapon),
          status: _statusForSlot(
            slotWire: entry.$1,
            assignment: slot,
            plan: plan,
          ),
        );
      }(),
  ];
}

/// Slot wire for a [ModSlotCategory]-style catalog key (manifest JSON).
String? armorSlotWireFromModSlotCategory(String? categoryJson) {
  switch ((categoryJson ?? '').trim()) {
    case 'helmet':
      return 'helmet';
    case 'arms':
      return 'arms';
    case 'chest':
      return 'chest';
    case 'legs':
      return 'legs';
    case 'classItem':
      return 'class_item';
    default:
      return null;
  }
}

/// Place DIM loadout mods under armor slots.
///
/// Prefers offline catalog [slotCategoryByModHash] (manifest ModRecord
/// `plugCategoryIdentifier` → helmet/arms/chest/legs/class item). General /
/// tuning / unknown mods go on the most likely slot with a small
/// `slot guessed` note — never an Unplaced group.
({Map<String, List<String>> bySlot, List<String> unplaced}) placeDimMods({
  required List<CachedDimNamedHash> mods,
  required MockBuild build,
  Map<int, String> slotCategoryByModHash = const {},
}) {
  final bySlot = <String, List<String>>{
    'helmet': <String>[],
    'arms': <String>[],
    'chest': <String>[],
    'legs': <String>[],
    'class_item': <String>[],
  };
  final pieceBySlot = <String, String>{
    for (final s in build.slots)
      if (s.pieceName.trim().isNotEmpty) s.slot: s.pieceName.trim().toLowerCase(),
  };
  for (final mod in mods) {
    final name = mod.name.trim();
    if (name.isEmpty) continue;
    final placed = _placeOneMod(
      name: name,
      hash: mod.hash,
      slotCategoryByModHash: slotCategoryByModHash,
      pieceBySlot: pieceBySlot,
    );
    bySlot[placed.slot]!.add(placed.label);
  }
  // Always empty — kept for call-site compatibility; never populate Unplaced.
  return (bySlot: bySlot, unplaced: const <String>[]);
}

({String slot, String label}) _placeOneMod({
  required String name,
  required int hash,
  required Map<int, String> slotCategoryByModHash,
  required Map<String, String> pieceBySlot,
}) {
  final category = slotCategoryByModHash[hash]?.trim();
  final fromCatalog = armorSlotWireFromModSlotCategory(category);
  if (fromCatalog != null) {
    return (slot: fromCatalog, label: name);
  }

  // General / tuning / unknown: most likely slot + small note (never Unplaced).
  final guessed =
      _guessArmorSlotFromModName(name.toLowerCase(), pieceBySlot) ??
          'class_item';
  return (slot: guessed, label: '$name (slot guessed)');
}

String? _guessArmorSlotFromModName(
  String lower,
  Map<String, String> pieceBySlot,
) {
  if (lower.contains('helmet') || lower.contains('head')) return 'helmet';
  if (lower.contains('gauntlet') ||
      lower.contains('arms') ||
      lower.contains('gloves')) {
    return 'arms';
  }
  if (lower.contains('chest') || lower.contains('plate')) return 'chest';
  if (lower.contains('leg') || lower.contains('boot')) return 'legs';
  if (lower.contains('class item') ||
      lower.contains('bond') ||
      lower.contains('mark') ||
      lower.contains('cloak')) {
    return 'class_item';
  }
  for (final entry in pieceBySlot.entries) {
    if (lower.contains(entry.value)) return entry.key;
  }
  return null;
}

/// Lazy enrichment cache keyed by build id + loadout shareId.
///
/// A hit is valid only when the **source** [MockBuild] is the same object
/// ([identical]). Fill In Apply / Undo call [BuildsMockController.replaceBuild]
/// with a new instance that keeps the same id + DIM share id — identity
/// guards against returning a stale pre-Apply enrichment.
class BuildsMockEnrichmentCache {
  final Map<String, ({MockBuild source, MockBuild enriched})> _cache = {};

  MockBuild enrich(MockBuild build, CachedDimLoadout? loadout) {
    final share = loadout?.shareId ?? '';
    final key = '${build.id}::$share';
    final hit = _cache[key];
    if (hit != null && identical(hit.source, build)) return hit.enriched;
    final next = enrichMockBuildFromDimLoadout(build, loadout: loadout);
    _cache[key] = (source: build, enriched: next);
    return next;
  }

  void invalidate() => _cache.clear();
}

/// Split subclass plugs into ability / aspect / fragment groups when length
/// suggests DIM socket order (5 abilities + 2 aspects + fragments).
({List<String> abilities, List<String> aspects, List<String> fragments})
    splitSubclassPlugs(List<CachedDimNamedHash> plugs) {
  final names = [
    for (final p in plugs)
      if (p.name.trim().isNotEmpty) p.name.trim(),
  ];
  if (names.length >= 7) {
    return (
      abilities: names.sublist(0, 5),
      aspects: names.sublist(5, 7),
      fragments: names.sublist(7),
    );
  }
  if (names.length >= 5) {
    return (
      abilities: names.sublist(0, 5),
      aspects: names.length > 5 ? names.sublist(5) : const <String>[],
      fragments: const <String>[],
    );
  }
  return (
    abilities: names,
    aspects: const <String>[],
    fragments: const <String>[],
  );
}

/// Set-bonus boxes for browse/detail cards.
///
/// Uses [proposedSetBonusesFor] so matrix builds with slot / Fill In proposed
/// sets still render (not only fixture [MockBuild.setBonuses]).
List<MockSetBonus> displaySetBonusesFor(
  MockBuild build, {
  FillInSavedBuildPlan? plan,
  List<FillInInventoryItem> armorItems = const [],
  Map<int, String> setBonusKeyByItemHash = const {},
}) {
  return proposedSetBonusesFor(
    build: build,
    plan: plan,
    armorItems: armorItems,
    setBonusKeyByItemHash: setBonusKeyByItemHash,
  );
}
