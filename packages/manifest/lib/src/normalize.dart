/// Canonical name normalization for extractors (`searchName`) and resolvers.
///
/// Port of TypeScript `src/lib/manifest/normalize.ts`. Must stay in sync with
/// product so entity caches and resolve paths match.
String normalizeName(String name) {
  var s = _stripDiacritics(name).toLowerCase();
  s = s.replaceAll(RegExp(r"['’\u2018\u2019]"), '');
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  return s.trim();
}

String _stripDiacritics(String input) {
  const pairs = <String, String>{
    'à': 'a',
    'á': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'å': 'a',
    'è': 'e',
    'é': 'e',
    'ê': 'e',
    'ë': 'e',
    'ì': 'i',
    'í': 'i',
    'î': 'i',
    'ï': 'i',
    'ò': 'o',
    'ó': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ù': 'u',
    'ú': 'u',
    'û': 'u',
    'ü': 'u',
    'ý': 'y',
    'ÿ': 'y',
    'ñ': 'n',
    'ç': 'c',
    'À': 'A',
    'Á': 'A',
    'Â': 'A',
    'Ã': 'A',
    'Ä': 'A',
    'Å': 'A',
    'È': 'E',
    'É': 'E',
    'Ê': 'E',
    'Ë': 'E',
    'Ì': 'I',
    'Í': 'I',
    'Î': 'I',
    'Ï': 'I',
    'Ò': 'O',
    'Ó': 'O',
    'Ô': 'O',
    'Õ': 'O',
    'Ö': 'O',
    'Ù': 'U',
    'Ú': 'U',
    'Û': 'U',
    'Ü': 'U',
    'Ý': 'Y',
    'Ñ': 'N',
    'Ç': 'C',
  };
  final buf = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    if (rune >= 0x0300 && rune <= 0x036f) continue;
    buf.write(pairs[ch] ?? ch);
  }
  return buf.toString();
}
