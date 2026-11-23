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
/// Armor pool / readiness / swap data stay empty — matrix rows carry
/// name, exotic, subclass, creator, DIM link, and Mario's armor set proposal.
///
/// [catalogSetBonusNames] maps proposal family labels to catalog keys. When
/// empty, unmatched proposals yield no [MockBuild.setBonuses] (Optimize can
/// rematch later once the catalog is loaded).
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
  final subclass = _subclassLabel(row);
  final exoticArmor = row.isWeaponExotic ? '' : row.exoticName;
  final exoticWeapon = row.isWeaponExotic ? row.exoticName : '';
  final creator = row.creator;
  final loop = creator == null || creator.isEmpty
      ? row.name
      : '${row.name} · $creator';
  final mapped = mockSetBonusesFromArmorSetProposal(
    proposal: row.armorSetProposal,
    catalogSetBonusNames: catalogSetBonusNames,
  );
  return MockBuild(
    id: 'matrix_$index',
    name: row.name,
    subclass: subclass,
    exoticArmor: exoticArmor,
    exoticWeapon: exoticWeapon,
    slots: const [],
    loop: loop,
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
  // Catalog not loaded yet — keep silent; rematch after names arrive.
  if (catalog.isEmpty) {
    final parsed = parseArmorSetProposal(proposal);
    if (parsed.noStrongFit || parsed.unparseable || !parsed.hasGoals) {
      final resolved = resolveArmorSetProposal(
        raw: proposal,
        catalogNames: const [],
      );
      return (bonuses: const [], unresolvedNote: resolved.unresolvedNote);
    }
    return (bonuses: const [], unresolvedNote: null);
  }
  final resolved = resolveArmorSetProposal(
    raw: proposal,
    catalogNames: catalog,
  );
  if (resolved.goals.isEmpty) {
    return (
      bonuses: const [],
      unresolvedNote: resolved.unresolvedNote,
    );
  }
  final bonuses = <MockSetBonus>[
    for (final g in resolved.goals)
      MockSetBonus(
        setId: g.setBonusKey,
        setName: g.setBonusKey,
        pieces: g.minPieces,
        tier: g.minPieces >= 4 ? '4pc' : '2pc',
        text: '${g.minPieces}pc ${g.setBonusKey}',
      ),
  ];
  return (
    bonuses: List<MockSetBonus>.unmodifiable(bonuses),
    unresolvedNote: resolved.unmatchedNames.isEmpty
        ? null
        : resolved.unresolvedNote,
  );
}

/// Rematch Mario proposals on matrix builds after the set-bonus catalog loads.
///
/// Skips optimized builds so a confirmed Optimize result is not overwritten.
/// Builds without [MockBuild.armorSetProposal] are left unchanged (user/fixture
/// set bonuses stay as the default they already are).
List<MockBuild> rematchMatrixArmorSetProposals({
  required List<MockBuild> builds,
  required Iterable<String> catalogSetBonusNames,
}) {
  final out = <MockBuild>[];
  for (final b in builds) {
    if (b.isOptimized ||
        b.armorSetProposal == null ||
        b.armorSetProposal!.trim().isEmpty) {
      out.add(b);
      continue;
    }
    final mapped = mockSetBonusesFromArmorSetProposal(
      proposal: b.armorSetProposal,
      catalogSetBonusNames: catalogSetBonusNames,
    );
    // Rebuild so a successful rematch can clear a prior unresolved note.
    out.add(
      MockBuild(
        id: b.id,
        name: b.name,
        subclass: b.subclass,
        exoticArmor: b.exoticArmor,
        exoticWeapon: b.exoticWeapon,
        slots: b.slots,
        loop: b.loop,
        artifact: b.artifact,
        setBonuses: mapped.bonuses,
        stats: b.stats,
        splitWhy: b.splitWhy,
        creator: b.creator,
        dimLink: b.dimLink,
        exoticWeaponType: b.exoticWeaponType,
        exoticWeaponDamageType: b.exoticWeaponDamageType,
        exoticWeaponSlot: b.exoticWeaponSlot,
        armorSetProposal: b.armorSetProposal,
        setBonusUnresolvedNote: mapped.unresolvedNote,
        isOptimized: b.isOptimized,
      ),
    );
  }
  return out;
}

String _subclassLabel(WarlockMatrixBuild row) {
  if (row.subclassRecognized) {
    return warlockSubclassLabel(row.subclassKey);
  }
  final raw = row.subclassKey.trim();
  if (raw.isEmpty) return 'Unresolved';
  return raw;
}
