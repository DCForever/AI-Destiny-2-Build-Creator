import 'dart:io';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  final fixtureText = File(_fixturePath()).readAsStringSync();

  group('parseCachedDimLoadouts', () {
    test('parses the three-loadout synthetic fixture', () {
      final result = parseCachedDimLoadouts(fixtureText);
      expect(result.isOk, isTrue);
      expect(result.loadouts, hasLength(3));
      expect(result.catalog!.schemaVersion, 1);
      expect(result.loadouts.map((l) => l.shareId).toList(), [
        'syn-share-contraverse-001',
        'syn-share-linked-stats-002',
        'syn-share-unknown-003',
      ]);
    });

    test('wrong schemaVersion is unreadable with empty loadouts', () {
      final bad = fixtureText.replaceFirst(
        '"schemaVersion": 1',
        '"schemaVersion": 99',
      );
      final result = parseCachedDimLoadouts(bad);
      expect(result.status, CachedDimLoadoutsParseStatus.unreadable);
      expect(result.loadouts, isEmpty);
      expect(result.catalog, isNull);
      expect(result.detail, contains('schemaVersion'));
    });

    test('truncated JSON is unreadable with empty loadouts', () {
      final truncated = fixtureText.substring(0, 40);
      final result = parseCachedDimLoadouts(truncated);
      expect(result.status, CachedDimLoadoutsParseStatus.unreadable);
      expect(result.loadouts, isEmpty);
      expect(result.catalog, isNull);
    });

    test('oversized payload is unreadable before partial parse', () {
      final result = parseCachedDimLoadouts(fixtureText, maxBytes: 32);
      expect(result.status, CachedDimLoadoutsParseStatus.unreadable);
      expect(result.detail, contains('size limit'));
      expect(result.loadouts, isEmpty);
    });

    test('duplicate shareId is unreadable with empty loadouts', () {
      final duplicated = fixtureText.replaceFirst(
        '"shareId": "syn-share-linked-stats-002"',
        '"shareId": "syn-share-contraverse-001"',
      );
      final result = parseCachedDimLoadouts(duplicated);
      expect(result.status, CachedDimLoadoutsParseStatus.unreadable);
      expect(result.loadouts, isEmpty);
      expect(result.catalog, isNull);
      expect(result.detail, contains('duplicate shareId'));
      expect(result.detail, contains('syn-share-contraverse-001'));
    });
  });

  group('rankDimLoadoutStats', () {
    late List<CachedDimLoadout> loadouts;

    setUp(() {
      final result = parseCachedDimLoadouts(fixtureText);
      expect(result.isOk, isTrue);
      loadouts = result.loadouts;
    });

    test(
      'Contraverse-style grenade energy description ranks Grenade #1 inferred',
      () {
        final ranking = rankDimLoadoutStats(loadouts[0]);
        expect(ranking.source, DimStatRankingSource.inferred);
        expect(ranking.entries, isNotEmpty);
        expect(ranking.entries.first.stat, ArmorStatName.grenade);
        expect(ranking.entries.first.rank, 1);
        expect(ranking.entries.first.label, 'inferred');
        expect(ranking.entries.first.matchedWords, contains('grenade'));
      },
    );

    test('statConstraints override keywords and label from link', () {
      final ranking = rankDimLoadoutStats(loadouts[1]);
      expect(ranking.source, DimStatRankingSource.fromLink);
      expect(
        ranking.entries.map((e) => e.stat).toList(),
        [
          ArmorStatName.melee,
          ArmorStatName.health,
          ArmorStatName.grenade,
        ],
      );
      expect(ranking.entries.every((e) => e.label == 'from link'), isTrue);
      expect(ranking.entries.every((e) => e.matchedWords.isEmpty), isTrue);
    });

    test('no keyword match yields unknown with empty entries', () {
      final ranking = rankDimLoadoutStats(loadouts[2]);
      expect(ranking.source, DimStatRankingSource.unknown);
      expect(ranking.entries, isEmpty);
    });

    test(
      'negation-ish note still matches grenade and stays inferred',
      () {
        final loadout = CachedDimLoadout(
          shareId: 'syn-share-negation-004',
          name: 'Negation note',
          classType: 2,
          items: const [],
          subclassPlugs: const [],
          mods: const [],
          artifactPerks: const [],
          notes: 'no grenade needed',
        );
        final ranking = rankDimLoadoutStats(loadout);
        expect(ranking.source, DimStatRankingSource.inferred);
        expect(ranking.entries.single.stat, ArmorStatName.grenade);
        expect(ranking.entries.single.label, 'inferred');
        expect(ranking.entries.single.matchedWords, contains('grenade'));
      },
    );
  });

  group('display-only ranking guard', () {
    test('ranking type exposes only display fields, not SoftStatTargets', () {
      final ranking = rankDimLoadoutStats(
        parseCachedDimLoadouts(fixtureText).loadouts.first,
      );
      expect(ranking, isA<DisplayOnlyStatRanking>());
      expect(ranking.entries.first, isA<RankedDimStat>());
      // SoftStatTargets is a Map of targets — DisplayOnlyStatRanking has no
      // values/targets map and must not be passed into optimizer/fill-in.
      expect(ranking.entries.first.stat.wireName, 'Grenade');
      expect(
        ranking.runtimeType.toString(),
        'DisplayOnlyStatRanking',
      );
    });

    test('dim_loadouts sources never bridge into SoftStatTargets or optimizer',
        () {
      final flutterRoot = _findFlutterRoot();
      final violations = <String>[];
      const banned = <String>[
        'SoftStatTargets(',
        'OptimizerRequest',
        'matchFillIn(',
        'buildVariantDimLoadout(',
        'PruneOptions',
      ];
      for (final entity in flutterRoot.listSync(recursive: true)) {
        if (entity is! File) continue;
        final path = entity.path.replaceAll('\\', '/');
        if (!path.contains('/dim_loadouts/')) continue;
        if (!path.endsWith('.dart')) continue;
        if (path.contains('/test/')) continue;
        final text = entity.readAsStringSync();
        for (final pattern in banned) {
          if (text.contains(pattern)) {
            violations.add('$path: $pattern');
          }
        }
      }
      expect(violations, isEmpty, reason: violations.join('\n'));
    });
  });
}

String _fixturePath() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File(
      '${dir.path}/test/fixtures/dim_loadouts_min.json',
    );
    if (candidate.existsSync()) return candidate.path;
    final nested = File(
      '${dir.path}/packages/domain/test/fixtures/dim_loadouts_min.json',
    );
    if (nested.existsSync()) return nested.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('dim_loadouts_min.json fixture not found');
}

Directory _findFlutterRoot() {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    if (Directory('${dir.path}/packages/domain').existsSync()) {
      return dir;
    }
    if (Directory('${dir.path}/flutter/packages/domain').existsSync()) {
      return Directory('${dir.path}/flutter');
    }
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError('flutter root not found');
}
