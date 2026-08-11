/// Structure-only Sets sheets for mobile (not Windows Capture exit gate).
///
/// Mounts library / create / board shells without Catalog fill embed.
library;

import 'package:destiny2_ui_flutter/destiny2_ui_flutter.dart';
import 'package:destiny2_ui_tokens/destiny2_ui_tokens.dart';
import 'package:flutter/material.dart';

/// Mobile Sets structure entry: list → create sheet → board sheet.
class SetsStructurePage extends StatefulWidget {
  const SetsStructurePage({super.key});

  @override
  State<SetsStructurePage> createState() => _SetsStructurePageState();
}

class _SetsStructurePageState extends State<SetsStructurePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('sets_mobile_structure'),
      appBar: AppBar(
        title: const Text('Sets'),
        actions: [
          IconButton(
            key: const Key('sets_library_new'),
            icon: const Icon(Icons.add),
            onPressed: () => _openCreate(context),
          ),
        ],
      ),
      body: ListView(
        key: const Key('sets_mobile_list'),
        children: [
          ListTile(
            key: const Key('sets_mobile_row_armor'),
            title: const Text('Armor sets (structure)'),
            subtitle: const Text('Open board shell'),
            onTap: () => _openBoard(context),
          ),
          const ListTile(
            key: Key('sets_mobile_row_non_armor'),
            title: Text('Weapon set (thin)'),
            subtitle: Text('Thin detail only'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreate(BuildContext context) async {
    var step = 0;
    var setType = 'armor';
    String? guardianClass;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModal) {
            final maxStep = setsCreateMaxStep(setType);
            final isFinal = step >= maxStep;
            final canContinue = setType == 'armor' && step == 1
                ? guardianClass != null
                : setType.isNotEmpty;
            return SafeArea(
              child: Padding(
                key: const Key('sets_mobile_create_sheet'),
                padding: const EdgeInsets.all(kSpace16),
                child: SizedBox(
                  height: MediaQuery.sizeOf(context).height * 0.75,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SetsCreateWizard(
                          step: step,
                          setType: setType,
                          guardianClass: guardianClass,
                          availableFamilies: const ['TechSec'],
                          onTypeChanged: (t) => setModal(() {
                            setType = t;
                            if (t != 'armor') guardianClass = null;
                          }),
                          onClassChanged: (c) =>
                              setModal(() => guardianClass = c),
                        ),
                      ),
                      SetsCreateWizardFooter(
                        step: step,
                        isFinalStep: isFinal,
                        canContinue: canContinue,
                        onBack: step == 0
                            ? null
                            : () => setModal(() => step -= 1),
                        onCancel: () => Navigator.of(ctx).pop(),
                        onContinue: isFinal
                            ? null
                            : () {
                                if (!canContinue) return;
                                setModal(() => step += 1);
                              },
                        onCreate: isFinal
                            ? () => Navigator.of(ctx).pop()
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openBoard(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          builder: (_, scroll) {
            return ListView(
              key: const Key('sets_mobile_board_sheet'),
              controller: scroll,
              padding: const EdgeInsets.all(kSpace16),
              children: [
                SetsArmorBoard(
                  slots: [
                    for (var i = 0; i < kArmorBoardSlotWires.length; i++)
                      SetsArmorSlotData(
                        slotWire: kArmorBoardSlotWires[i],
                        slotLabel: kArmorBoardSlotLabels[i],
                      ),
                  ],
                  onOptimize: () {},
                  onPickSlot: (_) {
                    // Structure-only: show owned-compare shell, not Catalog.
                    showModalBottomSheet<void>(
                      context: ctx,
                      builder: (c2) => const Padding(
                        padding: EdgeInsets.all(kSpace16),
                        child: SetsOwnedCompareTable(
                          rows: [],
                          emptyMessage: 'Owned compare (structure-only)',
                        ),
                      ),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
