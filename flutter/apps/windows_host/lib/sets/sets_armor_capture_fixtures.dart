/// Host-fixture seeds for Sets Armor Capture shot_matrix (001-armor).
///
/// Drive ids match plan shot_matrix `drive: host-fixture` rows.
library;

import 'package:destiny2_app/destiny2_app.dart';
import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';

/// Shot matrix ids that Capture must exercise (must=true).
const kSetsArmorMustShotIds = <String>[
  'desktop-library-armor',
  'desktop-signed-out-honesty',
  'desktop-create-type-class',
  'desktop-empty-board',
  'desktop-filled-board-coverage',
  'desktop-owned-compare',
  'desktop-optimize-confirm',
  'desktop-delete-set-in-use',
];

/// Optional matrix ids (must=false) — Capture may shoot when convenient.
const kSetsArmorOptionalShotIds = <String>[
  'desktop-tags-blocked',
  'desktop-need-sync',
  'desktop-non-armor-thin',
];

/// Full Capture rail order (must first, then optional).
const kSetsArmorCaptureMatrixIds = <String>[
  ...kSetsArmorMustShotIds,
  ...kSetsArmorOptionalShotIds,
];

/// Optional Capture surface keys hosts should expose for dual-truth.
const kSetsArmorCaptureSurfaceKeys = <String>[
  'sets_library_workspace',
  'sets_library_new',
  'sets_create_wizard',
  'sets_create_type',
  'sets_create_class',
  'sets_create_pieces_hidden',
  'sets_armor_board',
  'sets_optimize_primary',
  'sets_board_sigma',
  'sets_owned_compare_table',
  'sets_fill_owned_compare',
  'sets_optimize_confirm_shell',
  'sets_optimize_kit_matrix',
  'sets_delete_confirm_dialog',
  'sets_delete_set_in_use',
  'sets_honesty_signedOut',
  'sets_mod_set_deep_link',
];

/// Fixture Armor library rows (dual-pane + used-by).
List<SetsArmorLibraryRowData> fixtureLibraryArmorRows() => const [
      SetsArmorLibraryRowData(
        id: 'armor-raid',
        name: 'Raid Titan · TechSec',
        classLabel: 'Titan',
        pieceCount: 4,
        coverageLabel: 'TechSec 2pc',
        usedByLabel: 'Main · default',
        selected: true,
      ),
      SetsArmorLibraryRowData(
        id: 'armor-empty',
        name: 'Hunter · — · —',
        classLabel: 'Hunter',
        pieceCount: 0,
        coverageLabel: '—',
        usedByLabel: '—',
      ),
    ];

List<SetsArmorSlotData> fixtureEmptyBoardSlots() => [
      for (var i = 0; i < kArmorBoardSlotWires.length; i++)
        SetsArmorSlotData(
          slotWire: kArmorBoardSlotWires[i],
          slotLabel: kArmorBoardSlotLabels[i],
        ),
    ];

List<SetsArmorSlotData> fixtureFilledBoardSlots() => [
      for (var i = 0; i < kArmorBoardSlotWires.length; i++)
        SetsArmorSlotData(
          slotWire: kArmorBoardSlotWires[i],
          slotLabel: kArmorBoardSlotLabels[i],
          itemName: 'Fixture $i',
          instanceId: 'fix-inst-$i',
          isExotic: i == 2,
          setBonusKey: i != 2 ? 'TechSec' : null,
          stats: {
            for (final l in kArmorBoardEofStatLabels) l: 8 + i,
          },
        ),
    ];

List<OwnedArmorCompareRow> fixtureOwnedCompareRows() => [
      OwnedArmorCompareRow(
        instanceId: 'own-1',
        itemHash: 100,
        itemName: 'Fixture Helm',
        slot: 'helmet',
        power: 2000,
        setBonusKey: 'TechSec',
        bonusFit: true,
        statValues: {
          for (final s in ArmorStatName.all) s: 12,
        },
      ),
      OwnedArmorCompareRow(
        instanceId: 'own-2',
        itemHash: 101,
        itemName: 'Fixture Exotic Helm',
        slot: 'helmet',
        isExotic: true,
        power: 2000,
        statValues: {
          for (final s in ArmorStatName.all) s: 14,
        },
      ),
    ];

/// Presentation rows for [SetsOwnedCompareTable] (ranked + mapped).
List<SetsOwnedCompareRowData> fixtureOwnedComparePresentationRows() {
  final ranked = rankOwnedArmorCompare(fixtureOwnedCompareRows());
  return [
    for (final r in ranked)
      SetsOwnedCompareRowData(
        instanceId: r.instanceId,
        itemHash: r.itemHash,
        itemName: r.itemName,
        isExotic: r.isExotic,
        total: r.totalStats,
        power: r.power,
        bonusFit: r.bonusFit,
        setBonusKey: r.setBonusKey,
        exoticBlocked: r.isExotic,
        stats: {
          for (final e in r.statValues.entries) e.key.wireName: e.value,
        },
      ),
  ];
}

List<SetsOptimizeKitRowData> fixtureOptimizeKits() => const [
      SetsOptimizeKitRowData(
        id: 'kit-a',
        total: 210,
        deltaVsCurrent: 15,
        goalsLabel: 'TechSec 2pc',
        slotNames: {
          'helmet': 'H1',
          'arms': 'A1',
          'chest': 'C1',
          'legs': 'L1',
          'class_item': 'CI1',
        },
        selected: true,
      ),
      SetsOptimizeKitRowData(
        id: 'kit-b',
        total: 198,
        deltaVsCurrent: 3,
        goalsLabel: 'TechSec 2pc',
        slotNames: {
          'helmet': 'H2',
          'arms': 'A2',
          'chest': 'C2',
          'legs': 'L2',
          'class_item': 'CI2',
        },
      ),
    ];

SetsCoverageBandData fixtureCoverageBand() => const SetsCoverageBandData(
      hardGoals: [
        SetsBonusGoalData(familyKey: 'TechSec', minPieces: 2),
      ],
      hardMet: true,
      softTwoPiece: ['TechSec'],
    );
