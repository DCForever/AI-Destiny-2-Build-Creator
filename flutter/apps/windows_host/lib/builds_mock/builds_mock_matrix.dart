import 'package:destiny2_domain/destiny2_domain.dart';

import 'builds_mock_models.dart';

/// Empty fixture used while the real matrix loads (or on missing/error).
BuildsMockFixture emptyBuildsMockFixture() {
  return const BuildsMockFixture(
    sets: [],
    builds: [],
    held: [],
    swaps: [],
  );
}

/// Map Warlock matrix rows into the Builds page fixture shape.
///
/// [catalogSetBonusNames] maps Mario proposal labels to catalog keys. When
/// empty, parseable proposals stay without setBonuses until Optimize rematch
/// (via [proposedSetBonusesFor] + catalog item-hash map).
BuildsMockFixture buildsMockFixtureFromMatrix(
  List<WarlockMatrixBuild> rows, {
  Iterable<String> catalogSetBonusNames = const [],
}) {
  return BuildsMockFixture(
    sets: const [],
    builds: [
      for (var i = 0; i < rows.length; i++)
        mockBuildFromWarlockMatrix(
          rows[i],
          index: i,
          catalogSetBonusNames: catalogSetBonusNames,
        ),
    ],
    held: const [],
    swaps: const [],
  );
}

/// One matrix entry → [MockBuild] for the Builds list / filters / DIM bind.
MockBuild mockBuildFromWarlockMatrix(
  WarlockMatrixBuild row, {
  required int index,
  Iterable<String> catalogSetBonusNames = const [],
}) {
  final creator = row.creator;
  final mapped = mockSetBonusesFromArmorSetProposal(
    proposal: row.armorSetProposal,
    catalogSetBonusNames: catalogSetBonusNames,
  );
  return MockBuild(
    id: 'matrix_$index',
    name: row.name,
    subclass: _subclassLabel(row),
    exoticArmor: row.isWeaponExotic ? '' : row.exoticName,
    exoticWeapon: row.isWeaponExotic ? row.exoticName : '',
    slots: const [],
    loop: creator == null || creator.isEmpty
        ? row.name
        : '${row.name} · $creator',
    artifact: const MockArtifact(name: '—', season: '—'),
    setBonuses: mapped.bonuses,
    stats: const [],
    creator: creator,
    dimLink: row.dimLink,
    armorSetProposal: row.armorSetProposal,
    setBonusUnresolvedNote: mapped.unresolvedNote,
  );
}

/// Map Mario's proposal into [MockSetBonus] goals using catalog family names.
({List<MockSetBonus> bonuses, String? unresolvedNote})
    mockSetBonusesFromArmorSetProposal({
  required String? proposal,
  required Iterable<String> catalogSetBonusNames,
}) {
  if (proposal == null || proposal.trim().isEmpty) {
    return (bonuses: const [], unresolvedNote: null);
  }
  final catalog = [
    for (final n in catalogSetBonusNames)
      if (n.trim().isNotEmpty) n.trim(),
  ];
  // Catalog not loaded — stay silent for parseable proposals (rematch later).
  if (catalog.isEmpty) {
    final parsed = parseArmorSetProposal(proposal);
    if (parsed.hasGoals) return (bonuses: const [], unresolvedNote: null);
    return (
      bonuses: const [],
      unresolvedNote: resolveArmorSetProposal(
        raw: proposal,
        catalogNames: const [],
      ).unresolvedNote,
    );
  }
  final resolved = resolveArmorSetProposal(
    raw: proposal,
    catalogNames: catalog,
  );
  if (resolved.goals.isEmpty) {
    return (bonuses: const [], unresolvedNote: resolved.unresolvedNote);
  }
  return (
    bonuses: List<MockSetBonus>.unmodifiable([
      for (final g in resolved.goals)
        MockSetBonus(
          setId: g.setBonusKey,
          setName: g.setBonusKey,
          pieces: g.minPieces,
          tier: g.minPieces >= 4 ? '4pc' : '2pc',
          text: '${g.minPieces}pc ${g.setBonusKey}',
        ),
    ]),
    unresolvedNote:
        resolved.unmatchedNames.isEmpty ? null : resolved.unresolvedNote,
  );
}

/// Visible note when Mario's proposal did not fully map (import or rematch).
String? armorSetProposalDisplayNote(
  MockBuild build, {
  Map<int, String> setBonusKeyByItemHash = const {},
}) {
  if (build.setBonuses.isNotEmpty) return null;
  final proposal = build.armorSetProposal?.trim() ?? '';
  if (proposal.isEmpty) return build.setBonusUnresolvedNote;
  if (setBonusKeyByItemHash.isEmpty) return build.setBonusUnresolvedNote;
  final catalog = <String>{
    for (final n in setBonusKeyByItemHash.values)
      if (n.trim().isNotEmpty) n.trim(),
  };
  return resolveArmorSetProposal(
    raw: proposal,
    catalogNames: catalog,
  ).unresolvedNote;
}

String _subclassLabel(WarlockMatrixBuild row) {
  if (row.subclassRecognized) return warlockSubclassLabel(row.subclassKey);
  final raw = row.subclassKey.trim();
  return raw.isEmpty ? 'Unresolved' : raw;
}
