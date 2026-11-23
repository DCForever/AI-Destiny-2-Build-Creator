import '../evaluators/set_bonus_goals.dart';
import '../models/optimizer.dart';

/// One family + tier parsed from Mario's `armor_set_proposal` free text.
class ParsedArmorSetPiece {
  const ParsedArmorSetPiece({
    required this.familyName,
    required this.pieces,
  });

  /// Family label as written (before catalog key match).
  final String familyName;

  /// 2 or 4.
  final int pieces;
}

/// Result of parsing the primary phrase of an `armor_set_proposal` string.
class ArmorSetProposalParseResult {
  const ArmorSetProposalParseResult({
    this.pieces = const [],
    this.noStrongFit = false,
    this.unparseable = false,
  });

  /// Empty constructor for missing / blank input.
  const ArmorSetProposalParseResult.empty()
      : pieces = const [],
        noStrongFit = false,
        unparseable = false;

  final List<ParsedArmorSetPiece> pieces;
  final bool noStrongFit;
  final bool unparseable;

  bool get hasGoals => pieces.isNotEmpty;
}

/// Match a parsed family label to a catalog set-bonus display name.
///
/// Accepts exact case-insensitive equality, or a single trailing ` Set` on
/// either side. Returns null when zero or multiple catalog names match —
/// never guesses.
String? matchCatalogSetBonusKey(
  String parsedName, {
  required Iterable<String> catalogNames,
}) {
  final want = _normalizeSetFamily(parsedName);
  if (want.isEmpty) return null;

  final exact = <String>[];
  final soft = <String>[];
  for (final raw in catalogNames) {
    final name = raw.trim();
    if (name.isEmpty) continue;
    final norm = _normalizeSetFamily(name);
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

/// Resolve a Mario proposal string into legal hard [SetBonusCoverageGoal]s.
///
/// Unmatched family names are omitted (never guessed). When every piece fails
/// to match, returns empty goals. [unmatchedNames] lists parsed labels that
/// did not map to a catalog key.
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

  /// Human-readable note when the proposal did not fully resolve.
  String? get unresolvedNote {
    if (noStrongFit) return 'Armor set proposal: no strong fit';
    if (unparseable) {
      return 'Armor set proposal could not be parsed into 4pc or 2+2';
    }
    if (unmatchedNames.isNotEmpty) {
      return 'Armor set proposal unmatched in catalog: '
          '${unmatchedNames.join(', ')}';
    }
    return null;
  }
}

/// Parse + catalog-map Mario's proposal into hard Optimize goals.
ResolvedArmorSetProposal resolveArmorSetProposal({
  required String? raw,
  required Iterable<String> catalogNames,
}) {
  final parsed = parseArmorSetProposal(raw);
  if (parsed.noStrongFit) {
    return const ResolvedArmorSetProposal(noStrongFit: true);
  }
  if (parsed.unparseable) {
    return const ResolvedArmorSetProposal(unparseable: true);
  }
  if (!parsed.hasGoals) {
    return const ResolvedArmorSetProposal();
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
    // Partial match left an illegal combo (e.g. only one of 2+2 matched is
    // still legal as 1×2pc; two 4pcs cannot happen from the parser).
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

/// Parse Mario's free-text `armor_set_proposal` into primary 4pc / 2+2 pieces.
///
/// Ignores an `(alt: …)` suffix. `no strong fit`, blank, and unparseable
/// inputs yield no pieces (never throws).
ArmorSetProposalParseResult parseArmorSetProposal(String? raw) {
  if (raw == null) return const ArmorSetProposalParseResult.empty();
  var text = raw.trim();
  if (text.isEmpty) return const ArmorSetProposalParseResult.empty();

  text = _stripAltSuffix(text).trim();
  if (text.isEmpty) return const ArmorSetProposalParseResult.empty();

  if (_isNoStrongFit(text)) {
    return const ArmorSetProposalParseResult(noStrongFit: true);
  }

  final parts = text.split('+').map((p) => p.trim()).where((p) => p.isNotEmpty);
  final pieces = <ParsedArmorSetPiece>[];
  for (final part in parts) {
    final match = _piecePattern.firstMatch(part);
    if (match == null) {
      return const ArmorSetProposalParseResult(unparseable: true);
    }
    final count = int.tryParse(match.group(1)!);
    final name = match.group(2)!.trim();
    if (count == null || (count != 2 && count != 4) || name.isEmpty) {
      return const ArmorSetProposalParseResult(unparseable: true);
    }
    pieces.add(ParsedArmorSetPiece(familyName: name, pieces: count));
  }

  if (pieces.isEmpty) {
    return const ArmorSetProposalParseResult(unparseable: true);
  }
  if (pieces.length > 2) {
    return const ArmorSetProposalParseResult(unparseable: true);
  }
  if (pieces.length == 1) {
    return ArmorSetProposalParseResult(pieces: pieces);
  }
  // Exactly two: both must be 2pc on different families.
  if (pieces[0].pieces != 2 || pieces[1].pieces != 2) {
    return const ArmorSetProposalParseResult(unparseable: true);
  }
  if (_normalizeSetFamily(pieces[0].familyName) ==
      _normalizeSetFamily(pieces[1].familyName)) {
    return const ArmorSetProposalParseResult(unparseable: true);
  }
  return ArmorSetProposalParseResult(
    pieces: List<ParsedArmorSetPiece>.unmodifiable(pieces),
  );
}

final RegExp _piecePattern = RegExp(
  r'^(\d+)\s*pc\s+(.+)$',
  caseSensitive: false,
);

String _stripAltSuffix(String text) {
  final lower = text.toLowerCase();
  final idx = lower.indexOf('(alt:');
  if (idx < 0) return text;
  return text.substring(0, idx).trimRight();
}

bool _isNoStrongFit(String text) {
  final n = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  return n == 'no strong fit';
}

String _normalizeSetFamily(String name) {
  var n = name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  if (n.endsWith(' set')) {
    n = n.substring(0, n.length - 4).trimRight();
  }
  return n;
}
