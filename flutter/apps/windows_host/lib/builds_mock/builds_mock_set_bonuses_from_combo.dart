import 'package:destiny2_domain/destiny2_domain.dart';

import 'builds_mock_derived_name.dart';
import 'builds_mock_models.dart';

/// Build grid/detail set-bonus boxes from an optimizer combination summary.
///
/// Active 4pc → one combined box (via [combineBuildsMockSetBonuses]).
/// Active 2+2 → two separate 2pc boxes.
List<MockSetBonus> mockSetBonusesFromCombination(
  ArmorCombination combination, {
  Map<String, ({String twoPc, String fourPc})> catalogTextByKey = const {},
}) {
  final raw = <MockSetBonus>[];
  for (final e in combination.setBonusSummary) {
    if (!e.active2pc && !e.active4pc && e.pieceCount < 2) continue;
    final is4 = e.active4pc || e.pieceCount >= 4;
    final tier = is4 ? '4pc' : '2pc';
    final catalog = catalogTextByKey[e.setBonusKey];
    final text = is4
        ? (catalog?.fourPc.trim().isNotEmpty == true
            ? catalog!.fourPc.trim()
            : '$tier ${e.setBonusKey}')
        : (catalog?.twoPc.trim().isNotEmpty == true
            ? catalog!.twoPc.trim()
            : '$tier ${e.setBonusKey}');
    raw.add(
      MockSetBonus(
        setId: e.setBonusKey,
        setName: e.setBonusKey,
        pieces: is4 ? 4 : e.pieceCount.clamp(2, 3),
        tier: tier,
        text: text,
      ),
    );
  }
  return combineBuildsMockSetBonuses(raw);
}
