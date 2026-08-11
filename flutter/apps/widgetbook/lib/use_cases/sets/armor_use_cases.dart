import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

List<SetsArmorSlotData> _emptySlots() => [
      for (var i = 0; i < kArmorBoardSlotWires.length; i++)
        SetsArmorSlotData(
          slotWire: kArmorBoardSlotWires[i],
          slotLabel: kArmorBoardSlotLabels[i],
        ),
    ];

List<SetsArmorSlotData> _filledSlots() => [
      for (var i = 0; i < kArmorBoardSlotWires.length; i++)
        SetsArmorSlotData(
          slotWire: kArmorBoardSlotWires[i],
          slotLabel: kArmorBoardSlotLabels[i],
          itemName: 'Demo $i',
          instanceId: 'wb-$i',
          isExotic: i == 0,
          setBonusKey: i > 0 ? 'TechSec' : null,
          stats: {
            for (final l in kArmorBoardEofStatLabels) l: 10 + i,
          },
        ),
    ];

@widgetbook.UseCase(
  name: 'Library dual-pane Armor',
  type: SetsLibraryWorkspace,
  path: '[Sets]/Armor',
)
Widget setsLibraryArmor(BuildContext context) {
  return SizedBox(
    width: 1100,
    height: 700,
    child: SetsLibraryWorkspace(
      rows: const [
        SetsArmorLibraryRowData(
          id: '1',
          name: 'Raid Titan · TechSec',
          classLabel: 'Titan',
          pieceCount: 4,
          coverageLabel: 'TechSec 2pc',
          usedByLabel: 'Main',
          selected: true,
        ),
        SetsArmorLibraryRowData(
          id: '2',
          name: 'Hunter · — · —',
          classLabel: 'Hunter',
          pieceCount: 0,
        ),
      ],
      detail: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Raid Titan · TechSec'),
            SizedBox(height: 12),
            SetsModSetDeepLink(linkedModSetId: 'mod-1', linkedModSetName: 'Raid'),
          ],
        ),
      ),
      onNewSet: () {},
      onSelectRow: (_) {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Create step Type',
  type: SetsCreateWizard,
  path: '[Sets]/Armor',
)
Widget setsCreateStepType(BuildContext context) {
  return const SizedBox(
    width: 520,
    height: 560,
    child: SetsCreateWizard(
      setType: 'armor',
      step: 0,
      showEmbeddedFooter: true,
      canContinue: true,
      availableFamilies: ['TechSec', 'Twofer'],
    ),
  );
}

@widgetbook.UseCase(
  name: 'Create step Class',
  type: SetsCreateWizard,
  path: '[Sets]/Armor',
)
Widget setsCreateStepClass(BuildContext context) {
  return const SizedBox(
    width: 520,
    height: 560,
    child: SetsCreateWizard(
      setType: 'armor',
      step: 1,
      guardianClass: null,
      showEmbeddedFooter: true,
      canContinue: false,
      availableFamilies: ['TechSec', 'Twofer'],
    ),
  );
}

@widgetbook.UseCase(
  name: 'Create step Bonus',
  type: SetsCreateWizard,
  path: '[Sets]/Armor',
)
Widget setsCreateStepBonus(BuildContext context) {
  return const SizedBox(
    width: 520,
    height: 640,
    child: SetsCreateWizard(
      setType: 'armor',
      step: 2,
      guardianClass: 'Titan',
      showEmbeddedFooter: true,
      canContinue: true,
      availableFamilies: ['TechSec', 'Twofer'],
    ),
  );
}

@widgetbook.UseCase(
  name: 'Create step Name',
  type: SetsCreateWizard,
  path: '[Sets]/Armor',
)
Widget setsCreateStepName(BuildContext context) {
  return const SizedBox(
    width: 520,
    height: 560,
    child: SetsCreateWizard(
      setType: 'armor',
      step: 3,
      guardianClass: 'Titan',
      namePreview: 'Titan · — · —',
      showEmbeddedFooter: true,
      onCreate: null,
    ),
  );
}

@widgetbook.UseCase(
  name: 'Create non-Armor thin',
  type: SetsCreateWizard,
  path: '[Sets]/Armor',
)
Widget setsCreateNonArmorThin(BuildContext context) {
  return const SizedBox(
    width: 520,
    height: 480,
    child: SetsCreateWizard(
      setType: 'weapon',
      step: 1,
      showEmbeddedFooter: true,
      onCreate: null,
    ),
  );
}

/// Legacy alias name kept for directories regen compatibility.
@widgetbook.UseCase(
  name: 'Create Type+Class lock',
  type: SetsCreateWizard,
  path: '[Sets]/Armor',
)
Widget setsCreateLock(BuildContext context) => setsCreateStepType(context);

@widgetbook.UseCase(
  name: 'Empty board layout A',
  type: SetsArmorBoard,
  path: '[Sets]/Armor',
)
Widget setsEmptyBoard(BuildContext context) {
  return SizedBox(
    width: 720,
    height: 640,
    child: SingleChildScrollView(
      child: SetsArmorBoard(
        slots: _emptySlots(),
        onOptimize: () {},
        onPickSlot: (_) {},
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Filled board + coverage',
  type: SetsArmorBoard,
  path: '[Sets]/Armor',
)
Widget setsFilledBoard(BuildContext context) {
  return SizedBox(
    width: 720,
    height: 720,
    child: SingleChildScrollView(
      child: SetsArmorBoard(
        slots: _filledSlots(),
        coverage: const SetsCoverageBandData(
          hardGoals: [
            SetsBonusGoalData(familyKey: 'TechSec', minPieces: 2),
          ],
          hardMet: true,
          softTwoPiece: ['TechSec'],
        ),
        onOptimize: () {},
        onPickSlot: (_) {},
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Owned compare table',
  type: SetsOwnedCompareTable,
  path: '[Sets]/Armor',
)
Widget setsOwnedCompare(BuildContext context) {
  return SizedBox(
    width: 900,
    height: 400,
    child: SingleChildScrollView(
      child: SetsOwnedCompareTable(
        rows: const [
          SetsOwnedCompareRowData(
            instanceId: 'i1',
            itemHash: 1,
            itemName: 'Helm A',
            total: 64,
            power: 2000,
            bonusFit: true,
          ),
          SetsOwnedCompareRowData(
            instanceId: 'i2',
            itemHash: 2,
            itemName: 'Exotic Helm',
            isExotic: true,
            exoticBlocked: true,
            total: 70,
            power: 2000,
          ),
        ],
        onSelect: (_) {},
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'Optimize confirm shell',
  type: SetsOptimizeConfirmShell,
  path: '[Sets]/Armor',
)
Widget setsOptimizeConfirm(BuildContext context) {
  return SizedBox(
    width: 800,
    height: 520,
    child: SetsOptimizeConfirmShell(
      hasPins: true,
      classLabel: 'Titan',
      exoticLabel: 'Cuirass',
      bonusGoalsLabel: 'TechSec 2pc',
      selectedKitId: 'kit-1',
      kits: const [
        SetsOptimizeKitRowData(
          id: 'kit-1',
          total: 210,
          deltaVsCurrent: 12,
          goalsLabel: 'TechSec 2pc',
        ),
        SetsOptimizeKitRowData(
          id: 'kit-2',
          total: 200,
          deltaVsCurrent: 2,
          goalsLabel: 'TechSec 2pc',
        ),
      ],
      onSelectKit: (_) {},
      onConfirmApply: () {},
      onCancel: () {},
    ),
  );
}

@widgetbook.UseCase(
  name: 'Signed-out honesty',
  type: SetsHonestyEmpty,
  path: '[Sets]/Armor',
)
Widget setsSignedOut(BuildContext context) {
  return const SizedBox(
    width: 400,
    height: 300,
    child: SetsHonestyEmpty(
      kind: SetsHonestyKind.signedOut,
      message: 'Sign in to manage owned armor sets',
    ),
  );
}
