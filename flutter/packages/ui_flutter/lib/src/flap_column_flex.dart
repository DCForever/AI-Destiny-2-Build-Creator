import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';

/// Approximate flex factors from a [FlapColumnTemplate.columnsCss] track list.
///
/// Parses `fr` weights inside `minmax(..., Xfr)` (or bare `Xfr`). Falls back to
/// equal flex when parsing fails so hosts always get a stable length.
List<int> flapColumnFlexFactors(FlapColumnTemplate template) {
  final tracks = _splitTracks(template.columnsCss);
  final roles = template.cellRoles.length;
  if (tracks.isEmpty) {
    return List<int>.filled(roles > 0 ? roles : 1, 1);
  }

  final factors = <int>[];
  for (final track in tracks) {
    factors.add(_frWeight(track));
  }

  // Align length to cellRoles when CSS track count differs.
  while (factors.length < roles) {
    factors.add(1);
  }
  if (factors.length > roles && roles > 0) {
    return factors.sublist(0, roles);
  }
  return factors;
}

List<String> _splitTracks(String columnsCss) {
  final out = <String>[];
  final buf = StringBuffer();
  var depth = 0;
  for (var i = 0; i < columnsCss.length; i++) {
    final ch = columnsCss[i];
    if (ch == '(') {
      depth++;
      buf.write(ch);
    } else if (ch == ')') {
      depth--;
      buf.write(ch);
    } else if (ch == ' ' && depth == 0) {
      final t = buf.toString().trim();
      if (t.isNotEmpty) out.add(t);
      buf.clear();
    } else {
      buf.write(ch);
    }
  }
  final last = buf.toString().trim();
  if (last.isNotEmpty) out.add(last);
  return out;
}

int _frWeight(String track) {
  // Prefer the last `Nfr` or `N.Nfr` in the track (minmax max side).
  final re = RegExp(r'([0-9]+(?:\.[0-9]+)?)fr');
  final matches = re.allMatches(track).toList();
  if (matches.isEmpty) return 1;
  final raw = matches.last.group(1)!;
  final v = double.tryParse(raw) ?? 1;
  // Scale to integers suitable for Expanded.flex (×10 keeps 1.2fr distinct).
  final scaled = (v * 10).round();
  return scaled < 1 ? 1 : scaled;
}
