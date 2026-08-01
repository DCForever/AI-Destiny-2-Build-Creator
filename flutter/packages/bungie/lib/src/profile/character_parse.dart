import 'profile_types.dart';

/// Parse GetProfile Response characters (component 200) into summaries.
///
/// Sorted by [CharacterSummary.dateLastPlayed] descending (most recent first).
List<CharacterSummary> parseCharactersResponse(Object? response) {
  final data = extractCharactersData(response);
  if (data.isEmpty) return const [];
  final list = <CharacterSummary>[];
  for (final raw in data.values) {
    list.add(parseCharacterSummary(raw));
  }
  list.sort(_byDateLastPlayedDesc);
  return list;
}

/// Extract `characters.data` map from a GetProfile Response body.
Map<String, Object?> extractCharactersData(Object? response) {
  if (response is! Map) return const {};
  final res = _asStringKeyedMap(response);
  final characters = res['characters'];
  if (characters is! Map) return const {};
  final data = _asStringKeyedMap(characters)['data'];
  if (data is! Map) return const {};
  final out = <String, Object?>{};
  for (final e in data.entries) {
    out[e.key.toString()] = e.value;
  }
  return out;
}

/// Parse one character entry from profile characters.data.
CharacterSummary parseCharacterSummary(Object? raw) {
  if (raw is! Map) {
    throw const FormatException('Invalid character entry');
  }
  final c = _asStringKeyedMap(raw);
  final classNum = c['classType'];
  final classType = classNum is num
      ? (kDestinyClassTypeNames[classNum.toInt()] ?? 'Titan')
      : 'Titan';
  final lightRaw = c['light'];
  final light = lightRaw is num ? lightRaw.toInt() : 0;
  final emblem = c['emblemPath'];
  return CharacterSummary(
    characterId: '${c['characterId'] ?? ''}',
    classType: classType,
    light: light,
    emblemPath: emblem is String ? emblem : null,
    dateLastPlayed: '${c['dateLastPlayed'] ?? ''}',
  );
}

int _byDateLastPlayedDesc(CharacterSummary a, CharacterSummary b) {
  return b.dateLastPlayed.compareTo(a.dateLastPlayed);
}

Map<String, Object?> _asStringKeyedMap(Map raw) {
  final out = <String, Object?>{};
  for (final e in raw.entries) {
    out[e.key.toString()] = e.value;
  }
  return out;
}
