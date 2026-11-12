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
/// Armor pool / readiness / swap data stay empty — matrix rows only carry
/// name, exotic, subclass, creator, and DIM link.
BuildsMockFixture buildsMockFixtureFromMatrix(
  List<WarlockMatrixBuild> rows,
) {
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
  final subclass = _subclassLabel(row);
  final exoticArmor = row.isWeaponExotic ? '' : row.exoticName;
  final exoticWeapon = row.isWeaponExotic ? row.exoticName : '';
  final creator = row.creator;
  final loop = creator == null || creator.isEmpty
      ? row.name
      : '${row.name} · $creator';
  return MockBuild(
    id: 'matrix_$index',
    name: row.name,
    subclass: subclass,
    exoticArmor: exoticArmor,
    exoticWeapon: exoticWeapon,
    slots: const [],
    loop: loop,
    artifact: const MockArtifact(name: '—', season: '—'),
    setBonuses: const [],
    stats: const [],
    creator: creator,
    dimLink: row.dimLink,
  );
}

String _subclassLabel(WarlockMatrixBuild row) {
  if (row.subclassRecognized) {
    return warlockSubclassLabel(row.subclassKey);
  }
  final raw = row.subclassKey.trim();
  if (raw.isEmpty) return 'Unresolved';
  return raw;
}
