import 'pilot_text.dart';

const List<String> pilotNoteLabels = <String>[
  'Does',
  'Loop',
  'Uses',
  'Set',
  'Best for',
  'Source',
];

/// Text under a `Label:` header. Absent when the header is missing.
PilotText pilotNoteSection(String notes, String label) {
  final lines = notes.split(RegExp(r'\r?\n'));
  final header = '$label:';
  for (var i = 0; i < lines.length; i++) {
    if (!lines[i].startsWith(header)) continue;
    return PilotText(_sectionBody(lines, i, header));
  }
  return const PilotText.absent();
}

String _sectionBody(List<String> lines, int headerIndex, String header) {
  final body = <String>[];
  final rest = lines[headerIndex].substring(header.length).trim();
  if (rest.isNotEmpty) body.add(rest);
  for (var j = headerIndex + 1; j < lines.length; j++) {
    if (_startsWithLabel(lines[j])) break;
    body.add(lines[j]);
  }
  return body.join('\n').trim();
}

bool _startsWithLabel(String line) {
  for (final label in pilotNoteLabels) {
    if (line.startsWith('$label:')) return true;
  }
  return false;
}
