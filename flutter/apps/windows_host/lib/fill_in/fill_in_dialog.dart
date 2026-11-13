import 'package:destiny2_domain/destiny2_domain.dart';
import 'package:destiny2_storage/destiny2_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../builds_mock/builds_mock_models.dart';
import 'fill_in_build_mapper.dart';
import 'fill_in_cache_loader.dart';
import 'fill_in_labels.dart';

/// Injectable clipboard writer (tests capture text without OS clipboard).
typedef FillInClipboardWriter = Future<void> Function(String text);

/// Injectable missing-list saver (tests avoid real StorageRoot IO).
typedef FillInMissingListSaver = Future<void> Function(FillInSavedBuildPlan plan);

Future<void> defaultFillInClipboardWriter(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

/// Opens the read-only Fill In pop-up for [build].
///
/// Loads DIM armor + weapons caches, runs [matchFillIn], shows held / missing /
/// over-cap chips and a Similar weapon suggestion. Persists the missing list
/// only when the user presses **Save missing list**.
Future<void> showFillInDialog({
  required BuildContext context,
  required MockBuild build,
  required FillInCacheLoader loadCaches,
  FillInClipboardWriter? clipboardWriter,
  FillInMissingListSaver? saveMissingList,
  VoidCallback? onMissingListSaved,
  GuardianClass guardianClass = GuardianClass.warlock,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return FillInDialog(
        build: build,
        loadCaches: loadCaches,
        clipboardWriter: clipboardWriter ?? defaultFillInClipboardWriter,
        saveMissingList: saveMissingList,
        onMissingListSaved: onMissingListSaved,
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
    this.saveMissingList,
    this.onMissingListSaved,
    this.guardianClass = GuardianClass.warlock,
  });

  final MockBuild build;
  final FillInCacheLoader loadCaches;
  final FillInClipboardWriter clipboardWriter;
  final FillInMissingListSaver? saveMissingList;
  final VoidCallback? onMissingListSaved;
  final GuardianClass guardianClass;

  @override
  State<FillInDialog> createState() => _FillInDialogState();
}

class _FillInDialogState extends State<FillInDialog> {
  var _loading = true;
  var _saving = false;
  String? _error;
  String? _saveMessage;
  FillInBuildResult? _result;
  List<FillInSlotMatch> _missing = const [];
  FillInSimilarWeapon? _similar;
  String? _missingWeaponName;

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
        _similar = null;
        _missingWeaponName = null;
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

    FillInSimilarWeapon? similar;
    String? missingWeaponName;
    final weaponMissing = missing.any(_isWeaponMatch);
    if (weaponMissing) {
      final need = fillInWeaponNeedForBuild(
        build: widget.build,
        inventory: loaded.items,
      );
      missingWeaponName = need?.name ?? widget.build.exoticWeapon.trim();
      if (need != null) {
        similar = suggestSimilarWeapon(
          need: need,
          heldWeapons: loaded.items,
        );
      }
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = null;
      _result = result;
      _missing = missing;
      _similar = similar;
      _missingWeaponName =
          missingWeaponName?.isEmpty ?? true ? null : missingWeaponName;
    });
  }

  Future<void> _copyMissing() async {
    if (_missing.isEmpty) return;
    final lines = <String>[
      for (final slot in _missing) fillInSlotLabel(slot.slot),
    ];
    await widget.clipboardWriter(lines.join('\n'));
  }

  Future<void> _saveMissing() async {
    final save = widget.saveMissingList;
    if (save == null || _saving) return;
    setState(() {
      _saving = true;
      _saveMessage = null;
    });
    try {
      final similar = _similar;
      await save(
        FillInSavedBuildPlan(
          buildId: widget.build.id,
          missing: [
            for (final slot in _missing) fillInSlotLabel(slot.slot),
          ],
          similarWeaponName: similar?.item.name,
          similarForName: _missingWeaponName,
        ),
      );
      widget.onMissingListSaved?.call();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveMessage = 'Missing list saved on this build.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveMessage = 'Could not save missing list: $e';
      });
    }
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
        if (_missing.isNotEmpty && widget.saveMissingList != null)
          TextButton(
            key: const Key('fill_in_save_missing'),
            onPressed: _saving ? null : _saveMissing,
            child: Text(_saving ? 'Saving…' : 'Save missing list'),
          ),
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
          if (_similar != null) ...[
            const SizedBox(height: 4),
            Text(
              'Similar: ${_similar!.item.name}'
              '${_missingWeaponName == null ? '' : ' (for $_missingWeaponName)'}',
              key: const Key('fill_in_similar_weapon'),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Plan only — never moves, equips, or transfers in-game items.',
              key: const Key('fill_in_similar_plan_note'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_saveMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _saveMessage!,
              key: const Key('fill_in_save_status'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
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
            fillInSlotLabel(match.slot),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        if (!_isWeaponMatch(match) && match.isHeld)
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

bool _isWeaponMatch(FillInSlotMatch match) {
  return EquipmentSlot.weaponSlots.contains(match.slot) ||
      match.slot == EquipmentSlot.exoticWeapon;
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
