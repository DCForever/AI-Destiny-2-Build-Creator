import 'dart:convert';
import 'dart:io';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('Solipsism flag', () {
    test('flags Solipsism off Prismatic only', () {
      expect(
        isSolipsismNotPrismatic(exoticName: 'Solipsism', subclassKey: 'solar'),
        isTrue,
      );
      expect(
        isSolipsismNotPrismatic(exoticName: ' solipsism ', subclassKey: 'Strand'),
        isTrue,
      );
      expect(
        isSolipsismNotPrismatic(
          exoticName: 'Solipsism',
          subclassKey: 'prismatic',
        ),
        isFalse,
      );
      expect(
        isSolipsismNotPrismatic(exoticName: 'Aeon Soul', subclassKey: 'solar'),
        isFalse,
      );
    });
  });

  group('exotic filter', () {
    late List<WarlockMatrixBuild> builds;

    setUp(() {
      builds = _loadFixture();
    });

    test('null filter returns every build in the fixture', () {
      expect(filterWarlockBuildsByExotic(builds, null), builds);
      expect(filterWarlockBuildsByExotic(builds, '  '), builds);
    });

    test('filters to the exotic name present in the data', () {
      final aeon = filterWarlockBuildsByExotic(builds, 'Aeon Soul');
      expect(aeon.map((build) => build.name), [
        'Aeon solar sample',
        'Aeon void sample',
      ]);
      expect(aeon.every((build) => !build.solipsismNotPrismatic), isTrue);
    });

    test('unknown exotic matches nothing', () {
      expect(filterWarlockBuildsByExotic(builds, 'Sunbracers'), isEmpty);
    });

    test('exotic picker lists only names that have builds', () {
      expect(exoticNamesIn(builds), [
        'Aeon Soul',
        'Necrotic Grip',
        'Solipsism',
      ]);
    });

    test('Solipsism on Solar is flagged and Prismatic is not', () {
      final rows = filterWarlockBuildsByExotic(builds, 'Solipsism');
      expect(rows, hasLength(2));
      final solar = rows.singleWhere((build) => build.subclassKey == 'solar');
      final prismatic = rows.singleWhere(
        (build) => build.subclassKey == 'prismatic',
      );
      expect(solar.solipsismNotPrismatic, isTrue);
      expect(prismatic.solipsismNotPrismatic, isFalse);
      expect(warlockSubclassLabel(solar.subclassKey), 'Solar');
    });
  });

  test('parser skips removed builds and keeps overflow rows', () {
    final parsed = parseWarlockMatrix({
      'exotics': {
        'Solipsism': {
          'prismatic': {
            'builds': [
              {'name': 'Main'},
            ],
            'overflow_builds': [
              {'name': 'Overflow', 'creator': 'Author'},
            ],
          },
          'removed_builds': [
            {'name': 'Removed'},
          ],
          'combos': {
            'item': 'Solipsism',
          },
        },
      },
    });

    expect(parsed.map((build) => build.name), ['Main', 'Overflow']);
    expect(parsed.last.creator, 'Author');
    expect(parsed.every((build) => !build.solipsismNotPrismatic), isTrue);
  });
}

List<WarlockMatrixBuild> _loadFixture() {
  final file = File(_fixturePath());
  final decoded = jsonDecode(file.readAsStringSync());
  return parseWarlockMatrix(decoded);
}

String _fixturePath() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File(
      '${dir.path}/packages/domain/test/fixtures/warlock_matrix_min.json',
    );
    if (candidate.existsSync()) return candidate.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
    'warlock matrix fixture not found from ${Directory.current.path}',
  );
}
