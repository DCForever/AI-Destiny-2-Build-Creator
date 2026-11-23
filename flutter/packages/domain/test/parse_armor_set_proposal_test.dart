import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:test/test.dart';

void main() {
  group('parseArmorSetProposal', () {
    test('parses 4pc primary phrase', () {
      final r = parseArmorSetProposal('4pc Seventh Seraph');
      expect(r.hasGoals, isTrue);
      expect(r.pieces, hasLength(1));
      expect(r.pieces.single.familyName, 'Seventh Seraph');
      expect(r.pieces.single.pieces, 4);
    });

    test('parses 2+2 and ignores alt suffix', () {
      final r = parseArmorSetProposal(
        "2pc CODA + 2pc Apostate's Blade (alt: 4pc CODA)",
      );
      expect(r.pieces.map((p) => '${p.pieces}pc ${p.familyName}').toList(), [
        '2pc CODA',
        "2pc Apostate's Blade",
      ]);
      expect(r.unparseable, isFalse);
    });

    test('no strong fit / blank / missing → no goals', () {
      expect(parseArmorSetProposal('no strong fit').noStrongFit, isTrue);
      expect(parseArmorSetProposal('No Strong Fit').hasGoals, isFalse);
      expect(parseArmorSetProposal('').hasGoals, isFalse);
      expect(parseArmorSetProposal(null).hasGoals, isFalse);
      expect(parseArmorSetProposal('   ').hasGoals, isFalse);
    });

    test('illegal or junk phrases are unparseable without throwing', () {
      expect(parseArmorSetProposal('4pc CODA + 2pc Foo').unparseable, isTrue);
      expect(parseArmorSetProposal('something weird').unparseable, isTrue);
      expect(parseArmorSetProposal('3pc CODA').unparseable, isTrue);
      expect(parseArmorSetProposal('2pc CODA + 2pc CODA').unparseable, isTrue);
    });
  });

  group('matchCatalogSetBonusKey', () {
    const catalog = [
      'CODA',
      'Seventh Seraph Set',
      "Apostate's Blade",
      'Wayward Psyche Set',
    ];

    test('exact and trailing Set match; never guesses', () {
      expect(
        matchCatalogSetBonusKey('CODA', catalogNames: catalog),
        'CODA',
      );
      expect(
        matchCatalogSetBonusKey('Seventh Seraph', catalogNames: catalog),
        'Seventh Seraph Set',
      );
      expect(
        matchCatalogSetBonusKey('Wayward Psyche Set', catalogNames: catalog),
        'Wayward Psyche Set',
      );
      expect(
        matchCatalogSetBonusKey('Unknown Family', catalogNames: catalog),
        isNull,
      );
    });
  });

  group('resolveArmorSetProposal', () {
    const catalog = [
      'CODA',
      'Seventh Seraph Set',
      "Apostate's Blade",
    ];

    test('maps 4pc and 2+2 to legal goals', () {
      final four = resolveArmorSetProposal(
        raw: '4pc Seventh Seraph',
        catalogNames: catalog,
      );
      expect(four.goals, hasLength(1));
      expect(four.goals.single.setBonusKey, 'Seventh Seraph Set');
      expect(four.goals.single.minPieces, 4);
      expect(four.unresolvedNote, isNull);

      final twoTwo = resolveArmorSetProposal(
        raw: "2pc CODA + 2pc Apostate's Blade (alt: 4pc CODA)",
        catalogNames: catalog,
      );
      expect(twoTwo.goals.map((g) => '${g.minPieces}:${g.setBonusKey}'), [
        '2:CODA',
        "2:Apostate's Blade",
      ]);
    });

    test('unmatched piece drops that goal and surfaces a reason', () {
      final partial = resolveArmorSetProposal(
        raw: '2pc CODA + 2pc Not A Real Set',
        catalogNames: catalog,
      );
      expect(partial.goals, hasLength(1));
      expect(partial.goals.single.setBonusKey, 'CODA');
      expect(partial.unmatchedNames, ['Not A Real Set']);
      expect(partial.unresolvedNote, contains('Not A Real Set'));

      final none = resolveArmorSetProposal(
        raw: '4pc Totally Fake',
        catalogNames: catalog,
      );
      expect(none.goals, isEmpty);
      expect(none.unresolvedNote, contains('Totally Fake'));
    });

    test('no strong fit stays empty', () {
      final r = resolveArmorSetProposal(
        raw: 'no strong fit',
        catalogNames: catalog,
      );
      expect(r.goals, isEmpty);
      expect(r.noStrongFit, isTrue);
      expect(r.unresolvedNote, contains('no strong fit'));
    });
  });
}
