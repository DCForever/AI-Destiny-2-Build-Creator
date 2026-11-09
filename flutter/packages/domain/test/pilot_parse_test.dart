import 'dart:convert';
import 'dart:io';

import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  test('CSV schema rejects a short header and an unclosed quote', () {
    expect(
      () => parsePilotCsv('type,exotic\n'),
      throwsFormatException,
    );
    expect(
      () => parseCsvTable('"unterminated'),
      throwsFormatException,
    );
  });

  test('CSV keeps quoted commas, quotes, and newlines', () {
    final csv = '${pilotCsvColumns.join(',')}\n'
        '"armor","Solipsism","prismatic","Name, ""quoted""","Creator","S","D",'
        '"https://dim.gg/abc","4pc CODA","","dim","Does: alpha\n'
        'Loop: beta\nUses: x\nSet: 4pc CODA (proposal)\nBest for: \nSource: s"\n'
        'armor,Other,solar,Decoy,Nobody,S,D,https://dim.gg/nope,none,,,notes\n';
    final rows = parseCsvTable(csv);
    expect(rows[1][3], 'Name, "quoted"');
    expect(rows[1].last, contains('Loop: beta'));
    expect(parsePilotCsv(csv), isEmpty);
  });

  test('trimmed fixture preserves the five identities and drops nothing else',
      () {
    final matrixPath = _fixture('contrast_matrix.json');
    final csvPath = _fixture('contrast_queue.csv');
    final matrixBefore = File(matrixPath).readAsBytesSync();
    final csvBefore = File(csvPath).readAsBytesSync();
    final board = loadPilotBoard(
      matrixJson: utf8.decode(matrixBefore),
      csvText: utf8.decode(csvBefore),
    );
    expect(File(matrixPath).readAsBytesSync(), matrixBefore);
    expect(File(csvPath).readAsBytesSync(), csvBefore);

    final details = <String>[
      for (final review in board.cases)
        for (final row in review.records) row.record.sourceDetail,
    ];
    expect(details, isNot(contains(contains('Aeon'))));
    expect(details.length, 12);
    expect(_case(board, 'kahoona-hexbugs').records, hasLength(4));
    expect(_case(board, 'debs-ignition').records, hasLength(2));
    expect(_case(board, 'tipsy-gambit').records, hasLength(2));
    expect(_case(board, 'zirak-witness').records, hasLength(3));
    expect(_case(board, 'suutekk-solar').records, hasLength(1));
  });

  test('Kahoona rows keep link, loop, and both perk labelings', () {
    final board = _board();
    final rows = _case(board, 'kahoona-hexbugs').records;
    final prismatic = rows.singleWhere(
      (row) => row.record.sourceDetail.endsWith('/prismatic'),
    );
    expect(
      prismatic.record.originalDimLink,
      "https://dim.gg/lxggu2a/Kahoona's-HexBugs-N-Supers!",
    );
    expect(
      prismatic.record.doesText.value,
      'Prismatic Solipsism super-spam build built on the Apotheosis + Harmony class item.',
    );
    expect(
      prismatic.record.loopText.value,
      'Harmony gives super energy on kills, Elemental Supercharger tops it off, and you cast your super again.',
    );
    expect(prismatic.record.classItemPerk1.value, 'Spirit of Apotheosis');
    expect(prismatic.record.classItemPerk2.value, 'Spirit of Harmony');
    expect(prismatic.record.armorSetProposal, '4pc CODA');
    expect(prismatic.record.personalDimLink.present, isFalse);
    expect(prismatic.record.buildName, isNot(prismatic.record.loopText.value));

    final combo = rows.singleWhere(
      (row) => row.record.sourceDetail.contains('Apotheosis + Harmony'),
    );
    expect(combo.record.classItemPerk1.value, 'Apotheosis');
    expect(combo.record.classItemPerk2.value, 'Harmony');
    expect(combo.record.armorSetProposal, 'no strong fit');
    expect(
      _case(board, 'kahoona-hexbugs').caseReasons,
      contains(PilotReason.perkLabelConflict),
    );
    expect(
      _case(board, 'kahoona-hexbugs').caseReasons,
      contains(PilotReason.setProposalConflict),
    );
  });

  test('Debs, Tipsy, zirak, and Suutekk keep gaps and the invalid subclass',
      () {
    final board = _board();
    final debs = _case(board, 'debs-ignition').records.singleWhere(
          (row) => row.record.sourceKind == 'matrix',
        );
    expect(debs.record.ergoTrait.value, 'Perfect Fifth');
    expect(debs.record.ergoFrame.value, 'Caster Frame');
    expect(debs.record.ergoElement.value, pilotUnknownPerkToken);
    expect(debs.record.originalDimLink, 'https://dim.gg/thxdq4y');
    expect(
      debs.record.doesText.value,
      "Solar build with infinite ignitions using Skyburner's Oath.",
    );
    expect(debs.reasons, contains(PilotReason.ergoElementUnresolved));

    final tipsy = _case(board, 'tipsy-gambit').records.singleWhere(
          (row) => row.record.sourceKind == 'matrix',
        );
    expect(tipsy.record.loopText.present, isTrue);
    expect(tipsy.record.loopText.isBlank, isTrue);
    expect(tipsy.record.doesText.value, isNot('Gambit'));
    expect(tipsy.record.ergoTrait.value, pilotUnknownPerkToken);
    expect(tipsy.record.armorSetProposal, '4pc Seventh Seraph');

    final zirak = _case(board, 'zirak-witness');
    expect(zirak.caseReasons, contains(PilotReason.setProposalConflict));
    expect(zirak.caseReasons, contains(PilotReason.linkPathMismatch));
    expect(
      zirak.records.map((row) => row.record.armorSetProposal).toSet(),
      containsAll(<String>['4pc Seventh Seraph', '4pc Iron Battalion Set']),
    );
    expect(
      zirak.records.every((row) => row.record.loopText.isBlank),
      isTrue,
    );

    final suutekk = _case(board, 'suutekk-solar').records.single;
    expect(suutekk.record.subclassText.value, 'solar');
    expect(suutekk.reasons, contains(PilotReason.invalidSolipsism));
    expect(suutekk.record.originalDimLink, 'https://dim.gg/he6yssi');
  });
}

PilotBoard _board() {
  return loadPilotBoard(
    matrixJson: File(_fixture('contrast_matrix.json')).readAsStringSync(),
    csvText: File(_fixture('contrast_queue.csv')).readAsStringSync(),
  );
}

PilotCaseReview _case(PilotBoard board, String caseId) {
  return board.cases.singleWhere((review) => review.caseId == caseId);
}

String _fixture(String name) {
  var dir = Directory.current;
  for (var i = 0; i < 8; i++) {
    final candidate = File(
      '${dir.path}/apps/windows_host/assets/pilot/$name',
    );
    if (candidate.existsSync()) return candidate.path;
    final parent = dir.parent;
    if (parent.path == dir.path) break;
    dir = parent;
  }
  throw StateError(
      'pilot fixture $name not found from ${Directory.current.path}');
}
