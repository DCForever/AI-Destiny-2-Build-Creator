import 'dart:convert';

import '../models/equipment.dart';
import '../pilot_review/pilot_csv.dart' show parseCsvTable;
import 'fill_in_inventory.dart';

/// Max DIM Armor CSV payload accepted by [parseDimArmorCsv].
///
/// Untrusted import surface — larger inputs fail closed.
const int kDimArmorCsvMaxBytes = 8 * 1024 * 1024;

/// Required DIM Armor spreadsheet columns (English headers).
///
/// Source: DestinyItemManager/DIM `src/app/organizer/Columns.tsx`
/// (`csv: 'Name'|'Hash'|'Id'|'Equippable'|'Type'|'Rarity'`) driven by
/// `src/app/inventory/spreadsheets.ts` `generateCSVExportData('armor', …)`.
const List<String> kDimArmorCsvRequiredColumns = <String>[
  'Name',
  'Hash',
  'Id',
  'Equippable',
  'Type',
  'Rarity',
];

/// Result of parsing a DIM Armor CSV export (fail closed; no partial guesses).
class DimArmorCsvParseResult {
  DimArmorCsvParseResult._({this.items, this.error});

  factory DimArmorCsvParseResult.ok(List<FillInInventoryItem> items) {
    return DimArmorCsvParseResult._(
      items: List<FillInInventoryItem>.unmodifiable(items),
    );
  }

  factory DimArmorCsvParseResult.couldNotRead(String detail) {
    return DimArmorCsvParseResult._(error: "Couldn't read file: $detail");
  }

  final List<FillInInventoryItem>? items;
  final String? error;

  bool get isOk => items != null && error == null;
}

/// Parse DIM Armor CSV [text] into [FillInInventoryItem] rows.
///
/// Pure: no filesystem or network access, no path following. Cell values that
/// look like paths or URLs are ignored as data only — never opened.
///
/// [armorSetHashByItemHash] supplies legendary set hashes. DIM's armor CSV
/// has no set-hash column; hosts with manifest data pass this map. Without it,
/// legendary rows keep `armorSetHash == null`.
DimArmorCsvParseResult parseDimArmorCsv(
  String text, {
  Map<int, int> armorSetHashByItemHash = const <int, int>{},
  int maxBytes = kDimArmorCsvMaxBytes,
}) {
  if (maxBytes < 1) {
    return DimArmorCsvParseResult.couldNotRead('invalid size cap');
  }
  final byteLength = utf8.encode(text).length;
  if (byteLength > maxBytes) {
    return DimArmorCsvParseResult.couldNotRead(
      'file exceeds size limit ($byteLength > $maxBytes bytes)',
    );
  }

  final normalized = text.startsWith('\uFEFF') ? text.substring(1) : text;
  if (normalized.trim().isEmpty) {
    return DimArmorCsvParseResult.couldNotRead('file is empty');
  }

  final List<List<String>> rows;
  try {
    rows = parseCsvTable(normalized);
  } on FormatException catch (e) {
    return DimArmorCsvParseResult.couldNotRead(e.message);
  }

  if (rows.isEmpty) {
    return DimArmorCsvParseResult.couldNotRead('file is empty');
  }

  final header = rows.first;
  final indexByName = <String, int>{};
  for (var i = 0; i < header.length; i++) {
    final name = header[i].trim();
    if (name.isEmpty) continue;
    if (indexByName.containsKey(name)) {
      return DimArmorCsvParseResult.couldNotRead(
        'duplicate column "$name"',
      );
    }
    indexByName[name] = i;
  }

  for (final required in kDimArmorCsvRequiredColumns) {
    if (!indexByName.containsKey(required)) {
      return DimArmorCsvParseResult.couldNotRead(
        'missing required column "$required"',
      );
    }
  }

  final seenIds = <String>{};
  final items = <FillInInventoryItem>[];
  for (var r = 1; r < rows.length; r++) {
    final row = rows[r];
    if (_rowIsBlank(row)) continue;
    final item = _itemFromRow(
      row: row,
      indexByName: indexByName,
      armorSetHashByItemHash: armorSetHashByItemHash,
    );
    if (item == null) continue;
    if (!seenIds.add(item.instanceId)) continue;
    items.add(item);
  }

  return DimArmorCsvParseResult.ok(items);
}

/// Decode UTF-8 [bytes] then parse. Fails closed on invalid UTF-8 or oversize.
DimArmorCsvParseResult parseDimArmorCsvBytes(
  List<int> bytes, {
  Map<int, int> armorSetHashByItemHash = const <int, int>{},
  int maxBytes = kDimArmorCsvMaxBytes,
}) {
  if (bytes.length > maxBytes) {
    return DimArmorCsvParseResult.couldNotRead(
      'file exceeds size limit (${bytes.length} > $maxBytes bytes)',
    );
  }
  final String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException catch (e) {
    return DimArmorCsvParseResult.couldNotRead(e.message);
  }
  return parseDimArmorCsv(
    text,
    armorSetHashByItemHash: armorSetHashByItemHash,
    maxBytes: maxBytes,
  );
}

FillInInventoryItem? _itemFromRow({
  required List<String> row,
  required Map<String, int> indexByName,
  required Map<int, int> armorSetHashByItemHash,
}) {
  final idRaw = _cell(row, indexByName, 'Id');
  final hashRaw = _cell(row, indexByName, 'Hash');
  final equippable = _cell(row, indexByName, 'Equippable');
  final typeName = _cell(row, indexByName, 'Type');
  final rarity = _cell(row, indexByName, 'Rarity');
  if (idRaw == null ||
      hashRaw == null ||
      equippable == null ||
      typeName == null ||
      rarity == null) {
    return null;
  }

  final instanceId = _normalizeInstanceId(idRaw);
  if (instanceId.isEmpty) return null;

  final itemHash = int.tryParse(hashRaw.trim());
  if (itemHash == null || itemHash <= 0) return null;

  final guardianClass = _parseClass(equippable);
  if (guardianClass == null) return null;

  final slot = _parseSlot(typeName);
  if (slot == null) return null;

  final isExotic = rarity.trim().toLowerCase() == 'exotic';
  final setHash = isExotic ? null : armorSetHashByItemHash[itemHash];

  return FillInInventoryItem(
    instanceId: instanceId,
    itemHash: itemHash,
    guardianClass: guardianClass,
    slot: slot,
    isExotic: isExotic,
    armorSetHash: setHash,
  );
}

String? _cell(List<String> row, Map<String, int> indexByName, String name) {
  final index = indexByName[name];
  if (index == null || index >= row.length) return null;
  return row[index];
}

bool _rowIsBlank(List<String> row) {
  for (final cell in row) {
    if (cell.trim().isNotEmpty) return false;
  }
  return true;
}

String _normalizeInstanceId(String raw) {
  // DIM wraps Id in quotes in CSV; import strips every `"` (spreadsheets.ts).
  return raw.replaceAll('"', '').trim();
}

GuardianClass? _parseClass(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final lower = trimmed.toLowerCase();
  if (lower == 'any' || lower == 'unknown' || lower == 'classified') {
    return null;
  }
  return GuardianClass.tryParse(trimmed);
}

EquipmentSlot? _parseSlot(String typeName) {
  switch (typeName.trim().toLowerCase()) {
    case 'helmet':
      return EquipmentSlot.helmet;
    case 'gauntlets':
      return EquipmentSlot.arms;
    case 'chest armor':
      return EquipmentSlot.chest;
    case 'leg armor':
      return EquipmentSlot.legs;
    case 'warlock bond':
    case 'titan mark':
    case 'hunter cloak':
      return EquipmentSlot.classItem;
    default:
      return null;
  }
}
