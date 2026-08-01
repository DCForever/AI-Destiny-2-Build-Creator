import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_app/destiny2_app.dart';
import 'package:test/test.dart';

void main() {
  group('finish_gaps_format (windows)', () {
    test('policy requires finish-complete AND equip-ready', () {
      expect(kFinishGapsPolicyCaption, contains('finish-complete AND equip-ready'));
      expect(kFinishIncompleteCtaCaption, contains('Finish incomplete'));

      expect(
        canProceedWithFinishAndEquipReady(
          finishComplete: true,
          equipReady: true,
        ),
        isTrue,
      );
      expect(
        canProceedWithFinishAndEquipReady(
          finishComplete: false,
          equipReady: true,
        ),
        isFalse,
      );
      expect(
        canProceedWithFinishAndEquipReady(
          finishComplete: true,
          equipReady: false,
        ),
        isFalse,
      );
    });

    test('evaluateFinishGaps incomplete shows category reasons', () {
      final r = evaluateFinishGaps(
        const EvaluateFinishGapsInput(
          variantId: 'v1',
          isDefaultVariant: true,
        ),
      );
      expect(r.complete, isFalse);
      expect(formatFinishGapsCompleteSummary(r), contains('Finish incomplete'));
      expect(r.gaps.length, 3);
      expect(
        formatFinishGapRowSummary(r.gaps.first),
        contains('Needs covering set'),
      );
    });

    test('satisfied categories format complete row', () {
      final armorSlots = EquipmentSlot.armorSlots.map((s) => s.wireName).toList();
      final weaponSlots =
          EquipmentSlot.weaponSlots.map((s) => s.wireName).toList();
      final equipment = <String, FinishEquipmentClaim?>{
        for (final s in [...armorSlots, ...weaponSlots])
          s: FinishEquipmentClaim(
            slot: s,
            itemHash: 1,
            itemName: s,
          ),
      };
      final r = evaluateFinishGaps(
        EvaluateFinishGapsInput(
          variantId: 'v1',
          isDefaultVariant: true,
          attachments: const [
            FinishAttachmentInput(
              setId: 'a1',
              mode: AttachmentMode.live,
              setType: SetType.armor,
              setName: 'Armor set',
            ),
            FinishAttachmentInput(
              setId: 'w1',
              mode: AttachmentMode.live,
              setType: SetType.weapon,
              setName: 'Weapon set',
            ),
            FinishAttachmentInput(
              setId: 'm1',
              mode: AttachmentMode.live,
              setType: SetType.mod,
              setName: 'Mod set',
            ),
          ],
          equipment: equipment,
        ),
      );
      expect(r.complete, isTrue);
      expect(formatFinishGapsCompleteSummary(r), 'Finish complete');
    });
  });
}
