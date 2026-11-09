import 'dart:convert';
import 'dart:io';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  late PilotBoard board;

  setUp(() {
    board = loadPilotBoard(
      matrixJson: File(_fixture('contrast_matrix.json')).readAsStringSync(),
      csvText: File(_fixture('contrast_queue.csv')).readAsStringSync(),
    );
  });

  test('exact perk match does not accept a name or a different pair', () {
    final checks = {for (final check in board.perkChecks) check.itemId: check};
    final spirit = checks['synthetic-solipsism-spirit-pair']!;
    final nameOnly = checks['synthetic-solipsism-name-only']!;
    final other = checks['synthetic-solipsism-other-pair']!;
    final shortPair = checks['synthetic-solipsism-short-pair']!;
    final ergoPartial = checks['synthetic-ergo-trait-frame-only']!;

    expect(spirit.matchedDetails, contains(contains('/prismatic')));
    expect(spirit.matchedDetails,
        isNot(contains(contains('Apotheosis + Harmony'))));
    expect(
        shortPair.matchedDetails, contains(contains('Apotheosis + Harmony')));
    expect(nameOnly.matched, isFalse);
    expect(other.matched, isFalse);
    expect(ergoPartial.matched, isFalse);
    expect(checks['synthetic-ergo-name-only']!.matched, isFalse);
  });

  test('no pilot case exports, and the shape sample is marked synthetic', () {
    for (final review in board.cases) {
      expect(review.exportAllowed, isFalse, reason: review.caseId);
      expect(gatedPersonalDimJson(review), isNull);
    }
    final sample = syntheticDimShapeSample();
    final encoded = jsonEncode(sample);
    expect(encoded, contains(pilotSyntheticBanner));
    expect(encoded, contains('SYNTHETIC SHAPE SAMPLE'));
    expect(encoded, isNot(contains('dim.gg')));
    expect(sample['dimAcceptance'], isFalse);
    expect(sample['synthetic'], isTrue);
    final loadout = sample['loadout']! as Map<String, Object?>;
    expect(
        loadout.keys,
        containsAll(
            <String>['id', 'name', 'classType', 'equipped', 'unequipped']));
  });

  test('a fully stated single row can export only as labeled synthetic JSON',
      () {
    const record = PilotSourceRecord(
      caseId: 'synthetic-resolved',
      sourceKind: 'test',
      sourceDetail: 'handmade',
      rowType: 'matrix-exotic',
      filingExotic: 'Solipsism',
      weaponExotic: PilotText.absent(),
      subclassText: PilotText('prismatic'),
      buildName: 'Handmade resolved row',
      creator: 'Test',
      season: PilotText('S'),
      date: PilotText('2026-01-01'),
      originalDimLink: 'https://dim.gg/source-only',
      armorSetProposal: '4pc CODA',
      personalDimLink: PilotText(''),
      dimName: PilotText('name'),
      doesText: PilotText('Does stay here'),
      loopText: PilotText('Loop stays here'),
      notesDoes: PilotText('Does stay here'),
      notesLoop: PilotText('Loop stays here'),
      notesSet: PilotText('4pc CODA (proposal)'),
      classItemPerk1: PilotText('Spirit of Apotheosis'),
      classItemPerk2: PilotText('Spirit of Harmony'),
      ergoTrait: PilotText.absent(),
      ergoElement: PilotText.absent(),
      ergoFrame: PilotText.absent(),
    );
    final allowed = PilotCaseReview(
      caseId: 'synthetic-resolved',
      records: <PilotRecordReview>[
        PilotRecordReview(
          record: record,
          reasons: const <String>[],
          perkRequirement: perkRequirementFor(record),
        ),
      ],
      caseReasons: const <String>[],
      ambiguityNotes: const <String>[],
    );
    expect(allowed.exportAllowed, isTrue);
    final encoded = jsonEncode(gatedPersonalDimJson(allowed));
    expect(encoded, contains(pilotSyntheticBanner));
    expect(encoded, contains('Does stay here'));
    expect(encoded, contains('Loop stays here'));
    expect(encoded, isNot(contains('dim.gg/source-only')));
    expect(encoded, isNot(contains('https://dim.gg')));
  });

  test(
      'stat and set proposals stay synthetic and do not claim a global optimum',
      () {
    final tipsy =
        board.cases.singleWhere((item) => item.caseId == 'tipsy-gambit');
    final stat = board.proposals.singleWhere(
      (item) => item.caseId == 'tipsy-gambit' && item.kind == 'stat-total',
    );
    final setGoal = board.proposals.singleWhere(
      (item) => item.caseId == 'tipsy-gambit' && item.kind == 'set-goal',
    );
    expect(stat.summary, contains('SYNTHETIC'));
    expect(stat.instanceIds, everyElement(contains('synthetic-')));
    expect(setGoal.withheld, isFalse);
    expect(setGoal.score!, lessThan(stat.score!));
    expect(
      setGoal.instanceIds.where((id) => id.startsWith('synthetic-set-')).length,
      greaterThanOrEqualTo(4),
    );
    expect(tipsy.exportAllowed, isFalse);

    final kahoonaSet = board.proposals.singleWhere(
      (item) => item.caseId == 'kahoona-hexbugs' && item.kind == 'set-goal',
    );
    expect(kahoonaSet.withheld, isTrue);
    expect(kahoonaSet.instanceIds, isEmpty);

    final suutekk = board.proposals.where(
      (item) => item.caseId == 'suutekk-solar',
    );
    expect(suutekk, isEmpty);

    expect(board.overlaps, isNotEmpty);
    expect(
      board.overlaps.every((overlap) => overlap.note == pilotNotGlobalOptimum),
      isTrue,
    );
    expect(
      board.overlaps.map((overlap) => overlap.instanceId),
      contains('synthetic-stat-helmet'),
    );
    expect(pilotCompareReuse(preferReuse: true, reuseCount: 3), lessThan(0));

    final reuse = board.proposals.singleWhere(
      (item) => item.kind == 'reuse-tie-break',
    );
    expect(reuse.instanceIds, contains('synthetic-reused-helmet'));
    final before = tipsy.records.first.record.loopText.value;
    expect(tipsy.records.first.record.loopText.value, before);
  });
}

String _fixture(String name) {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File('${dir.path}/apps/windows_host/assets/pilot/$name');
    if (candidate.existsSync()) return candidate.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
      'pilot fixture $name not found from ${Directory.current.path}');
}
