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
/// Mario's `armor_set_proposal` is kept on [MockBuild.armorSetProposal];
/// Optimize rematches it to catalog keys in [proposedSetBonusesFor].
BuildsMockFixture buildsMockFixtureFromMatrix(List<WarlockMatrixBuild> rows) {
  return BuildsMockFixture(
    sets: const [],
    builds: [
      for (var i = 0; i < rows.length; i++)
        mockBuildFromWarlockMatrix(rows[i], index: i),
    ],
    held: const [],
    swaps: const [],
  );
}

/// One matrix entry → [MockBuild] for the Builds list / filters / DIM bind.
MockBuild mockBuildFromWarlockMatrix(
  WarlockMatrixBuild row, {
  required int index,
}) {
  final creator = row.creator;
  final resolved = resolveArmorSetProposal(
    raw: row.armorSetProposal,
    catalogNames: const [],
  );
  // Catalog-backed goals land later via proposedSetBonusesFor; note only for
  // no-strong-fit / unparseable so the detail pane can show a reason.
  final note = resolved.noStrongFit || resolved.unparseable
      ? resolved.unresolvedNote
      : null;
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
    setBonuses: const [],
    stats: const [],
    creator: creator,
    dimLink: row.dimLink,
    armorSetProposal: row.armorSetProposal,
    setBonusUnresolvedNote: note,
  );
}

String _subclassLabel(WarlockMatrixBuild row) {
  if (row.subclassRecognized) return warlockSubclassLabel(row.subclassKey);
  final raw = row.subclassKey.trim();
  return raw.isEmpty ? 'Unresolved' : raw;
}
