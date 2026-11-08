import 'pilot_identity.dart';
import 'pilot_notes.dart';
import 'pilot_source_record.dart';
import 'pilot_text.dart';

const List<String> pilotCsvColumns = <String>[
  'type',
  'exotic',
  'subclass_or_combo',
  'build_name',
  'creator',
  'season',
  'date',
  'original_dim_link',
  'armor_set_proposal',
  'personal_dim_link',
  'dim_name',
  'dim_notes',
];

/// Parse a pilot CSV. Rejects a header other than [pilotCsvColumns].
///
/// Rows whose creator, title, and exotic do not match [pilotIdentities]
/// are not returned.
List<PilotSourceRecord> parsePilotCsv(String csvText) {
  final rows = parseCsvTable(csvText);
  if (rows.isEmpty) {
    throw const FormatException('Pilot CSV is empty');
  }
  _requireHeader(rows.first);
  final records = <PilotSourceRecord>[];
  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    if (row.length != pilotCsvColumns.length) {
      throw FormatException(
        'Pilot CSV row ${i + 1} has ${row.length} fields, '
        'expected ${pilotCsvColumns.length}',
      );
    }
    final record = _recordFromRow(row);
    if (record != null) records.add(record);
  }
  return records;
}

void _requireHeader(List<String> header) {
  if (header.length != pilotCsvColumns.length) {
    throw FormatException(
      'Pilot CSV header has ${header.length} columns, '
      'expected ${pilotCsvColumns.length}',
    );
  }
  for (var i = 0; i < header.length; i++) {
    if (header[i] != pilotCsvColumns[i]) {
      throw FormatException(
        'Pilot CSV header column ${i + 1} is "${header[i]}", '
        'expected "${pilotCsvColumns[i]}"',
      );
    }
  }
}

PilotSourceRecord? _recordFromRow(List<String> row) {
  final values = <String, String>{
    for (var i = 0; i < pilotCsvColumns.length; i++) pilotCsvColumns[i]: row[i],
  };
  final exotic = values['exotic']!;
  final caseId = pilotCaseId(
    creator: values['creator']!,
    buildName: values['build_name']!,
    filingExotic: exotic,
  );
  if (caseId == null) return null;
  final notes = values['dim_notes']!;
  final combo = values['subclass_or_combo']!;
  final perks = _perkColumns(combo);
  return PilotSourceRecord(
    caseId: caseId,
    sourceKind: 'csv',
    sourceDetail: 'csv type=${values['type']}',
    rowType: values['type']!,
    filingExotic: exotic,
    weaponExotic: const PilotText.absent(),
    subclassText: _subclassColumn(combo),
    buildName: values['build_name']!,
    creator: values['creator']!,
    season: PilotText(values['season']!),
    date: PilotText(values['date']!),
    originalDimLink: values['original_dim_link']!,
    armorSetProposal: values['armor_set_proposal']!,
    personalDimLink: PilotText(values['personal_dim_link']!),
    dimName: PilotText(values['dim_name']!),
    doesText: pilotNoteSection(notes, 'Does'),
    loopText: pilotNoteSection(notes, 'Loop'),
    notesDoes: pilotNoteSection(notes, 'Does'),
    notesLoop: pilotNoteSection(notes, 'Loop'),
    notesSet: pilotNoteSection(notes, 'Set'),
    classItemPerk1: perks.$1,
    classItemPerk2: perks.$2,
    ergoTrait: const PilotText.absent(),
    ergoElement: const PilotText.absent(),
    ergoFrame: const PilotText.absent(),
  );
}

PilotText _subclassColumn(String combo) {
  if (pilotIsSubclass(combo)) return PilotText(combo);
  return const PilotText.absent();
}

(PilotText, PilotText) _perkColumns(String combo) {
  if (pilotIsSubclass(combo)) {
    return (const PilotText.absent(), const PilotText.absent());
  }
  final parts = combo.split(' + ');
  if (parts.length != 2 || parts.any((part) => part.trim().isEmpty)) {
    return (const PilotText.absent(), const PilotText.absent());
  }
  return (PilotText(parts[0].trim()), PilotText(parts[1].trim()));
}

/// RFC-style CSV: commas, quotes, and newlines inside quoted fields.
List<List<String>> parseCsvTable(String input) {
  final rows = <List<String>>[];
  final row = <String>[];
  final field = StringBuffer();
  var quoted = false;
  var index = 0;
  while (index < input.length) {
    final step = _readCsv(input, index, quoted, field, row, rows);
    quoted = step.quoted;
    index = step.index;
  }
  if (quoted) {
    throw const FormatException('CSV quote is not closed');
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(List<String>.from(row));
  }
  return rows;
}

({bool quoted, int index}) _readCsv(
  String input,
  int index,
  bool quoted,
  StringBuffer field,
  List<String> row,
  List<List<String>> rows,
) {
  final char = input[index];
  if (quoted) return _readQuoted(input, index, char, field);
  if (char == '"') return (quoted: true, index: index + 1);
  if (char == ',') {
    row.add(field.toString());
    field.clear();
    return (quoted: false, index: index + 1);
  }
  if (char == '\n' || char == '\r') {
    return _endRow(input, index, char, field, row, rows);
  }
  field.write(char);
  return (quoted: false, index: index + 1);
}

({bool quoted, int index}) _readQuoted(
  String input,
  int index,
  String char,
  StringBuffer field,
) {
  if (char == '"' && index + 1 < input.length && input[index + 1] == '"') {
    field.write('"');
    return (quoted: true, index: index + 2);
  }
  if (char == '"') return (quoted: false, index: index + 1);
  field.write(char);
  return (quoted: true, index: index + 1);
}

({bool quoted, int index}) _endRow(
  String input,
  int index,
  String char,
  StringBuffer field,
  List<String> row,
  List<List<String>> rows,
) {
  var next = index + 1;
  if (char == '\r' && next < input.length && input[next] == '\n') next++;
  row.add(field.toString());
  field.clear();
  if (row.length != 1 || row.single.isNotEmpty) {
    rows.add(List<String>.from(row));
  }
  row.clear();
  return (quoted: false, index: next);
}
