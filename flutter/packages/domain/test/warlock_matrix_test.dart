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
      expect(
        isSolipsismNotPrismatic(
          exoticName: 'Solipsism',
          subclassKey: 'not-a-subclass',
        ),
        isFalse,
      );
      expect(
        isSolipsismNotPrismatic(exoticName: 'Solipsism', subclassKey: ''),
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
        'Sunshot',
      ]);
    });

    test('Solipsism on Solar is flagged and Prismatic is not', () {
      final rows = filterWarlockBuildsByExotic(builds, 'Solipsism');
      final flagged = rows.where((build) => build.solipsismNotPrismatic);
      expect(flagged.map((build) => build.name), ['Solipsism solar mismatch']);
      expect(
        rows.where((build) => build.name == 'Solipsism prismatic sample').single
            .solipsismNotPrismatic,
        isFalse,
      );
      final combo =
          rows.where((build) => build.name == 'Solipsism combo sample').single;
      expect(combo.subclassKey, '');
      expect(combo.subclassRecognized, isFalse);
      expect(combo.solipsismNotPrismatic, isFalse);
      expect(warlockSubclassLabel('solar'), 'Solar');
    });

    test('weapon cells are listed under the weapon exotic', () {
      final sunshot = filterWarlockBuildsByExotic(builds, 'Sunshot');
      expect(sunshot.map((build) => build.name), ['Sunshot solar sample']);
      expect(sunshot.single.subclassKey, 'solar');
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
            'combos': {
              'Inmost + Synthoceps': {
                'builds': [
                  {'name': 'Combo', 'subclass': 'Solar'},
                ],
              },
              'Empty': {'status': 'none found'},
            },
          },
        },
      },
      'weapons': {
        'cells': {
          'Sunshot': {
            'solar': [
              {'name': 'Weapon row', 'creator': 'Author'},
            ],
          },
        },
      },
    });

    expect(parsed.map((build) => build.name), [
      'Main',
      'Overflow',
      'Combo',
      'Weapon row',
    ]);
    expect(parsed[2].subclassKey, 'solar');
    expect(parsed[2].subclassRecognized, isTrue);
    expect(parsed[2].solipsismNotPrismatic, isTrue);
    expect(parsed.last.creator, 'Author');
    expect(parsed.map((build) => build.name), isNot(contains('Removed')));
  });

  test('missing and unrecognized combo subclasses stay unresolved', () {
    final parsed = parseWarlockMatrix({
      'exotics': {
        'Solipsism': {
          'combos': {
            'combos': {
              'Missing': {
                'builds': [
                  {'name': 'Missing subclass'},
                ],
              },
              'Unknown': {
                'builds': [
                  {'name': 'Unknown subclass', 'subclass': 'Not Stated'},
                ],
              },
            },
          },
        },
      },
    });
    final missing = parsed.singleWhere((b) => b.name == 'Missing subclass');
    final unknown = parsed.singleWhere((b) => b.name == 'Unknown subclass');
    expect(missing.subclassKey, '');
    expect(missing.subclassRecognized, isFalse);
    expect(missing.solipsismNotPrismatic, isFalse);
    expect(unknown.subclassKey, 'Not Stated');
    expect(unknown.subclassKey, isNot('prismatic'));
    expect(unknown.subclassKey, isNot('solar'));
    expect(unknown.subclassRecognized, isFalse);
    expect(unknown.solipsismNotPrismatic, isFalse);
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
