import 'dart:math';

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

/// Called after Apply to build / Undo updates the app build copy.
typedef FillInBuildMutator = void Function(MockBuild updated);

Future<void> defaultFillInClipboardWriter(String text) async {
  await Clipboard.setData(ClipboardData(text: text));
}

/// Opens the Fill In pop-up for [build].
///
/// Loads DIM armor + weapons caches, runs [matchFillIn], shows held / missing /
/// substitute diffs. **Apply to build** writes all total-fill slots into the
/// app copy; missing list stays saved. Never writes Bungie inventory.
///
/// When [dimLoadout] is set (matched compiled DIM link), exotic armor + items
/// enrich the build the same way the details panel reads EXOTIC.
Future<void> showFillInDialog({
  required BuildContext context,
  required MockBuild build,
  required FillInCacheLoader loadCaches,
  FillInClipboardWriter? clipboardWriter,
  FillInMissingListSaver? saveMissingList,
  VoidCallback? onMissingListSaved,
  FillInBuildMutator? onBuildUpdated,
  FillInSavedBuildPlan? existingPlan,
  GuardianClass guardianClass = GuardianClass.warlock,
  CachedDimLoadout? dimLoadout,
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
        onBuildUpdated: onBuildUpdated,
        existingPlan: existingPlan,
        guardianClass: guardianClass,
        dimLoadout: dimLoadout,
      );
    },
  );
}

/// Fill In results dialog with Apply to build / Undo fill in.
class FillInDialog extends StatefulWidget {
  const FillInDialog({
    super.key,
    required this.build,
    required this.loadCaches,
    this.clipboardWriter = defaultFillInClipboardWriter,
    this.saveMissingList,
    this.onMissingListSaved,
    this.onBuildUpdated,
    this.existingPlan,
    this.guardianClass = GuardianClass.warlock,
    this.dimLoadout,
  });

  final MockBuild build;
  final FillInCacheLoader loadCaches;
  final FillInClipboardWriter clipboardWriter;
  final FillInMissingListSaver? saveMissingList;
  final VoidCallback? onMissingListSaved;
  final FillInBuildMutator? onBuildUpdated;
  final FillInSavedBuildPlan? existingPlan;
  final GuardianClass guardianClass;
  final CachedDimLoadout? dimLoadout;

  @override
  State<FillInDialog> createState() => _FillInDialogState();
}

class _FillInDialogState extends State<FillInDialog> {
  var _loading = true;
  var _saving = false;
  var _applying = false;
  String? _error;
  String? _saveMessage;
  FillInBuildResult? _result;
  List<FillInSlotMatch> _missing = const [];
  List<FillInSlotDiff> _diffs = const [];
  late MockBuild _build;
  FillInSavedBuildPlan? _plan;

  /// Exact pre-Apply build snapshot for Undo (exotic weapon + slot + rows).
  /// Never reconstruct Undo from per-slot [FillInAppliedSlot.originalLabel]s.
  MockBuild? _undoBaseline;

  @override
  void initState() {
    super.initState();
    _build = enrichMockBuildFromDimLoadout(
      widget.build,
      loadout: widget.dimLoadout,
    );
    _plan = widget.existingPlan;
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
        _diffs = const [];
      });
      return;
    }

    final mapped = mapMockBuildForFillIn(
      build: _build,
      inventory: loaded.items,
      guardianClass: widget.guardianClass,
      dimLoadout: widget.dimLoadout,
    );
    // Keep the dialog build in sync with DIM enrichment (exotic armor name).
    _build = enrichMockBuildFromDimLoadout(
      _build,
      loadout: widget.dimLoadout,
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

    // Exotic weapon need attrs (damage/type) for that slot's similar pick.
    FillInWeaponNeed? weaponNeed;
    final exoticWeaponNeed = fillInWeaponNeedForBuild(
      build: _build,
      inventory: loaded.items,
    );
    if (exoticWeaponNeed != null &&
        missing.any((m) => m.slot == exoticWeaponNeed.slot)) {
      weaponNeed = exoticWeaponNeed;
    }

    final currentLabels = _currentLabelsForBuild(
      build: _build,
      dimLoadout: widget.dimLoadout,
    );

    var diffs = planFillInSubstitutes(
      match: result,
      requirement: mapped.requirement,
      inventory: mapped.inventory,
      currentLabels: currentLabels,
      weaponNeed: weaponNeed,
      // Fresh RNG each open → re-roll when there is no saved/applied plan.
      random: Random(),
    );
    // Saved / applied picks stay stable until the user re-runs Fill In.
    diffs = _stabilizeDiffsFromPlan(
      diffs: diffs,
      plan: _plan,
      inventory: mapped.inventory,
    );

    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = null;
      _result = result;
      _missing = missing;
      _diffs = diffs;
    });
  }

  Future<void> _copyMissing() async {
    if (_missing.isEmpty) return;
    final exoticSlots = {
      for (final d in _diffs)
        if (d.isExotic) d.slot,
    };
    final exoticName = _build.exoticArmor.trim();
    final lines = <String>[
      for (final slot in _missing)
        fillInMissingSlotLabel(
          slot: slot.slot,
          isExotic: exoticSlots.contains(slot.slot),
          exoticArmorName: exoticName,
        ),
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
      final exoticSlots = {
        for (final d in _diffs)
          if (d.isExotic) d.slot,
      };
      final exoticName = _build.exoticArmor.trim();
      // Substitutes are filled picks — omit them from the flat missing list.
      final missingLabels = [
        for (final slot in _missing)
          if (!_diffs.any(
            (d) =>
                d.slot == slot.slot && (d.wouldSubstitute || d.isHeld),
          ))
            fillInMissingSlotLabel(
              slot: slot.slot,
              isExotic: exoticSlots.contains(slot.slot),
              exoticArmorName: exoticName,
            ),
      ].where((s) => s.trim().isNotEmpty).toList();
      // Only Apply pins count as filled; wouldSubstitute rows stay proposed.
      final filledWires = {
        for (final a in (_plan?.applied ?? const <FillInAppliedSlot>[]))
          if (a.label.trim().isNotEmpty) a.slotWire,
      };
      final plan = FillInSavedBuildPlan(
        buildId: _build.id,
        missing: missingLabels,
        applied: [
          for (final a in (_plan?.applied ?? const <FillInAppliedSlot>[]))
            if (a.label.trim().isNotEmpty ||
                (a.instanceId != null && a.instanceId!.trim().isNotEmpty))
              a,
        ],
        rows: buildFillInSavedSlotRows(
          diffs: _diffs,
          exoticArmorName: exoticName,
          filledSlotWires: filledWires,
        ),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      await save(plan);
      widget.onMissingListSaved?.call();
      if (!mounted) return;
      setState(() {
        _saving = false;
        _plan = plan;
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

  Future<void> _applyToBuild() async {
    if (_applying) return;
    if (_diffs.isEmpty) {
      setState(() => _saveMessage = 'Nothing to apply.');
      return;
    }
    setState(() {
      _applying = true;
      _saveMessage = null;
    });

    // Snapshot exact pre-Apply build for Undo (weapon + slot + full row list).
    final baseline = _snapshotBuild(_build);

    var next = _build;
    final applied = <FillInAppliedSlot>[];
    final slotByWire = <String, MockSlotAssignment>{
      for (final s in next.slots) s.slot: s,
    };

    for (final diff in _diffs) {
      final label = diff.applyLabel;
      final original = diff.currentLabel;
      final instanceId = diff.applyInstanceId;
      final itemHash = diff.applyItemHash;
      final filled = diff.isHeld || diff.wouldSubstitute;
      final realLabel = _isRealItemLabel(label);
      final realOriginal = _isRealItemLabel(original);

      // Never persist wire placeholders, "No weapon in DIM link", or blank
      // names in the store. Keep equip pins that still have an instance id.
      if (realLabel ||
          (instanceId != null && instanceId.trim().isNotEmpty)) {
        applied.add(
          FillInAppliedSlot(
            slotWire: diff.slot.wireName,
            label: realLabel ? label.trim() : '',
            originalLabel: realOriginal ? original.trim() : '',
            instanceId: instanceId,
            itemHash: itemHash,
          ),
        );
      }

      if (_isWeaponSlot(diff.slot)) {
        if (realLabel &&
            diff.isExotic &&
            (diff.wouldSubstitute || next.exoticWeapon.trim().isEmpty)) {
          next = next.copyWith(
            exoticWeapon: label,
            exoticWeaponSlot: diff.slot.wireName,
          );
        }
        final existingWeapon = slotByWire[diff.slot.wireName];
        final pieceName = realLabel
            ? label.trim()
            : (existingWeapon?.pieceName ?? '').trim();
        // Never mark filled-in with an empty/whitespace name.
        final markFilled = filled && pieceName.isNotEmpty;
        slotByWire[diff.slot.wireName] = MockSlotAssignment(
          slot: diff.slot.wireName,
          setId: existingWeapon?.setId ??
              (diff.isExotic ? 'exotic_weapon' : 'weapon'),
          pieceName: pieceName,
          isExoticSlot: diff.isExotic,
          filledIn: markFilled,
        );
        continue;
      }

      if (diff.slot == EquipmentSlot.exoticArmor) {
        // Slot-unknown exotic row is missing-list only — no combat pieceName.
        if (realLabel) {
          next = next.copyWith(exoticArmor: label);
        }
        continue;
      }

      final existing = slotByWire[diff.slot.wireName];
      final isExotic = diff.isExotic ||
          (existing?.isExoticSlot ?? false) ||
          (realLabel &&
              next.exoticArmor.trim().isNotEmpty &&
              label.trim().toLowerCase() ==
                  next.exoticArmor.trim().toLowerCase());
      final pieceName =
          realLabel ? label.trim() : (existing?.pieceName ?? '').trim();
      final markFilled = filled && pieceName.isNotEmpty;
      slotByWire[diff.slot.wireName] = MockSlotAssignment(
        slot: diff.slot.wireName,
        setId: existing?.setId ?? (isExotic ? 'exotic' : 'fill_in'),
        pieceName: pieceName,
        isExoticSlot: isExotic,
        filledIn: markFilled,
      );

      if (isExotic && realLabel) {
        next = next.copyWith(exoticArmor: label);
      }
    }

    next = next.copyWith(
      slots: List<MockSlotAssignment>.unmodifiable(slotByWire.values),
    );

    final exoticName = next.exoticArmor.trim();
    final missingLabels = [
      for (final slot in _missing)
        if (!_diffs.any(
          (d) => d.slot == slot.slot && (d.wouldSubstitute || d.isHeld),
        ))
          fillInMissingSlotLabel(
            slot: slot.slot,
            isExotic: _diffs.any((d) => d.slot == slot.slot && d.isExotic),
            exoticArmorName: exoticName,
          ),
    ].where((s) => s.trim().isNotEmpty).toList();

    final filledWires = {
      for (final a in applied)
        if (a.label.trim().isNotEmpty) a.slotWire,
    };
    final plan = FillInSavedBuildPlan(
      buildId: next.id,
      missing: missingLabels,
      applied: List<FillInAppliedSlot>.unmodifiable(applied),
      rows: buildFillInSavedSlotRows(
        diffs: _diffs,
        exoticArmorName: exoticName,
        filledSlotWires: filledWires,
      ),
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );

    final save = widget.saveMissingList;
    try {
      if (save != null) await save(plan);
      widget.onBuildUpdated?.call(next);
      widget.onMissingListSaved?.call();
      if (!mounted) return;
      setState(() {
        _applying = false;
        _build = next;
        _plan = plan;
        _undoBaseline = baseline;
        _saveMessage = 'Applied to build.';
      });
      await _runMatch();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _saveMessage = 'Could not apply to build: $e';
      });
    }
  }

  Future<void> _undoFillIn() async {
    final plan = _plan;
    final baseline = _undoBaseline;
    if (plan == null || !plan.hasAppliedSubstitutes || _applying) return;
    if (baseline == null) {
      setState(() => _saveMessage = 'Nothing to undo.');
      return;
    }
    setState(() {
      _applying = true;
      _saveMessage = null;
    });

    // Exact restore — do not reconstruct from per-slot originalLabel entries.
    final next = _snapshotBuild(baseline);

    // Clear applied pins; rows rebuilt after rematch without filled wires.
    var restored = plan.copyWith(
      clearApplied: true,
      rows: const [],
      updatedAt: DateTime.now().toUtc().toIso8601String(),
    );
    final save = widget.saveMissingList;
    try {
      if (save != null) await save(restored);
      widget.onBuildUpdated?.call(next);
      widget.onMissingListSaved?.call();
      if (!mounted) return;
      setState(() {
        _applying = false;
        _build = next;
        _plan = restored;
        _undoBaseline = null;
        _saveMessage = 'Fill in undone.';
      });
      await _runMatch();
      // Persist structured rows for the restored (pre-Apply) state.
      if (mounted && widget.saveMissingList != null) {
        restored = restored.copyWith(
          rows: buildFillInSavedSlotRows(
            diffs: _diffs,
            exoticArmorName: _build.exoticArmor,
          ),
          missing: [
            for (final slot in _missing)
              fillInMissingSlotLabel(
                slot: slot.slot,
                isExotic: _diffs.any((d) => d.slot == slot.slot && d.isExotic),
                exoticArmorName: _build.exoticArmor,
              ),
          ].where((s) => s.trim().isNotEmpty).toList(),
        );
        await widget.saveMissingList!(restored);
        widget.onMissingListSaved?.call();
        if (mounted) setState(() => _plan = restored);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _applying = false;
        _saveMessage = 'Could not undo: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final build = _build;
    final hasApplied =
        (_plan?.hasAppliedSubstitutes ?? false) && _undoBaseline != null;
    final canApply = _diffs.isNotEmpty;
    return AlertDialog(
      key: Key('fill_in_dialog_${build.id}'),
      title: Text('Fill In — ${build.name}'),
      content: SizedBox(
        width: 440,
        child: _buildBody(context),
      ),
      actions: [
        if (hasApplied)
          TextButton(
            key: const Key('fill_in_undo'),
            onPressed: _applying ? null : _undoFillIn,
            child: const Text('Undo fill in'),
          ),
        if (canApply && widget.onBuildUpdated != null)
          FilledButton(
            key: const Key('fill_in_apply_to_build'),
            onPressed: (_applying || _loading) ? null : _applyToBuild,
            child: Text(_applying ? 'Applying…' : 'Apply to build'),
          ),
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
    final armorDiffs = [
      for (final slot in kFillInArmorSectionOrder)
        ..._diffs.where((d) => d.slot == slot),
      ..._diffs.where((d) => d.slot == EquipmentSlot.exoticArmor),
    ];
    final weaponDiffs = [
      for (final slot in kFillInWeaponSectionOrder)
        ..._diffs.where((d) => d.slot == slot),
    ];

    Widget diffRows(List<FillInSlotDiff> diffs) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final diff in diffs) ...[
            _DiffRow(
              diff: diff,
              match: _matchForSlot(result.slots, diff.slot),
              exoticArmorName: _build.exoticArmor,
              filledIn: _build.slots.any(
                (s) =>
                    s.filledIn &&
                    (_slotFromMockWire(s.slot) == diff.slot ||
                        s.slot == diff.slot.wireName),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (result.hasSolipsismWarning) ...[
            Text(
              result.exoticArmorUnknown
                  ? "Exotic armor unknown: can't confirm Solipsism/Prismatic."
                  : 'Solipsism is flagged: subclass is not Prismatic.',
              key: const Key('fill_in_solipsism_flag'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            const SizedBox(height: 12),
          ],
          if (_diffs.isNotEmpty) ...[
            Text(
              'Armor',
              key: const Key('fill_in_section_armor'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            diffRows(armorDiffs),
            const SizedBox(height: 4),
            Text(
              'Weapons',
              key: const Key('fill_in_section_weapons'),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            diffRows(weaponDiffs),
          ],
          if (_diffs.isEmpty)
            for (final slot in result.slots) ...[
              _SlotRow(match: slot),
              const SizedBox(height: 8),
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

class _DiffRow extends StatelessWidget {
  const _DiffRow({
    required this.diff,
    required this.filledIn,
    this.match,
    this.exoticArmorName,
  });

  final FillInSlotDiff diff;
  final bool filledIn;
  final FillInSlotMatch? match;
  final String? exoticArmorName;

  @override
  Widget build(BuildContext context) {
    final slotLabel = fillInMissingSlotLabel(
      slot: diff.slot,
      isExotic: diff.isExotic,
      exoticArmorName: exoticArmorName,
    );
    final overCap = match?.exceedsCap ?? false;
    final right = diff.wouldSubstitute
        ? diff.substituteLabel!
        : (diff.isHeld ? 'held' : 'missing');
    final chipState = overCap
        ? 'over cap'
        : (diff.isHeld
            ? 'held'
            : (diff.wouldSubstitute ? 'substitute' : 'missing'));
    final showSimilarPick = _isWeaponSlot(diff.slot) &&
        diff.wouldSubstitute &&
        (diff.substituteLabel?.trim().isNotEmpty ?? false);
    return Row(
      key: Key('fill_in_diff_${diff.slot.wireName}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(slotLabel, style: Theme.of(context).textTheme.bodyMedium),
              Text(
                '${diff.currentLabel} → $right',
                key: Key('fill_in_diff_text_${diff.slot.wireName}'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (showSimilarPick)
                Text(
                  'Similar pick: ${diff.substituteLabel}',
                  key: Key('fill_in_similar_pick_${diff.slot.wireName}'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              if (diff.note != null && diff.note!.trim().isNotEmpty)
                Text(
                  diff.note!,
                  key: Key('fill_in_note_${diff.slot.wireName}'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        if (match != null && !_isWeaponSlot(diff.slot) && match!.isHeld)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              '${match!.poolHeldCount}/${match!.cap}',
              key: Key('fill_in_held_count_${diff.slot.wireName}'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (match?.overCapLabel != null)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              match!.overCapLabel!,
              key: Key('fill_in_over_cap_${diff.slot.wireName}'),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        if (filledIn)
          _FillInStatusChip(
            chipKey: Key('fill_in_filled_badge_${diff.slot.wireName}'),
            label: 'Filled in',
            emphasized: true,
          )
        else
          _FillInStatusChip(
            chipKey: Key('fill_in_chip_${diff.slot.wireName}_$chipState'),
            label: chipState,
            emphasized: false,
            error: overCap,
          ),
      ],
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
        if (!_isWeaponMatch(match) &&
            match.slot != EquipmentSlot.exoticArmor &&
            match.isHeld)
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
        _FillInStatusChip(
          chipKey: Key('fill_in_chip_${match.slot.wireName}_$state'),
          label: state,
          emphasized: match.isHeld && !match.exceedsCap,
          error: match.exceedsCap,
          backgroundColor: chipColor,
        ),
      ],
    );
  }
}

/// Per-row status chip with theme foreground that contrasts the fill.
///
/// Avoids undefined ColorScheme container roles (secondaryContainer /
/// errorContainer default to black on this host theme) which made "Filled in"
/// unreadable. Uses chipTheme / onSurface / error ink instead.
class _FillInStatusChip extends StatelessWidget {
  const _FillInStatusChip({
    required this.chipKey,
    required this.label,
    this.emphasized = false,
    this.error = false,
    this.backgroundColor,
  });

  final Key chipKey;
  final String label;
  final bool emphasized;
  final bool error;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final chipTheme = theme.chipTheme;
    final Color bg;
    final Color fg;
    if (error) {
      bg = backgroundColor ?? scheme.error.withValues(alpha: 0.14);
      fg = scheme.error;
    } else if (emphasized) {
      bg = backgroundColor ??
          chipTheme.selectedColor ??
          scheme.primary.withValues(alpha: 0.18);
      fg = chipTheme.labelStyle?.color ?? scheme.onSurface;
    } else {
      bg = backgroundColor ??
          chipTheme.backgroundColor ??
          scheme.surface;
      fg = chipTheme.labelStyle?.color ?? scheme.onSurface;
    }
    // Explicit fg/bg (not unset ColorScheme containers) so the label stays
    // readable for both the emphasized "Filled in" state and plain status chips.
    return Chip(
      key: chipKey,
      label: Text(
        label,
        style: TextStyle(color: fg),
      ),
      visualDensity: VisualDensity.compact,
      backgroundColor: bg,
      side: chipTheme.side,
      labelStyle: TextStyle(color: fg),
    );
  }
}

FillInSlotMatch? _matchForSlot(
  List<FillInSlotMatch> slots,
  EquipmentSlot slot,
) {
  for (final match in slots) {
    if (match.slot == slot) return match;
  }
  return null;
}

bool _isWeaponMatch(FillInSlotMatch match) {
  return _isWeaponSlot(match.slot);
}

bool _isWeaponSlot(EquipmentSlot slot) {
  return EquipmentSlot.weaponSlots.contains(slot) ||
      slot == EquipmentSlot.exoticWeapon;
}

/// Build per-slot current labels from DIM buckets + assignments.
///
/// Never invent Class Item = exotic armor, never park the exotic weapon on
/// Energy when its bucket is unknown, and never use wire placeholders as names.
Map<EquipmentSlot, String> _currentLabelsForBuild({
  required MockBuild build,
  CachedDimLoadout? dimLoadout,
}) {
  final labels = <EquipmentSlot, String>{};

  if (dimLoadout != null) {
    final pieces = extractFillInPiecesFromDimLoadout(dimLoadout);
    for (final entry in pieces.armorBySlot.entries) {
      labels[entry.key] = entry.value.name;
    }
    for (final entry in pieces.weaponsBySlot.entries) {
      labels[entry.key] = entry.value.name;
    }
  }

  for (final assignment in build.slots) {
    final slot = EquipmentSlot.tryParse(assignment.slot) ??
        _slotFromMockWire(assignment.slot);
    if (slot == null) continue;
    final name = assignment.pieceName.trim();
    if (name.isEmpty) continue;
    if (_isWeaponSlot(slot) && _isWirePlaceholderName(name)) continue;
    labels.putIfAbsent(slot, () => name);
  }

  // Exotic armor label only on its real assignment slot — never class_item.
  final exoticArmor = build.exoticArmor.trim();
  if (exoticArmor.isNotEmpty) {
    var placedOnCombatSlot = false;
    for (final assignment in build.slots) {
      if (!assignment.isExoticSlot) continue;
      final slot = _slotFromMockWire(assignment.slot);
      if (slot != null && EquipmentSlot.armorSlots.contains(slot)) {
        labels.putIfAbsent(slot, () => exoticArmor);
        placedOnCombatSlot = true;
      }
    }
    if (!placedOnCombatSlot && dimLoadout != null) {
      final pieces = extractFillInPiecesFromDimLoadout(dimLoadout);
      if (pieces.exoticArmorSlot != null) {
        labels.putIfAbsent(pieces.exoticArmorSlot!, () => exoticArmor);
        placedOnCombatSlot = true;
      }
    }
    if (!placedOnCombatSlot) {
      labels.putIfAbsent(EquipmentSlot.exoticArmor, () => exoticArmor);
    }
  }

  // Exotic weapon only when we know the combat bucket (DIM / inventory / meta).
  final exoticWeapon = build.exoticWeapon.trim();
  if (exoticWeapon.isNotEmpty && !_isWirePlaceholderName(exoticWeapon)) {
    final weaponSlot = build.exoticWeaponSlot == null
        ? null
        : EquipmentSlot.tryParse(build.exoticWeaponSlot!);
    if (weaponSlot != null && _isWeaponSlot(weaponSlot)) {
      labels.putIfAbsent(weaponSlot, () => exoticWeapon);
    }
  }

  return labels;
}

bool _isWirePlaceholderName(String name) {
  final lower = name.trim().toLowerCase();
  for (final slot in EquipmentSlot.values) {
    if (slot.wireName == lower) return true;
  }
  return false;
}

/// When a saved/applied plan already names substitutes, keep those picks
/// instead of the fresh random roll from [planFillInSubstitutes].
List<FillInSlotDiff> _stabilizeDiffsFromPlan({
  required List<FillInSlotDiff> diffs,
  required FillInSavedBuildPlan? plan,
  required List<FillInInventoryItem> inventory,
}) {
  if (plan == null) return diffs;
  final byWire = <String, ({String label, String? instanceId, int? itemHash})>{};
  for (final row in plan.rows) {
    if (row.state != 'proposed' && row.state != 'filled') continue;
    final name = row.itemName.trim();
    if (name.isEmpty) continue;
    byWire[row.slotWire] = (label: name, instanceId: null, itemHash: null);
  }
  for (final applied in plan.applied) {
    final name = applied.label.trim();
    if (name.isEmpty &&
        (applied.instanceId == null || applied.instanceId!.trim().isEmpty)) {
      continue;
    }
    byWire[applied.slotWire] = (
      label: name.isNotEmpty
          ? name
          : (byWire[applied.slotWire]?.label ?? ''),
      instanceId: applied.instanceId,
      itemHash: applied.itemHash,
    );
  }
  if (byWire.isEmpty) return diffs;

  final out = <FillInSlotDiff>[];
  for (final diff in diffs) {
    final saved = byWire[diff.slot.wireName];
    if (diff.isHeld || saved == null) {
      out.add(diff);
      continue;
    }
    final label = saved.label.trim().isNotEmpty
        ? saved.label.trim()
        : (diff.substituteLabel ?? '');
    if (label.isEmpty && saved.instanceId == null) {
      out.add(diff);
      continue;
    }
    FillInInventoryItem? invMatch;
    final savedId = saved.instanceId?.trim() ?? '';
    if (savedId.isNotEmpty) {
      for (final item in inventory) {
        if (item.instanceId == savedId) {
          invMatch = item;
          break;
        }
      }
    }
    if (invMatch == null && label.isNotEmpty) {
      final want = label.toLowerCase();
      for (final item in inventory) {
        if (item.slot != diff.slot) continue;
        if ((item.name ?? '').trim().toLowerCase() == want) {
          invMatch = item;
          break;
        }
      }
    }
    out.add(
      FillInSlotDiff(
        slot: diff.slot,
        currentLabel: diff.currentLabel,
        isHeld: false,
        isExotic: diff.isExotic,
        substituteLabel: label.isNotEmpty ? label : invMatch?.name,
        substituteInstanceId: saved.instanceId ?? invMatch?.instanceId,
        substituteItemHash: saved.itemHash ?? invMatch?.itemHash,
        note: diff.note,
      ),
    );
  }
  return List<FillInSlotDiff>.unmodifiable(out);
}

/// Deep-ish copy used for Apply/Undo baselines (exact row list restore).
MockBuild _snapshotBuild(MockBuild build) {
  return MockBuild(
    id: build.id,
    name: build.name,
    subclass: build.subclass,
    exoticArmor: build.exoticArmor,
    exoticWeapon: build.exoticWeapon,
    slots: List<MockSlotAssignment>.unmodifiable([
      for (final s in build.slots) s.copyWith(),
    ]),
    loop: build.loop,
    artifact: build.artifact,
    setBonuses: build.setBonuses,
    stats: build.stats,
    splitWhy: build.splitWhy,
    creator: build.creator,
    dimLink: build.dimLink,
    exoticWeaponType: build.exoticWeaponType,
    exoticWeaponDamageType: build.exoticWeaponDamageType,
    exoticWeaponSlot: build.exoticWeaponSlot,
  );
}

/// True when [label] is a real item name, not an equipment wire placeholder
/// such as `heavy` / `primary` / `helmet`, and not the empty-weapon display.
bool _isRealItemLabel(String label) {
  final trimmed = label.trim();
  if (trimmed.isEmpty) return false;
  if (trimmed == kFillInNoWeaponInDimLink) return false;
  final lower = trimmed.toLowerCase();
  for (final slot in EquipmentSlot.values) {
    if (slot.wireName == lower) return false;
  }
  return true;
}

EquipmentSlot? _slotFromMockWire(String wire) {
  switch (wire) {
    case 'helmet':
      return EquipmentSlot.helmet;
    case 'arms':
      return EquipmentSlot.arms;
    case 'chest':
      return EquipmentSlot.chest;
    case 'legs':
      return EquipmentSlot.legs;
    case 'class_item':
      return EquipmentSlot.classItem;
    default:
      return EquipmentSlot.tryParse(wire);
  }
}

String _stateLabel(FillInSlotMatch match) {
  if (match.exceedsCap) return 'over cap';
  if (match.isHeld) return 'held';
  return 'missing';
}

Color? _chipColor(BuildContext context, FillInSlotMatch match) {
  final scheme = Theme.of(context).colorScheme;
  final chipTheme = Theme.of(context).chipTheme;
  // Do not use secondaryContainer / errorContainer / surfaceContainerHighest —
  // this host ColorScheme leaves them unset (black), which hides label text.
  if (match.exceedsCap) return scheme.error.withValues(alpha: 0.14);
  if (match.isHeld) return chipTheme.selectedColor;
  return chipTheme.backgroundColor;
}
