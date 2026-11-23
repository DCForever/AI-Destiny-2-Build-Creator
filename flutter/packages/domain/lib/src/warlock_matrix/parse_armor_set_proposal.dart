import '../evaluators/set_bonus_goals.dart';
import '../models/optimizer.dart';

/// One family + tier from Mario's `armor_set_proposal` free text.
class ParsedArmorSetPiece {
  const ParsedArmorSetPiece({required this.familyName, required this.pieces});
  final String familyName;
  final int pieces;
}

/// Parse of the primary phrase (alt suffix ignored).
class ArmorSetProposalParseResult {
  const ArmorSetProposalParseResult({
    this.pieces = const [],
    this.noStrongFit = false,
    this.unparseable = false,
  });
  final List<ParsedArmorSetPiece> pieces;
  final bool noStrongFit;
  final bool unparseable;
  bool get hasGoals => pieces.isNotEmpty;
}

/// Exact (case-insensitive) or trailing ` Set` catalog match; never guesses.
String? matchCatalogSetBonusKey(
  String parsedName, {
  required Iterable<String> catalogNames,
}) {
  final want = _normFamily(parsedName);
  if (want.isEmpty) return null;
  final exact = <String>[];
  final soft = <String>[];
  for (final raw in catalogNames) {
    final name = raw.trim();
    if (name.isEmpty) continue;
    final norm = _normFamily(name);
    if (norm.isEmpty) continue;
    if (name.toLowerCase() == parsedName.trim().toLowerCase()) {
      exact.add(name);
    } else if (norm == want) {
      soft.add(name);
    }
  }
  if (exact.length == 1) return exact.single;
  if (exact.isEmpty && soft.length == 1) return soft.single;
  return null;
}

/// Goals + unmatched labels after catalog map.
class ResolvedArmorSetProposal {
  const ResolvedArmorSetProposal({
    this.goals = const [],
    this.unmatchedNames = const [],
    this.noStrongFit = false,
    this.unparseable = false,
  });
  final List<SetBonusCoverageGoal> goals;
  final List<String> unmatchedNames;
  final bool noStrongFit;
  final bool unparseable;

  String? get unresolvedNote {
    if (noStrongFit) return 'Armor set proposal: no strong fit';
    if (unparseable) {
      return 'Armor set proposal could not be parsed into 4pc or 2+2';
    }
    if (unmatchedNames.isEmpty) return null;
    return 'Armor set proposal unmatched in catalog: '
        '${unmatchedNames.join(', ')}';
  }
}

/// Parse + catalog-map into legal hard goals (unmatched pieces omitted).
ResolvedArmorSetProposal resolveArmorSetProposal({
  required String? raw,
  required Iterable<String> catalogNames,
}) {
  final parsed = parseArmorSetProposal(raw);
  if (parsed.noStrongFit) {
    return const ResolvedArmorSetProposal(noStrongFit: true);
  }
  if (parsed.unparseable || !parsed.hasGoals) {
    return ResolvedArmorSetProposal(unparseable: parsed.unparseable);
  }
  final goals = <SetBonusCoverageGoal>[];
  final unmatched = <String>[];
  for (final p in parsed.pieces) {
    final key = matchCatalogSetBonusKey(
      p.familyName,
      catalogNames: catalogNames,
    );
    if (key == null) {
      unmatched.add(p.familyName);
      continue;
    }
    goals.add(SetBonusCoverageGoal(setBonusKey: key, minPieces: p.pieces));
  }
  if (goals.isEmpty) {
    return ResolvedArmorSetProposal(unmatchedNames: unmatched);
  }
  if (!isLegalSetBonusGoalCombo(goals)) {
    return ResolvedArmorSetProposal(
      unmatchedNames: unmatched,
      unparseable: true,
    );
  }
  return ResolvedArmorSetProposal(
    goals: List<SetBonusCoverageGoal>.unmodifiable(goals),
    unmatchedNames: List<String>.unmodifiable(unmatched),
  );
}

/// Primary phrase only → 4pc or 2+2. Blank / no strong fit / junk → no pieces.
ArmorSetProposalParseResult parseArmorSetProposal(String? raw) {
  if (raw == null) return const ArmorSetProposalParseResult();
  var text = _stripAlt(raw.trim()).trim();
  if (text.isEmpty) return const ArmorSetProposalParseResult();
  if (_loose(text) == 'no strong fit') {
    return const ArmorSetProposalParseResult(noStrongFit: true);
  }
  final pieces = <ParsedArmorSetPiece>[];
  for (final part in text.split('+')) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) continue;
    final m = _pieceRe.firstMatch(trimmed);
    if (m == null) return const ArmorSetProposalParseResult(unparseable: true);
    final count = int.tryParse(m.group(1)!);
    final name = m.group(2)!.trim();
    if (count == null || (count != 2 && count != 4) || name.isEmpty) {
      return const ArmorSetProposalParseResult(unparseable: true);
    }
    pieces.add(ParsedArmorSetPiece(familyName: name, pieces: count));
  }
  if (pieces.isEmpty || pieces.length > 2) {
    return const ArmorSetProposalParseResult(unparseable: true);
  }
  if (pieces.length == 2) {
    if (pieces[0].pieces != 2 || pieces[1].pieces != 2) {
      return const ArmorSetProposalParseResult(unparseable: true);
    }
    if (_normFamily(pieces[0].familyName) == _normFamily(pieces[1].familyName)) {
      return const ArmorSetProposalParseResult(unparseable: true);
    }
  }
  return ArmorSetProposalParseResult(
    pieces: List<ParsedArmorSetPiece>.unmodifiable(pieces),
  );
}

final RegExp _pieceRe = RegExp(r'^(\d+)\s*pc\s+(.+)$', caseSensitive: false);

String _stripAlt(String text) {
  final i = text.toLowerCase().indexOf('(alt:');
  return i < 0 ? text : text.substring(0, i).trimRight();
}

String _loose(String text) =>
    text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

String _normFamily(String name) {
  var n = _loose(name);
  if (n.endsWith(' set')) n = n.substring(0, n.length - 4).trimRight();
  return n;
}
