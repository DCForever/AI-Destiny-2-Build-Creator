import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_windows_host/builds_mock/builds_mock_set_bonuses_from_combo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ArmorCombination combo(List<SetBonusSummaryEntry> summary) {
    return ArmorCombination(
      pieces: const [],
      estimatedStats: const {},
      incompleteEstimate: false,
      setBonusSummary: summary,
      reusePieceCount: 0,
      score: 0,
      meetsSoftThresholds: true,
    );
  }

  test('active 4pc yields one combined box', () {
    final boxes = mockSetBonusesFromCombination(
      combo(const [
        SetBonusSummaryEntry(
          setBonusKey: 'Techsec',
          pieceCount: 4,
          active2pc: true,
          active4pc: true,
        ),
      ]),
    );
    expect(boxes, hasLength(1));
    expect(boxes.single.tier, '4pc');
    expect(boxes.single.pieces, 4);
    expect(boxes.single.setId, 'Techsec');
  });

  test('2+2 yields two separate boxes', () {
    final boxes = mockSetBonusesFromCombination(
      combo(const [
        SetBonusSummaryEntry(
          setBonusKey: 'Alpha',
          pieceCount: 2,
          active2pc: true,
          active4pc: false,
        ),
        SetBonusSummaryEntry(
          setBonusKey: 'Beta',
          pieceCount: 2,
          active2pc: true,
          active4pc: false,
        ),
      ]),
    );
    expect(boxes, hasLength(2));
    expect(boxes.map((b) => b.tier).toSet(), {'2pc'});
    expect(boxes.map((b) => b.setId).toSet(), {'Alpha', 'Beta'});
  });
}
