import 'dart:convert';

import '../models/equipment.dart';
import '../pilot_review/pilot_csv.dart' show parseCsvTable;
import 'fill_in_inventory.dart';

/// Max DIM Weapons CSV payload accepted by [parseDimWeaponsCsv].
///
/// Untrusted import surface — larger inputs fail closed.
const int kDimWeaponsCsvMaxBytes = 8 * 1024 * 1024;

/// Required DIM Weapons spreadsheet columns (English headers).
///
/// Source: DestinyItemManager/DIM `src/app/organizer/Columns.tsx`
/// (`csv: 'Name'|'Hash'|'Id'|'Type'|'Rarity'|'Category'`) driven by
/// `src/app/inventory/spreadsheets.ts` `generateCSVExportData('weapon', …)`.
///
/// Measured from Daniel's export, Nov 12, 2026: 72-column Weapons CSV has
/// **no** `Equippable` column (weapons are class-agnostic). Slot comes from
/// `Category` (KineticSlot / Energy / Power). Unused columns are ignored when
/// row width matches the header.
const List<String> kDimWeaponsCsvRequiredColumns = <String>[
  'Name',
  'Hash',
  'Id',
  'Type',
  'Rarity',
  'Category',
];

/// Result of parsing a DIM Weapons CSV export (fail closed; no partial guesses).
class DimWeaponsCsvParseResult {
  DimWeaponsCsvParseResult._({this.items, this.error});

  factory DimWeaponsCsvParseResult.ok(List<FillInInventoryItem> items) {
    return DimWeaponsCsvParseResult._(
      items: List<FillInInventoryItem>.unmodifiable(items),
    );
  }

  factory DimWeaponsCsvParseResult.couldNotRead(String detail) {
    return DimWeaponsCsvParseResult._(error: "Couldn't read file: $detail");
  }

  final List<FillInInventoryItem>? items;
  final String? error;

  bool get isOk => items != null && error == null;
}

/// Parse DIM Weapons CSV [text] into [FillInInventoryItem] rows.
///
/// Pure: no filesystem or network access, no path following. Cell values that
/// look like paths or URLs are ignored as data only — never opened.
///
/// Fail closed: any data row shorter/longer than the header, missing a needed
/// field, with an empty `Id`, or with an unparseable `Hash`, rejects the
/// **whole** import (no partial held inventory). Rows whose Category cannot be
/// mapped to a weapon slot are skipped (not held). Weapons have no class —
/// [FillInInventoryItem.guardianClass] is null.
DimWeaponsCsvParseResult parseDimWeaponsCsv(
  String text, {
  int maxBytes = kDimWeaponsCsvMaxBytes,
}) {
  if (maxBytes < 1) {
    return DimWeaponsCsvParseResult.couldNotRead('invalid size cap');
  }
  final byteLength = utf8.encode(text).length;
  if (byteLength > maxBytes) {
    return DimWeaponsCsvParseResult.couldNotRead(
      'file exceeds size limit ($byteLength > $maxBytes bytes)',
    );
  }

  final normalized = text.startsWith('\uFEFF') ? text.substring(1) : text;
  if (normalized.trim().isEmpty) {
    return DimWeaponsCsvParseResult.couldNotRead('file is empty');
  }

  final List<List<String>> rows;
  try {
    rows = parseCsvTable(normalized);
  } on FormatException catch (e) {
    return DimWeaponsCsvParseResult.couldNotRead(e.message);
  }

  if (rows.isEmpty) {
    return DimWeaponsCsvParseResult.couldNotRead('file is empty');
  }

  final header = rows.first;
  final indexByName = <String, int>{};
  for (var i = 0; i < header.length; i++) {
    final name = header[i].trim();
    if (name.isEmpty) continue;
    if (indexByName.containsKey(name)) {
      return DimWeaponsCsvParseResult.couldNotRead(
        'duplicate column "$name"',
      );
    }
    indexByName[name] = i;
  }

  for (final required in kDimWeaponsCsvRequiredColumns) {
    if (!indexByName.containsKey(required)) {
      return DimWeaponsCsvParseResult.couldNotRead(
        'missing required column "$required"',
      );
    }
  }

  final headerWidth = header.length;
  final seenIds = <String>{};
  final items = <FillInInventoryItem>[];
  for (var r = 1; r < rows.length; r++) {
    final row = rows[r];
    if (_rowIsBlank(row)) continue;
    if (row.length != headerWidth) {
      return DimWeaponsCsvParseResult.couldNotRead(
        'row ${r + 1} width ${row.length} does not match header width '
        '$headerWidth',
      );
    }
    final parsed = _itemFromRow(
      row: row,
      rowNumber: r + 1,
      indexByName: indexByName,
    );
    if (parsed.error != null) {
      return DimWeaponsCsvParseResult.couldNotRead(parsed.error!);
    }
    final item = parsed.item;
    if (item == null) continue;
    if (!seenIds.add(item.instanceId)) continue;
    items.add(item);
  }

  return DimWeaponsCsvParseResult.ok(items);
}

/// Decode UTF-8 [bytes] then parse. Fails closed on invalid UTF-8 or oversize.
DimWeaponsCsvParseResult parseDimWeaponsCsvBytes(
  List<int> bytes, {
  int maxBytes = kDimWeaponsCsvMaxBytes,
}) {
  if (bytes.length > maxBytes) {
    return DimWeaponsCsvParseResult.couldNotRead(
      'file exceeds size limit (${bytes.length} > $maxBytes bytes)',
    );
  }
  final String text;
  try {
    text = utf8.decode(bytes);
  } on FormatException catch (e) {
    return DimWeaponsCsvParseResult.couldNotRead(e.message);
  }
  return parseDimWeaponsCsv(text, maxBytes: maxBytes);
}

class _RowParse {
  const _RowParse({this.item, this.error});

  final FillInInventoryItem? item;
  final String? error;
}

_RowParse _itemFromRow({
  required List<String> row,
  required int rowNumber,
  required Map<String, int> indexByName,
}) {
  final idRaw = _cell(row, indexByName, 'Id');
  final hashRaw = _cell(row, indexByName, 'Hash');
  final nameRaw = _cell(row, indexByName, 'Name');
  final typeName = _cell(row, indexByName, 'Type');
  final rarity = _cell(row, indexByName, 'Rarity');
  final category = _cell(row, indexByName, 'Category');
  // Width already checked; missing map index would be a programmer error.
  if (idRaw == null ||
      hashRaw == null ||
      nameRaw == null ||
      typeName == null ||
      rarity == null ||
      category == null) {
    return _RowParse(error: 'row $rowNumber is missing a needed field');
  }

  final instanceId = _normalizeInstanceId(idRaw);
  if (instanceId.isEmpty) {
    return _RowParse(error: 'row $rowNumber has an empty Id');
  }

  final itemHash = int.tryParse(hashRaw.trim());
  if (itemHash == null || itemHash <= 0) {
    return _RowParse(error: 'row $rowNumber has an unparseable Hash');
  }

  // Type must be present (non-blank); Category maps the equipment slot.
  if (typeName.trim().isEmpty) {
    return _RowParse(error: 'row $rowNumber is missing a needed field');
  }

  final slot = _parseWeaponSlot(category);
  if (slot == null) return const _RowParse();

  final isExotic = rarity.trim().toLowerCase() == 'exotic';
  final displayName = nameRaw.trim();

  return _RowParse(
    item: FillInInventoryItem(
      instanceId: instanceId,
      itemHash: itemHash,
      name: displayName.isEmpty ? null : displayName,
      guardianClass: null,
      slot: slot,
      isExotic: isExotic,
    ),
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

/// Map DIM Weapons `Category` CSV values to combat weapon slots.
///
/// Source: Columns.tsx Category column for D2 —
/// KineticSlot / Energy / Power (D1: Primary / Special / Heavy).
EquipmentSlot? _parseWeaponSlot(String category) {
  switch (category.trim().toLowerCase()) {
    case 'kineticslot':
    case 'primary':
      return EquipmentSlot.primary;
    case 'energy':
    case 'special':
      return EquipmentSlot.special;
    case 'power':
    case 'heavy':
      return EquipmentSlot.heavy;
    default:
      return null;
  }
}
