import '../models/dim_loadout.dart' show DimStatHashes;
import '../models/soft_stats.dart' show ArmorStatName;
import 'cached_dim_loadout.dart';

/// How a [DisplayOnlyStatRanking] was produced.
///
/// - [fromLink]: DIM `statConstraints` order (keywords ignored).
/// - [inferred]: keyword scores from notes / exotic / mods (display only).
/// - [unknown]: no constraints and no keyword matches — never a default guess.
enum DimStatRankingSource { fromLink, inferred, unknown }

/// One ranked armor-stat row for UI.
///
/// **Display only.** Must not feed Optimize, build saves, Fill In matching,
/// SoftStatTargets, or any write path. See [DisplayOnlyStatRanking].
class RankedDimStat {
  const RankedDimStat({
    required this.stat,
    required this.score,
    required this.rank,
    required this.source,
    required this.matchedWords,
  });

  final ArmorStatName stat;

  /// Link rows use descending priority weight; inferred rows use keyword score.
  final int score;

  /// 1-based rank within [DisplayOnlyStatRanking.entries].
  final int rank;

  final DimStatRankingSource source;

  /// Keywords that contributed (empty for [DimStatRankingSource.fromLink]).
  final List<String> matchedWords;

  String get label => switch (source) {
        DimStatRankingSource.fromLink => 'from link',
        DimStatRankingSource.inferred => 'inferred',
        DimStatRankingSource.unknown => 'unknown',
      };
}

/// Display-only armor-stat ranking for a cached DIM loadout.
///
/// There is intentionally **no** API that converts this into
/// [SoftStatTargets], optimizer `priorities`, Fill In requirements, or
/// persisted build fields. Hosts must render it and stop.
class DisplayOnlyStatRanking {
  const DisplayOnlyStatRanking({
    required this.source,
    required this.entries,
  });

  final DimStatRankingSource source;

  /// Empty when [source] is [DimStatRankingSource.unknown].
  final List<RankedDimStat> entries;
}

/// Source weights (notes > exotic description > mod names).
///
/// Documented choice: notes=3, exotic description=2, each mod name=1.
/// Scores sum across matches so repeated cues stack deterministically.
const int kDimStatRankWeightNotes = 3;
const int kDimStatRankWeightExotic = 2;
const int kDimStatRankWeightModName = 1;

/// Deterministic keyword → [ArmorStatName] table (lowercase tokens).
///
/// Word-boundary match against untrusted notes/descriptions/mod names.
const Map<String, ArmorStatName> kDimStatKeywordTable =
    <String, ArmorStatName>{
  'health': ArmorStatName.health,
  'melee': ArmorStatName.melee,
  'grenade': ArmorStatName.grenade,
  'grenades': ArmorStatName.grenade,
  'super': ArmorStatName.superStat,
  'class': ArmorStatName.classStat,
  'weapon': ArmorStatName.weapons,
  'weapons': ArmorStatName.weapons,
};

/// Rank armor stats for [loadout].
///
/// When [CachedDimLoadout.statConstraints] is non-null and non-empty, uses that
/// order labeled [DimStatRankingSource.fromLink] and ignores keywords.
/// Otherwise scores keywords; no match → [DimStatRankingSource.unknown].
DisplayOnlyStatRanking rankDimLoadoutStats(CachedDimLoadout loadout) {
  final constraints = loadout.statConstraints;
  if (constraints != null && constraints.isNotEmpty) {
    return _fromLink(constraints);
  }
  return _infer(loadout);
}

DisplayOnlyStatRanking _fromLink(List<CachedDimStatConstraint> constraints) {
  final entries = <RankedDimStat>[];
  var rank = 1;
  final remaining = constraints.length;
  for (final row in constraints) {
    final stat = _statFromConstraint(row);
    if (stat == null) continue;
    entries.add(
      RankedDimStat(
        stat: stat,
        score: remaining - rank + 1,
        rank: rank,
        source: DimStatRankingSource.fromLink,
        matchedWords: const [],
      ),
    );
    rank++;
  }
  if (entries.isEmpty) {
    return const DisplayOnlyStatRanking(
      source: DimStatRankingSource.unknown,
      entries: [],
    );
  }
  return DisplayOnlyStatRanking(
    source: DimStatRankingSource.fromLink,
    entries: List<RankedDimStat>.unmodifiable(entries),
  );
}

DisplayOnlyStatRanking _infer(CachedDimLoadout loadout) {
  final scores = <ArmorStatName, int>{
    for (final s in ArmorStatName.all) s: 0,
  };
  final matched = <ArmorStatName, Set<String>>{
    for (final s in ArmorStatName.all) s: <String>{},
  };

  void absorb(String? text, int weight) {
    if (text == null || text.trim().isEmpty) return;
    for (final hit in _scanKeywords(text)) {
      scores[hit.stat] = scores[hit.stat]! + weight;
      matched[hit.stat]!.add(hit.word);
    }
  }

  absorb(loadout.notes, kDimStatRankWeightNotes);
  absorb(loadout.exotic?.description, kDimStatRankWeightExotic);
  for (final mod in loadout.mods) {
    absorb(mod.name, kDimStatRankWeightModName);
  }

  final scored = <ArmorStatName>[
    for (final s in ArmorStatName.all)
      if (scores[s]! > 0) s,
  ];
  if (scored.isEmpty) {
    return const DisplayOnlyStatRanking(
      source: DimStatRankingSource.unknown,
      entries: [],
    );
  }

  scored.sort((a, b) {
    final byScore = scores[b]!.compareTo(scores[a]!);
    if (byScore != 0) return byScore;
    return a.wireName.compareTo(b.wireName);
  });

  final entries = <RankedDimStat>[
    for (var i = 0; i < scored.length; i++)
      RankedDimStat(
        stat: scored[i],
        score: scores[scored[i]]!,
        rank: i + 1,
        source: DimStatRankingSource.inferred,
        matchedWords: List<String>.unmodifiable(
          (matched[scored[i]]!.toList()..sort()),
        ),
      ),
  ];

  return DisplayOnlyStatRanking(
    source: DimStatRankingSource.inferred,
    entries: List<RankedDimStat>.unmodifiable(entries),
  );
}

class _KeywordHit {
  const _KeywordHit({required this.word, required this.stat});
  final String word;
  final ArmorStatName stat;
}

/// Lowercase alphanumeric tokens; matches [kDimStatKeywordTable] keys.
Iterable<_KeywordHit> _scanKeywords(String text) sync* {
  final lower = text.toLowerCase();
  final re = RegExp(r"[a-z0-9']+");
  for (final m in re.allMatches(lower)) {
    final word = m.group(0)!;
    final stat = kDimStatKeywordTable[word];
    if (stat != null) {
      yield _KeywordHit(word: word, stat: stat);
    }
  }
}

ArmorStatName? _statFromConstraint(CachedDimStatConstraint row) {
  final byName = ArmorStatName.tryParse(row.name);
  if (byName != null) return byName;
  return _statFromHash(row.statHash);
}

ArmorStatName? _statFromHash(int hash) {
  for (final stat in ArmorStatName.all) {
    if (DimStatHashes.forArmorStat(stat) == hash) return stat;
  }
  return null;
}
