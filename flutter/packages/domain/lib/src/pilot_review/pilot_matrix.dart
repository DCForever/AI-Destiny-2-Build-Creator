import 'pilot_identity.dart';
import 'pilot_notes.dart';
import 'pilot_source_record.dart';
import 'pilot_text.dart';

/// Read pilot rows from a decoded matrix object. Other rows are dropped.
List<PilotSourceRecord> parsePilotMatrix(Object? decoded) {
  if (decoded is! Map) {
    throw const FormatException('Pilot matrix root must be a JSON object');
  }
  final root = Map<Object?, Object?>.from(decoded);
  final records = <PilotSourceRecord>[];
  _readExotics(records, root['exotics']);
  _readWeapons(records, root['weapons']);
  return records;
}

void _readExotics(List<PilotSourceRecord> records, Object? node) {
  if (node is! Map) return;
  for (final entry in node.entries) {
    final exotic = '${entry.key}';
    if (entry.value is! Map) continue;
    final body = Map<Object?, Object?>.from(entry.value as Map);
    for (final sub in body.entries) {
      final key = '${sub.key}';
      if (key == 'combos') {
        _readCombos(records, exotic, sub.value);
        continue;
      }
      if (!pilotIsSubclass(key) || sub.value is! Map) continue;
      final cell = Map<Object?, Object?>.from(sub.value as Map);
      _readBuildList(
        records,
        exotic: exotic,
        detail: 'matrix exotics/$exotic/$key',
        rowType: 'matrix-exotic',
        subclass: PilotText(key),
        weapon: const PilotText.absent(),
        builds: cell['builds'],
      );
    }
  }
}

void _readCombos(
  List<PilotSourceRecord> records,
  String exotic,
  Object? node,
) {
  if (node is! Map) return;
  final body = Map<Object?, Object?>.from(node);
  final table = body['combos'];
  if (table is! Map) return;
  for (final entry in table.entries) {
    final pair = '${entry.key}';
    if (entry.value is! Map) continue;
    final row = Map<Object?, Object?>.from(entry.value as Map);
    _readBuildList(
      records,
      exotic: exotic,
      detail: 'matrix exotics/$exotic/combos/$pair',
      rowType: 'matrix-combo',
      subclass: const PilotText.absent(),
      weapon: const PilotText.absent(),
      builds: row['builds'],
      comboKey: pair,
    );
  }
}

void _readWeapons(List<PilotSourceRecord> records, Object? node) {
  if (node is! Map) return;
  final weapons = Map<Object?, Object?>.from(node);
  final cells = weapons['cells'];
  if (cells is! Map) return;
  for (final weaponEntry in cells.entries) {
    final weapon = '${weaponEntry.key}';
    if (weaponEntry.value is! Map) continue;
    final subclasses = Map<Object?, Object?>.from(weaponEntry.value as Map);
    for (final sub in subclasses.entries) {
      final key = '${sub.key}';
      if (!pilotIsSubclass(key)) continue;
      _readBuildList(
        records,
        exotic: weapon,
        detail: 'matrix weapons/$weapon/$key',
        rowType: 'matrix-weapon',
        subclass: PilotText(key),
        weapon: PilotText(weapon),
        builds: sub.value,
      );
    }
  }
}

void _readBuildList(
  List<PilotSourceRecord> records, {
  required String exotic,
  required String detail,
  required String rowType,
  required PilotText subclass,
  required PilotText weapon,
  required Object? builds,
  String? comboKey,
}) {
  if (builds is! List) return;
  for (final item in builds) {
    if (item is! Map) continue;
    final record = _recordFromBuild(
      Map<Object?, Object?>.from(item),
      exotic: exotic,
      detail: detail,
      rowType: rowType,
      subclass: subclass,
      weapon: weapon,
      comboKey: comboKey,
    );
    if (record != null) records.add(record);
  }
}

PilotSourceRecord? _recordFromBuild(
  Map<Object?, Object?> build, {
  required String exotic,
  required String detail,
  required String rowType,
  required PilotText subclass,
  required PilotText weapon,
  required String? comboKey,
}) {
  final name = _requiredString(build, 'name');
  final creator = _requiredString(build, 'creator');
  final caseId = pilotCaseId(
    creator: creator,
    buildName: name,
    filingExotic: exotic,
  );
  if (caseId == null) return null;
  final notes = _optionalString(build, 'dim_notes');
  final perks = _perks(build, comboKey);
  final statedSubclass = _statedSubclass(build, subclass);
  return PilotSourceRecord(
    caseId: caseId,
    sourceKind: 'matrix',
    sourceDetail: detail,
    rowType: rowType,
    filingExotic: exotic,
    weaponExotic: weapon,
    subclassText: statedSubclass,
    buildName: name,
    creator: creator,
    season: _text(build, 'season'),
    date: _text(build, 'date'),
    originalDimLink: _requiredString(build, 'dim'),
    armorSetProposal: _optionalString(build, 'armor_set_proposal').value,
    personalDimLink: const PilotText.absent(),
    dimName: _text(build, 'dim_name'),
    doesText: _text(build, 'does'),
    loopText: _text(build, 'loop'),
    notesDoes: _notesPart(notes, 'Does'),
    notesLoop: _notesPart(notes, 'Loop'),
    notesSet: _notesPart(notes, 'Set'),
    classItemPerk1: perks.$1,
    classItemPerk2: perks.$2,
    ergoTrait: _text(build, 'ergo_trait'),
    ergoElement: _text(build, 'ergo_element'),
    ergoFrame: _text(build, 'ergo_perk2'),
  );
}

PilotText _statedSubclass(Map<Object?, Object?> build, PilotText cellSubclass) {
  if (!build.containsKey('subclass')) return cellSubclass;
  final value = build['subclass'];
  if (value is! String || !pilotIsSubclass(value)) {
    return const PilotText.absent();
  }
  return PilotText(value);
}

(PilotText, PilotText) _perks(Map<Object?, Object?> build, String? comboKey) {
  final first = _text(build, 'class_item_perk1');
  final second = _text(build, 'class_item_perk2');
  if (first.present || second.present) return (first, second);
  final listed = build['combo'];
  if (listed is List && listed.length == 2) {
    return (_listPerk(listed[0]), _listPerk(listed[1]));
  }
  if (comboKey == null) {
    return (const PilotText.absent(), const PilotText.absent());
  }
  final parts = comboKey.split(' + ');
  if (parts.length != 2) {
    return (const PilotText.absent(), const PilotText.absent());
  }
  return (PilotText(parts[0].trim()), PilotText(parts[1].trim()));
}

PilotText _listPerk(Object? value) {
  if (value is! String) return const PilotText.absent();
  return PilotText(value.trim());
}

PilotText _notesPart(PilotText notes, String label) {
  if (!notes.present) return const PilotText.absent();
  return pilotNoteSection(notes.value, label);
}

PilotText _text(Map<Object?, Object?> build, String key) {
  if (!build.containsKey(key) || build[key] == null) {
    return const PilotText.absent();
  }
  final value = build[key];
  if (value is! String) {
    throw FormatException('Matrix field $key must be a string');
  }
  return PilotText(value);
}

PilotText _optionalString(Map<Object?, Object?> build, String key) {
  return _text(build, key);
}

String _requiredString(Map<Object?, Object?> build, String key) {
  final text = _text(build, key);
  if (!text.present || text.value.trim().isEmpty) {
    throw FormatException('Matrix field $key is required');
  }
  return text.value;
}
