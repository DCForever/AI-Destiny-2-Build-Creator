import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../builds_mock/builds_mock_models.dart';
import 'fill_in_build_mapper.dart';
import 'fill_in_cache_loader.dart';

/// Injectable clipboard writer (tests capture text without OS clipboard).
typedef FillInClipboardWriter = Future<void> Function(String text);

Future<void> defaultFillInClipboardWriter(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

/// Opens the read-only Fill In pop-up for [build].
///
/// Loads DIM armor + weapons caches, runs [matchFillIn], and shows held /
/// missing / over-cap chips. The only side effect is optional clipboard copy.
Future<void> showFillInDialog({
  required BuildContext context,
  required MockBuild build,
  required FillInCacheLoader loadCaches,
  FillInClipboardWriter? clipboardWriter,
  GuardianClass guardianClass = GuardianClass.warlock,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return FillInDialog(
        build: build,
        loadCaches: loadCaches,
        clipboardWriter: clipboardWriter ?? defaultFillInClipboardWriter,
        guardianClass: guardianClass,
      );
    },
  );
}

/// Read-only Fill In results dialog (armor + exotic weapons).
class FillInDialog extends StatefulWidget {
  const FillInDialog({
    super.key,
    required this.build,
    required this.loadCaches,
    this.clipboardWriter = defaultFillInClipboardWriter,
    this.guardianClass = GuardianClass.warlock,
  });

  final MockBuild build;
  final FillInCacheLoader loadCaches;
  final FillInClipboardWriter clipboardWriter;
  final GuardianClass guardianClass;

  @override
  State<FillInDialog> createState() => _FillInDialogState();
}

class _FillInDialogState extends State<FillInDialog> {
  var _loading = true;
  String? _error;
  FillInBuildResult? _result;
  List<FillInSlotMatch> _missing = const [];

  @override
  void initState() {
    super.initState();
    _runMatch();
  }

  Future<void> _runMatch() async {
    final loaded = await widget.loadCaches();
    if (!mounted) return;
    if (!loaded.isOk) {
      setState(() {
        _loading = false;
        _error = loaded.errorMessage;
        _result = null;
        _missing = const [];
      });
      return;
    }

    final mapped = mapMockBuildForFillIn(
      build: widget.build,
      inventory: loaded.items,
      guardianClass: widget.guardianClass,
    );
    final report = matchFillIn(
      inventory: mapped.inventory,
      builds: [mapped.requirement],
    );
    final result = report.builds.single;
    final missing = [
      for (final slot in result.slots)
        if (!slot.isHeld) slot,
    ];
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = null;
      _result = result;
      _missing = missing;
    });
  }

  Future<void> _copyMissing() async {
    if (_missing.isEmpty) return;
    final lines = <String>[
      for (final slot in _missing) _slotLabel(slot.slot),
    ];
    await widget.clipboardWriter(lines.join('\n'));
  }

  @override
  Widget build(BuildContext context) {
    final build = widget.build;
    return AlertDialog(
      key: Key('fill_in_dialog_${build.id}'),
      title: Text('Fill In — ${build.name}'),
      content: SizedBox(
        width: 420,
        child: _buildBody(context),
      ),
      actions: [
        if (_missing.isNotEmpty)
          TextButton(
            key: const Key('fill_in_copy_missing'),
            onPressed: _copyMissing,
            child: const Text('Copy missing list'),
          ),
        TextButton(
          key: const Key('fill_in_close'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_error != null) {
      return Text(
        _error!,
        key: const Key('fill_in_cache_error'),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }
    final result = _result;
    if (result == null) {
      return const Text('No Fill In result.', key: Key('fill_in_empty'));
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (result.solipsismNotPrismatic) ...[
            Text(
              'Solipsism is flagged: subclass is not Prismatic.',
              key: const Key('fill_in_solipsism_flag'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          for (final slot in result.slots) ...[
            _SlotRow(match: slot),
            const SizedBox(height: 8),
          ],
          if (result.slots.isEmpty)
            const Text(
              'This build has no armor or exotic weapon slots to check.',
              key: Key('fill_in_no_slots'),
            ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({required this.match});

  final FillInSlotMatch match;

  @override
  Widget build(BuildContext context) {
    final state = _stateLabel(match);
    final chipColor = _chipColor(context, match);
    return Row(
      key: Key('fill_in_slot_${match.slot.wireName}'),
      children: [
        Expanded(
          child: Text(
            _slotLabel(match.slot),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (!match.slotIsWeapon && match.isHeld)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '${match.poolHeldCount}/${match.cap}',
              key: Key('fill_in_held_count_${match.slot.wireName}'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (match.overCapLabel != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              match.overCapLabel!,
              key: Key('fill_in_over_cap_${match.slot.wireName}'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        Chip(
          key: Key('fill_in_chip_${match.slot.wireName}_$state'),
          label: Text(state),
          visualDensity: VisualDensity.compact,
          backgroundColor: chipColor,
        ),
      ],
    );
  }
}

extension on FillInSlotMatch {
  bool get slotIsWeapon =>
      EquipmentSlot.weaponSlots.contains(slot) ||
      slot == EquipmentSlot.exoticWeapon;
}

String _stateLabel(FillInSlotMatch match) {
  if (match.exceedsCap) return 'over cap';
  if (match.isHeld) return 'held';
  return 'missing';
}

Color? _chipColor(BuildContext context, FillInSlotMatch match) {
  final scheme = Theme.of(context).colorScheme;
  if (match.exceedsCap) return scheme.errorContainer;
  if (match.isHeld) return scheme.secondaryContainer;
  return scheme.surfaceContainerHighest;
}

String _slotLabel(EquipmentSlot slot) {
  switch (slot) {
    case EquipmentSlot.helmet:
      return 'Helmet';
    case EquipmentSlot.arms:
      return 'Gauntlets';
    case EquipmentSlot.chest:
      return 'Chest';
    case EquipmentSlot.legs:
      return 'Legs';
    case EquipmentSlot.classItem:
      return 'Class Item';
    case EquipmentSlot.primary:
      return 'Exotic weapon (kinetic)';
    case EquipmentSlot.special:
      return 'Exotic weapon (energy)';
    case EquipmentSlot.heavy:
      return 'Exotic weapon (power)';
    case EquipmentSlot.exoticWeapon:
      return 'Exotic weapon';
    case EquipmentSlot.exoticArmor:
      return 'Exotic armor';
  }
}
